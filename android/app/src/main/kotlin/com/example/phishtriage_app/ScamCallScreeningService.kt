package com.example.phishtriage_app

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.annotation.TargetApi

/**
 * Android calls this for incoming calls from numbers that are not in the
 * user's contacts, once PhishTriage holds the "call screening" role
 * (Android 10+). It checks the number against the offline list and must
 * answer within a few seconds, so it never uses the network.
 */
@TargetApi(Build.VERSION_CODES.Q)
class ScamCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val allow = CallResponse.Builder().build()
        if (callDetails.callDirection != Call.Details.DIRECTION_INCOMING) {
            respondToCall(callDetails, allow)
            return
        }
        val number = CallStore.normalize(callDetails.handle?.schemeSpecificPart)
        if (number == null) {
            respondToCall(callDetails, allow)
            return
        }

        val entry = CallStore.lookup(this, number)
        val org = CallStore.officialOrg(this, number)
        val block = entry != null && entry.risk == "High" && CallStore.blockHighRisk(this)

        if (block) {
            val reject = CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
            respondToCall(callDetails, reject)
        } else {
            respondToCall(callDetails, allow)
        }

        CallStore.addRecent(this, number, entry, org, block)

        when {
            block -> CallNotifier.show(
                this, number, "🛑 Blocked a likely scam call",
                "$number was reported ${entry!!.reports} time(s) for: ${entry.label}. Tap to see details."
            )
            entry != null -> CallNotifier.show(
                this, number, "⚠️ Possible scam call",
                "$number was reported ${entry.reports} time(s) for: ${entry.label}. " +
                    "Never share your OTP, PIN or BVN on this call."
            )
            org != null -> CallNotifier.show(
                this, number, "ℹ️ $org official number",
                "Caller ID can be faked. $org will never ask for your OTP, PIN or password."
            )
        }
    }
}
