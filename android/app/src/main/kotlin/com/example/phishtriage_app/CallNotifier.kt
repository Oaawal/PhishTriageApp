package com.example.phishtriage_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/** Heads-up notifications shown while a flagged number is calling. */
object CallNotifier {
    private const val CHANNEL_ID = "call_warnings"

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val ch = NotificationChannel(CHANNEL_ID, "Scam call warnings", NotificationManager.IMPORTANCE_HIGH)
                ch.description = "Warns you while a reported number is calling"
                nm.createNotificationChannel(ch)
            }
        }
    }

    private fun openApp(context: Context, number: String, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_OPEN, action)
            putExtra(MainActivity.EXTRA_NUMBER, number)
        }
        return PendingIntent.getActivity(
            context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun show(context: Context, number: String, title: String, text: String) {
        try {
            ensureChannel(context)
            val id = number.hashCode()
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
            }
            val notification = builder
                .setSmallIcon(android.R.drawable.stat_sys_warning)
                .setContentTitle(title)
                .setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setCategory(Notification.CATEGORY_CALL)
                .setAutoCancel(true)
                .setContentIntent(openApp(context, number, "lookup", id))
                .addAction(
                    Notification.Action.Builder(null, "Report", openApp(context, number, "report", id + 1)).build()
                )
                .build()
            context.getSystemService(NotificationManager::class.java).notify(id, notification)
        } catch (e: SecurityException) {
            // Notification permission not granted; the call itself is unaffected.
        }
    }
}
