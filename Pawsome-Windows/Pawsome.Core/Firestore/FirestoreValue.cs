using System.Globalization;
using System.Text.Json.Nodes;

namespace Pawsome.Core.Firestore;

/// <summary>
/// Converts between plain .NET values and Firestore's verbose REST "Value"
/// representation, e.g. <c>{"stringValue":"Mittens"}</c> or
/// <c>{"arrayValue":{"values":[{"stringValue":"uid1"}]}}</c>.
///
/// Supported .NET types: <see cref="string"/>, <see cref="bool"/>,
/// <see cref="int"/>/<see cref="long"/>, <see cref="double"/>,
/// <see cref="DateTimeOffset"/>, <c>IEnumerable&lt;object?&gt;</c> and
/// <c>IReadOnlyDictionary&lt;string, object?&gt;</c> (nested maps). <c>null</c>
/// round-trips as a Firestore nullValue.
/// </summary>
public static class FirestoreValue
{
    // ── .NET object  →  Firestore Value node ────────────────────────────────
    public static JsonNode FromObject(object? value)
    {
        switch (value)
        {
            case null:
                return new JsonObject { ["nullValue"] = null };

            case bool b:
                return new JsonObject { ["booleanValue"] = b };

            case int or long or short or byte:
                return new JsonObject
                {
                    ["integerValue"] = Convert.ToInt64(value, CultureInfo.InvariantCulture)
                        .ToString(CultureInfo.InvariantCulture)
                };

            case float or double or decimal:
                return new JsonObject
                {
                    ["doubleValue"] = Convert.ToDouble(value, CultureInfo.InvariantCulture)
                };

            case DateTimeOffset dto:
                return new JsonObject
                {
                    ["timestampValue"] = dto.ToUniversalTime()
                        .ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ", CultureInfo.InvariantCulture)
                };

            case DateTime dt:
                return FromObject(new DateTimeOffset(dt.ToUniversalTime(), TimeSpan.Zero));

            case string s:
                return new JsonObject { ["stringValue"] = s };

            case IReadOnlyDictionary<string, object?> map:
            {
                var fields = new JsonObject();
                foreach (var (k, v) in map) fields[k] = FromObject(v);
                return new JsonObject { ["mapValue"] = new JsonObject { ["fields"] = fields } };
            }

            case System.Collections.IEnumerable seq:
            {
                var values = new JsonArray();
                foreach (var item in seq) values.Add(FromObject(item));
                return new JsonObject { ["arrayValue"] = new JsonObject { ["values"] = values } };
            }

            default:
                return new JsonObject { ["stringValue"] = value.ToString() ?? "" };
        }
    }

    // ── Firestore Value node  →  .NET object ────────────────────────────────
    public static object? ToObject(JsonNode? node)
    {
        if (node is not JsonObject obj) return null;

        if (obj.ContainsKey("nullValue")) return null;
        if (obj.TryGetPropertyValue("stringValue", out var sv)) return sv?.GetValue<string>();
        if (obj.TryGetPropertyValue("booleanValue", out var bv)) return bv?.GetValue<bool>();
        if (obj.TryGetPropertyValue("referenceValue", out var rv)) return rv?.GetValue<string>();

        if (obj.TryGetPropertyValue("integerValue", out var iv) && iv is not null)
            return long.Parse(iv.GetValue<string>(), CultureInfo.InvariantCulture);

        if (obj.TryGetPropertyValue("doubleValue", out var dv) && dv is not null)
            return dv.GetValue<double>();

        if (obj.TryGetPropertyValue("timestampValue", out var tv) && tv is not null)
            return DateTimeOffset.Parse(tv.GetValue<string>(), CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal);

        if (obj.TryGetPropertyValue("arrayValue", out var av))
        {
            var list = new List<object?>();
            if (av is JsonObject ao && ao.TryGetPropertyValue("values", out var vals) && vals is JsonArray arr)
                foreach (var item in arr) list.Add(ToObject(item));
            return list;
        }

        if (obj.TryGetPropertyValue("mapValue", out var mv))
            return ParseFields(mv as JsonObject);

        return null;
    }

    /// <summary>Parses a Firestore document's <c>fields</c> object into a dictionary.</summary>
    public static Dictionary<string, object?> ParseFields(JsonObject? mapValueOrDoc)
    {
        var result = new Dictionary<string, object?>();
        if (mapValueOrDoc is null) return result;

        // Accept either a document/mapValue wrapper ({ "fields": {...} }) or the fields object itself.
        var fields = mapValueOrDoc.TryGetPropertyValue("fields", out var f) && f is JsonObject fo
            ? fo
            : mapValueOrDoc;

        foreach (var (key, node) in fields)
            result[key] = ToObject(node);

        return result;
    }

    /// <summary>Serializes a dictionary into a Firestore <c>fields</c> object.</summary>
    public static JsonObject ToFields(IReadOnlyDictionary<string, object?> data)
    {
        var fields = new JsonObject();
        foreach (var (key, value) in data) fields[key] = FromObject(value);
        return fields;
    }
}

/// <summary>Typed accessors over a parsed Firestore document dictionary.</summary>
public static class FirestoreDataExtensions
{
    public static string? GetString(this IReadOnlyDictionary<string, object?> data, string key)
        => data.TryGetValue(key, out var v) && v is string s ? s : null;

    public static long GetLong(this IReadOnlyDictionary<string, object?> data, string key)
        => data.TryGetValue(key, out var v) && v is long l ? l : 0;

    public static DateTimeOffset? GetTimestamp(this IReadOnlyDictionary<string, object?> data, string key)
        => data.TryGetValue(key, out var v) && v is DateTimeOffset dto ? dto : null;

    public static IReadOnlyList<string> GetStringList(this IReadOnlyDictionary<string, object?> data, string key)
    {
        if (data.TryGetValue(key, out var v) && v is List<object?> list)
            return list.OfType<string>().ToList();
        return Array.Empty<string>();
    }
}
