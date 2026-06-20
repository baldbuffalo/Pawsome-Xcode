using Microsoft.UI.Xaml.Media.Imaging;
using Windows.Graphics.Imaging;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.Storage.Streams;

namespace Pawsome.App.Services;

/// <summary>
/// Native image handling: pick a file, build a preview, and resize/encode to
/// JPEG bytes for upload (the WinUI equivalent of the Swift PlatformImage
/// helpers).
/// </summary>
public sealed class ImageService
{
    /// <summary>Shows the native file picker for images.</summary>
    public async Task<StorageFile?> PickImageAsync(IntPtr windowHandle)
    {
        var picker = new FileOpenPicker
        {
            ViewMode = PickerViewMode.Thumbnail,
            SuggestedStartLocation = PickerLocationId.PicturesLibrary,
        };
        picker.FileTypeFilter.Add(".jpg");
        picker.FileTypeFilter.Add(".jpeg");
        picker.FileTypeFilter.Add(".png");
        picker.FileTypeFilter.Add(".heic");
        picker.FileTypeFilter.Add(".webp");

        // WinUI 3 desktop requires associating the picker with the window.
        WinRT.Interop.InitializeWithWindow.Initialize(picker, windowHandle);

        return await picker.PickSingleFileAsync();
    }

    /// <summary>Loads a file as a BitmapImage for on-screen preview.</summary>
    public static async Task<BitmapImage> LoadPreviewAsync(StorageFile file)
    {
        var bitmap = new BitmapImage();
        using var stream = await file.OpenAsync(FileAccessMode.Read);
        await bitmap.SetSourceAsync(stream);
        return bitmap;
    }

    /// <summary>Resizes to <paramref name="maxDimension"/> and encodes JPEG bytes for upload.</summary>
    public async Task<byte[]> EncodeJpegAsync(StorageFile file, uint maxDimension = 1200, float quality = 0.8f)
    {
        using var inputStream = await file.OpenAsync(FileAccessMode.Read);
        var decoder = await BitmapDecoder.CreateAsync(inputStream);

        var (width, height) = (decoder.PixelWidth, decoder.PixelHeight);
        var scale = Math.Min(1.0, maxDimension / (double)Math.Max(width, height));
        var scaledWidth = (uint)Math.Max(1, Math.Round(width * scale));
        var scaledHeight = (uint)Math.Max(1, Math.Round(height * scale));

        var transform = new BitmapTransform
        {
            ScaledWidth = scaledWidth,
            ScaledHeight = scaledHeight,
            InterpolationMode = BitmapInterpolationMode.Fant,
        };

        var pixelData = await decoder.GetPixelDataAsync(
            BitmapPixelFormat.Bgra8,
            BitmapAlphaMode.Premultiplied,
            transform,
            ExifOrientationMode.RespectExifOrientation,
            ColorManagementMode.DoNotColorManage);

        using var outputStream = new InMemoryRandomAccessStream();
        var options = new BitmapPropertySet
        {
            { "ImageQuality", new BitmapTypedValue(quality, Windows.Foundation.PropertyType.Single) },
        };

        var encoder = await BitmapEncoder.CreateAsync(BitmapEncoder.JpegEncoderId, outputStream, options);
        encoder.SetPixelData(
            BitmapPixelFormat.Bgra8,
            BitmapAlphaMode.Premultiplied,
            scaledWidth, scaledHeight,
            96, 96,
            pixelData.DetachPixelData());
        await encoder.FlushAsync();

        var bytes = new byte[outputStream.Size];
        using var reader = new DataReader(outputStream.GetInputStreamAt(0));
        await reader.LoadAsync((uint)outputStream.Size);
        reader.ReadBytes(bytes);
        return bytes;
    }
}
