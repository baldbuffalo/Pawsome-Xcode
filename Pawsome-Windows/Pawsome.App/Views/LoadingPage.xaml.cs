using System.Threading.Tasks;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Pawsome.App.Views;

public sealed partial class LoadingPage : Page
{
    public LoadingPage() => InitializeComponent();

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        _ = InitializeAsync();
    }

    private async Task InitializeAsync()
    {
        bool restored = false;
        try
        {
            restored = await App.Instance.Services.Session.TryRestoreAsync();
        }
        catch
        {
            restored = false;
        }

        // Defer the root navigation onto the dispatcher so it never runs
        // re-entrantly inside OnNavigatedTo — doing it inline silently fails
        // on first launch and leaves the app stuck on the loading spinner.
        var target = restored ? typeof(ShellPage) : typeof(LoginPage);
        DispatcherQueue.TryEnqueue(() => App.NavigateRoot(target));
    }
}
