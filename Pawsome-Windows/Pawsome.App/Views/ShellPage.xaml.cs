using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Animation;
using Microsoft.UI.Xaml.Navigation;

namespace Pawsome.App.Views;

public sealed partial class ShellPage : Page
{
    public ShellPage() => InitializeComponent();

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (ContentFrame.Content is null)
            ContentFrame.Navigate(typeof(FeedPage));
    }

    private void Nav_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is not NavigationViewItem item) return;

        var target = (item.Tag as string) switch
        {
            "profile" => typeof(ProfilePage),
            _ => typeof(FeedPage),
        };

        if (ContentFrame.CurrentSourcePageType != target)
            ContentFrame.Navigate(target, null, new EntranceNavigationTransitionInfo());
    }
}
