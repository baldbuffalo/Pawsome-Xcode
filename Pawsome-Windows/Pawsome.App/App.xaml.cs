using Microsoft.UI.Xaml;
using Pawsome.App.Services;
using Pawsome.App.Views;

namespace Pawsome.App;

public partial class App : Application
{
    public static App Instance { get; private set; } = null!;

    /// <summary>The app's shared services (auth, Firestore, images, session).</summary>
    public AppServices Services { get; } = new();

    public MainWindow? MainWindow { get; private set; }

    public App()
    {
        Instance = this;
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        MainWindow = new MainWindow();
        MainWindow.RootFrame.Navigate(typeof(LoadingPage));
        MainWindow.Activate();
    }

    /// <summary>Replaces the entire window content (used for sign-in / sign-out transitions).</summary>
    public static void NavigateRoot(Type pageType)
        => Instance.MainWindow!.RootFrame.Navigate(pageType);
}
