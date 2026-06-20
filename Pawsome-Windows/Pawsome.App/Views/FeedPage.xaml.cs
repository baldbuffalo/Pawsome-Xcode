using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Animation;
using Microsoft.UI.Xaml.Navigation;
using Pawsome.App.ViewModels;

namespace Pawsome.App.Views;

public sealed partial class FeedPage : Page, IPostInteraction
{
    public FeedViewModel ViewModel { get; }

    public FeedPage()
    {
        ViewModel = new FeedViewModel(App.Instance.Services, this, DispatcherQueue);
        InitializeComponent();
    }

    protected override async void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        await ViewModel.LoadAsync();
        ViewModel.StartPolling();
    }

    protected override void OnNavigatedFrom(NavigationEventArgs e)
    {
        ViewModel.StopPolling();
        base.OnNavigatedFrom(e);
    }

    private void CreatePost_Click(object sender, RoutedEventArgs e)
        => Frame.Navigate(typeof(CreatePostPage), null, new EntranceNavigationTransitionInfo());

    // ── IPostInteraction ────────────────────────────────────────────────────
    public async Task ShowCommentsAsync(PostItemViewModel post)
    {
        var dialog = new CommentsDialog(post) { XamlRoot = XamlRoot };
        await dialog.ShowAsync();
    }

    public async Task ConfirmDeleteAsync(PostItemViewModel post)
    {
        var confirm = new ContentDialog
        {
            Title = "Delete this post?",
            Content = "This action cannot be undone.",
            PrimaryButtonText = "Delete",
            CloseButtonText = "Cancel",
            DefaultButton = ContentDialogButton.Close,
            XamlRoot = XamlRoot,
        };

        if (await confirm.ShowAsync() != ContentDialogResult.Primary) return;

        try
        {
            var services = App.Instance.Services;
            var fileName = post.Model.ImageFileName;
            if (!string.IsNullOrEmpty(fileName) && services.GitHub.HasToken)
                await services.GitHub.DeleteFileAsync($"postImages/{fileName}");

            await services.Firestore.DeletePostAsync(post.Model.Id);
            ViewModel.Posts.Remove(post);
        }
        catch (Exception ex)
        {
            await ShowMessageAsync("Couldn't delete post", ex.Message);
        }
    }

    public void ShowImage(string imageUrl)
    {
        var viewer = new ImageViewerWindow(imageUrl);
        viewer.Activate();
    }

    private async Task ShowMessageAsync(string title, string message)
    {
        var dialog = new ContentDialog
        {
            Title = title,
            Content = message,
            CloseButtonText = "OK",
            XamlRoot = XamlRoot,
        };
        await dialog.ShowAsync();
    }
}
