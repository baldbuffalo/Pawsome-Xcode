using Microsoft.UI.Xaml.Controls;
using Pawsome.App.ViewModels;

namespace Pawsome.App.Views;

public sealed partial class CommentsDialog : ContentDialog
{
    public CommentsViewModel ViewModel { get; }

    public CommentsDialog(PostItemViewModel post)
    {
        ViewModel = new CommentsViewModel(App.Instance.Services, post);
        InitializeComponent();
        Opened += async (_, _) => await ViewModel.LoadAsync();
    }
}
