using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Pawsome.App.Services;
using Pawsome.App.ViewModels;

namespace Pawsome.App.Views;

public sealed partial class ProfilePage : Page
{
    private const string AdminUrl = "https://baldbuffalo.github.io/Pawsome-Xcode/admin/";

    public ProfileViewModel ViewModel { get; }

    public ProfilePage()
    {
        ViewModel = new ProfileViewModel(App.Instance.Services);
        InitializeComponent();
    }

    private async void ChangePhoto_Click(object sender, RoutedEventArgs e)
    {
        var services = App.Instance.Services;
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(App.Instance.MainWindow);

        var file = await services.Images.PickImageAsync(hwnd);
        if (file is null) return;

        await ViewModel.UploadProfilePictureAsync(file);
    }

    private async void OpenAdmin_Click(object sender, RoutedEventArgs e)
    {
        await Windows.System.Launcher.LaunchUriAsync(new Uri(AdminUrl));
    }

    private void SaveToken_Click(object sender, RoutedEventArgs e)
    {
        var token = TokenBox.Password?.Trim();
        if (string.IsNullOrEmpty(token))
        {
            App.Instance.Services.Secrets.Remove(SecureStore.GitHubTokenKey);
            TokenStatus.Text = "Cleared";
        }
        else
        {
            App.Instance.Services.Secrets.Set(SecureStore.GitHubTokenKey, token);
            TokenStatus.Text = "✓ Saved";
        }
        TokenBox.Password = "";
    }
}
