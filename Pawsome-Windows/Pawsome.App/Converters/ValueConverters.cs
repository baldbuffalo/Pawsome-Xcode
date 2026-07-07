using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Data;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Pawsome.App.Converters;

/// <summary>true → Visible, false → Collapsed.</summary>
public sealed class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is true ? Visibility.Visible : Visibility.Collapsed;

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => value is Visibility.Visible;
}

/// <summary>true → Collapsed, false → Visible.</summary>
public sealed class InverseBoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is true ? Visibility.Collapsed : Visibility.Visible;

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => value is not Visibility.Visible;
}

/// <summary>Logical NOT for booleans.</summary>
public sealed class InverseBoolConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is not true;

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => value is not true;
}

/// <summary>Non-empty string → Visible.</summary>
public sealed class StringToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => string.IsNullOrWhiteSpace(value as string) ? Visibility.Collapsed : Visibility.Visible;

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => throw new NotSupportedException();
}

/// <summary>Positive count → Visible.</summary>
public sealed class CountToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is int n && n > 0 ? Visibility.Visible : Visibility.Collapsed;

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => throw new NotSupportedException();
}

/// <summary>A remote image URL → BitmapImage (null/empty → no image, so the fallback shows).</summary>
public sealed class UrlToImageSourceConverter : IValueConverter
{
    public object? Convert(object value, Type targetType, object parameter, string language)
    {
        if (value is string url && Uri.TryCreate(url, UriKind.Absolute, out var uri))
            return new BitmapImage(uri);
        return null;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => throw new NotSupportedException();
}

/// <summary>true → liked (red) heart brush, false → neutral.</summary>
public sealed class LikedToBrushConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is true
            ? new SolidColorBrush(Microsoft.UI.Colors.Crimson)
            : (Application.Current.Resources["TextFillColorSecondaryBrush"] as Brush
               ?? new SolidColorBrush(Microsoft.UI.Colors.Gray));

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => throw new NotSupportedException();
}

/// <summary>bool → Google sign-in text (Loading... or Sign in with Google).</summary>
public sealed class BoolToSignInTextGoogleConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is true ? "Loading..." : "Sign in with Google";

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => throw new NotSupportedException();
}

/// <summary>bool → Twitter/X sign-in text (Loading... or Sign in with X).</summary>
public sealed class BoolToSignInTextTwitterConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is true ? "Loading..." : "Sign in with X";

    public object ConvertBack(object value, Type targetType, object parameter, string language)
        => throw new NotSupportedException();
}
