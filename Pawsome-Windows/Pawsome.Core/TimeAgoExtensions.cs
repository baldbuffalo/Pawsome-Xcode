namespace Pawsome.Core;

/// <summary>Human-readable "X ago" strings — mirrors the Swift Timestamp extension.</summary>
public static class TimeAgoExtensions
{
    public static string TimeAgoDisplay(this DateTimeOffset time)
    {
        var diff = DateTimeOffset.UtcNow - time.ToUniversalTime();
        if (diff < TimeSpan.Zero) diff = TimeSpan.Zero;

        if (diff.TotalDays >= 365) return $"{(int)(diff.TotalDays / 365)}y ago";
        if (diff.TotalDays >= 30)  return $"{(int)(diff.TotalDays / 30)}mo ago";
        if (diff.TotalDays >= 7)   return $"{(int)(diff.TotalDays / 7)}w ago";
        if (diff.TotalDays >= 1)   return $"{(int)diff.TotalDays}d ago";
        if (diff.TotalHours >= 1)  return $"{(int)diff.TotalHours}h ago";
        if (diff.TotalMinutes >= 1) return $"{(int)diff.TotalMinutes}m ago";
        if (diff.TotalSeconds >= 1) return $"{(int)diff.TotalSeconds}s ago";
        return "just now";
    }
}
