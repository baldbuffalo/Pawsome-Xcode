using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Pawsome.App.Views;

public sealed partial class LoadingPage : Page
{
    public LoadingPage() => InitializeComponent();

    protected override async void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);

        bool restored = false;
        try
        {
            restored = await App.Instance.Services.Session.TryRestoreAsync();
        }
        catch
        {
            restored = false;
        }

        App.NavigateRoot(restored ? typeof(ShellPage) : typeof(LoginPage));
    }
}
