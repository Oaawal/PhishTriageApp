package com.example.phishtriage_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * On-device data for call protection:
 *  - the offline list of reported and official numbers (downloaded by the Flutter app)
 *  - the "block high-risk callers" setting
 *  - recent unknown callers, so the user can report them in one tap
 *
 * Nothing here leaves the phone. Contacts and the call log are never read.
 */
object CallStore {
    private const val LIST_FILE = "phishtriage_blocklist.json"
    private const val PREFS = "phishtriage_calls"
    private const val KEY_BLOCK = "block_high_risk"
    private const val KEY_RECENT = "recent_calls"
    private const val MAX_RECENT = 30

    data class Entry(val risk: String, val label: String, val reports: Int)

    @Volatile private var loadedAt = 0L
    @Volatile private var reported: Map<String, Entry> = emptyMap()
    @Volatile private var official: Map<String, String> = emptyMap()
    @Volatile private var updatedAt: String? = null

    fun normalize(raw: String?): String? {
        if (raw.isNullOrBlank()) return null
        val digits = raw.filter { it.isDigit() }
        return when {
            digits.startsWith("234") && digits.length == 13 -> "+$digits"
            digits.startsWith("0") && digits.length == 11 -> "+234" + digits.substring(1)
            digits.length == 10 && digits[0] in "789" -> "+234$digits"
            raw.trim().startsWith("+") && digits.length >= 8 -> "+$digits"
            digits.isNotEmpty() -> digits
            else -> null
        }
    }

    /** Called from Flutter with the JSON from GET /numbers/blocklist. */
    fun saveList(context: Context, json: String) {
        JSONObject(json) // validate before replacing the old list
        File(context.filesDir, LIST_FILE).writeText(json)
        loadedAt = 0L
        ensureLoaded(context)
    }

    @Synchronized
    private fun ensureLoaded(context: Context) {
        val file = File(context.filesDir, LIST_FILE)
        if (!file.exists()) return
        if (loadedAt == file.lastModified()) return
        try {
            val obj = JSONObject(file.readText())
            val nums = obj.optJSONArray("numbers") ?: JSONArray()
            val rep = HashMap<String, Entry>(nums.length() * 2)
            for (i in 0 until nums.length()) {
                val o = nums.getJSONObject(i)
                rep[o.getString("n")] = Entry(o.optString("r", "Medium"), o.optString("l", "Reported"), o.optInt("c", 1))
            }
            val offs = obj.optJSONArray("official") ?: JSONArray()
            val off = HashMap<String, String>()
            for (i in 0 until offs.length()) {
                val o = offs.getJSONObject(i)
                off[o.getString("n")] = o.optString("o", "Official")
            }
            reported = rep
            official = off
            updatedAt = obj.optString("generated_at", null)
            loadedAt = file.lastModified()
        } catch (e: Exception) {
            // A broken file must never break incoming calls; keep the previous list.
        }
    }

    fun lookup(context: Context, number: String?): Entry? {
        if (number == null) return null
        ensureLoaded(context)
        return reported[number]
    }

    fun officialOrg(context: Context, number: String?): String? {
        if (number == null) return null
        ensureLoaded(context)
        return official[number]
    }

    fun listCount(context: Context): Int {
        ensureLoaded(context)
        return reported.size
    }

    fun listUpdatedAt(context: Context): String? {
        ensureLoaded(context)
        return updatedAt
    }

    fun blockHighRisk(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_BLOCK, false)

    fun setBlockHighRisk(context: Context, value: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(KEY_BLOCK, value).apply()
    }

    @Synchronized
    fun addRecent(context: Context, number: String, entry: Entry?, org: String?, blocked: Boolean) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val old = JSONArray(prefs.getString(KEY_RECENT, "[]"))
        val item = JSONObject()
            .put("number", number)
            .put("time", System.currentTimeMillis())
            .put("risk", entry?.risk ?: JSONObject.NULL)
            .put("label", entry?.label ?: JSONObject.NULL)
            .put("reports", entry?.reports ?: 0)
            .put("official", org ?: JSONObject.NULL)
            .put("blocked", blocked)
        val out = JSONArray().put(item)
        for (i in 0 until minOf(old.length(), MAX_RECENT - 1)) out.put(old.getJSONObject(i))
        prefs.edit().putString(KEY_RECENT, out.toString()).apply()
    }

    fun recent(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_RECENT, "[]") ?: "[]"

    fun clearRecent(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(KEY_RECENT).apply()
    }
}
