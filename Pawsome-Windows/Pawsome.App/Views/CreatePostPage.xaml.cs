using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Pawsome.App.Services;
using Pawsome.App.ViewModels;

namespace Pawsome.App.Views;

public sealed partial class CreatePostPage : Page
{
    public CreatePostViewModel ViewModel { get; }

    public CreatePostPage()
    {
        ViewModel = new CreatePostViewModel(App.Instance.Services);
        ViewModel.PostCreated += OnPostCreated;
        InitializeComponent();
    }

    private void OnPostCreated()
    {
        if (Frame.CanGoBack) Frame.GoBack();
    }

    private void Back_Click(object sender, RoutedEventArgs e)
    {
        if (Frame.CanGoBack) Frame.GoBack();
    }

    private async void ChooseImage_Click(object sender, RoutedEventArgs e)
    {
        var services = App.Instance.Services;
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(App.Instance.MainWindow);

        var file = await services.Images.PickImageAsync(hwnd);
        if (file is null) return;

        try
        {
            var jpeg = await services.Images.EncodeJpegAsync(file, maxDimension: 1200);
            var preview = await ImageService.LoadPreviewAsync(file);
            ViewModel.SetImage(jpeg, preview);
        }
        catch (Exception ex)
        {
            var dialog = new ContentDialog
            {
                Title = "Couldn't load image",
                Content = ex.Message,
                CloseButtonText = "OK",
                XamlRoot = XamlRoot,
            };
            await dialog.ShowAsync();
        }
    }
}
