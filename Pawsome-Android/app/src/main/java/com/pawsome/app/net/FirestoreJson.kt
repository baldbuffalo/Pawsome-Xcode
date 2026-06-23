package com.pawsome.app.net

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

/** Converts between plain values and Firestore's REST typed-JSON, mirroring the Windows engine. */
object FirestoreValue {

    fun toValue(v: Any?): JSONObject = when (v) {
        null -> JSONObject().put("nullValue", JSONObject.NULL)
        is Boolean -> JSONObject().put("booleanValue", v)
        is Int -> JSONObject().put("integerValue", v.toString())
        is Long -> JSONObject().put("integerValue", v.toString())
        is Double -> JSONObject().put("doubleValue", v)
        is Float -> JSONObject().put("doubleValue", v.toDouble())
        is Instant -> JSONObject().put("timestampValue", v.toString())
        is String -> JSONObject().put("stringValue", v)
        is List<*> -> JSONObject().put(
            "arrayValue",
            JSONObject().put("values", JSONArray(v.map { toValue(it) }))
        )
        is Map<*, *> -> {
            val fields = JSONObject()
            v.forEach { (k, value) -> fields.put(k.toString(), toValue(value)) }
            JSONObject().put("mapValue", JSONObject().put("fields", fields))
        }
        else -> JSONObject().put("stringValue", v.toString())
    }

    fun fromValue(o: JSONObject): Any? = when {
        o.has("nullValue") -> null
        o.has("stringValue") -> o.getString("stringValue")
        o.has("booleanValue") -> o.getBoolean("booleanValue")
        o.has("integerValue") -> o.getString("integerValue").toLong()
        o.has("doubleValue") -> o.getDouble("doubleValue")
        o.has("timestampValue") -> runCatching { Instant.parse(o.getString("timestampValue")) }.getOrNull()
        o.has("referenceValue") -> o.getString("referenceValue")
        o.has("arrayValue") -> {
            val arr = o.getJSONObject("arrayValue").optJSONArray("values") ?: JSONArray()
            (0 until arr.length()).map { fromValue(arr.getJSONObject(it)) }
        }
        o.has("mapValue") -> parseFields(o.getJSONObject("mapValue"))
        else -> null
    }

    /** Accepts a document or mapValue wrapper or a raw fields object. */
    fun parseFields(docOrMap: JSONObject?): Map<String, Any?> {
        if (docOrMap == null) return emptyMap()
        val fields = docOrMap.optJSONObject("fields") ?: docOrMap
        val out = HashMap<String, Any?>()
        fields.keys().forEach { k -> out[k] = fromValue(fields.getJSONObject(k)) }
        return out
    }

    fun toFields(map: Map<String, Any?>): JSONObject {
        val fields = JSONObject()
        map.forEach { (k, v) -> fields.put(k, toValue(v)) }
        return fields
    }
}

// Typed accessors over a parsed document map.
fun Map<String, Any?>.str(key: String): String? = this[key] as? String
fun Map<String, Any?>.long(key: String): Long = (this[key] as? Long) ?: 0L
fun Map<String, Any?>.millis(key: String): Long =
    (this[key] as? Instant)?.toEpochMilli() ?: System.currentTimeMillis()
fun Map<String, Any?>.strList(key: String): List<String> =
    (this[key] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
