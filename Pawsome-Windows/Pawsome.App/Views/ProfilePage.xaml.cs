using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Pawsome.App.Services;
using Pawsome.App.ViewModels;

namespace Pawsome.App.Views;

public sealed partial class ProfilePage : Page
{
    private static readonly Uri FunctionsBase = new("https://europe-west1-pawsome-90cb3.cloudfunctions.net/");
    public ProfileViewModel ViewModel { get; }

    public ProfilePage()
    {
        ViewModel = new ProfileViewModel(App.Instance.Services);
        InitializeComponent();
        Loaded += async (_, _) => await CheckAdminAccessAsync();
    }

    private async Task CheckAdminAccessAsync()
    {
        try
        {
            var token = await App.Instance.Services.Auth.GetValidIdTokenAsync();
            using var request = new HttpRequestMessage(HttpMethod.Post, new Uri(FunctionsBase, "adminGetStats"));
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Content = JsonContent.Create(new { data = new { } });
            using var response = await App.Instance.Services.Http.SendAsync(request);
            AdminButton.Visibility = response.IsSuccessStatusCode ? Visibility.Visible : Visibility.Collapsed;
        }
        catch
        {
            AdminButton.Visibility = Visibility.Collapsed;
        }
    }

    private void OpenAdmin_Click(object sender, RoutedEventArgs e)
    {
        if (App.Instance.MainWindow is not null)
            App.Instance.MainWindow.RootFrame.Navigate(typeof(AdminPage));
    }

    private async void ChangePhoto_Click(object sender, RoutedEventArgs e)
    {
        var services = App.Instance.Services;
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(App.Instance.MainWindow);

        var file = await services.Images.PickImageAsync(hwnd);
        if (file is null) return;

        await ViewModel.UploadProfilePictureAsync(file);
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
