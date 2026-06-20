using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Pawsome.App.Views;

public sealed partial class ImageViewerWindow : Window
{
    public ImageViewerWindow(string imageUrl)
    {
        InitializeComponent();
        Title = "Pawsome — Photo";

        if (Uri.TryCreate(imageUrl, UriKind.Absolute, out var uri))
            FullImage.Source = new BitmapImage(uri);
    }

    private void Close_Click(object sender, RoutedEventArgs e) => Close();
}
