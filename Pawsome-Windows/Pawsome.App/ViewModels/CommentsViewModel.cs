using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.App.Services;

namespace Pawsome.App.ViewModels;

/// <summary>Comments for a post, shown in a dialog.</summary>
public sealed class CommentsViewModel : ObservableObject
{
    private readonly AppServices _services;
    public PostItemViewModel Post { get; }
    public ObservableCollection<CommentItemViewModel> Comments { get; } = new();

    public CommentsViewModel(AppServices services, PostItemViewModel post)
    {
        _services = services;
        Post = post;
        PostCommentCommand = new AsyncRelayCommand(PostCommentAsync, () => CanPost);
    }

    public string CatName => Post.CatName;
    public string OwnerUsername => Post.OwnerUsername;
    public string ImageUrl => Post.ImageUrl;
    private bool _isLoading = true;
    public bool IsLoading { get => _isLoading; private set => SetProperty(ref _isLoading, value); }
    private bool _isEmpty;
    public bool IsEmpty { get => _isEmpty; private set => SetProperty(ref _isEmpty, value); }
    private bool _isPosting;
    public bool IsPosting { get => _isPosting; private set { if (SetProperty(ref _isPosting, value)) OnPostStateChanged(); } }
    private string _newComment = "";
    public string NewComment { get => _newComment; set { if (SetProperty(ref _newComment, value)) OnPostStateChanged(); } }
    public bool CanPost => !IsPosting && !string.IsNullOrWhiteSpace(NewComment);
    public IAsyncRelayCommand PostCommentCommand { get; }

    public async Task LoadAsync()
    {
        IsLoading = true;
        try
        {
            var comments = await _services.Firestore.GetCommentsAsync(Post.Model.Id);
            Comments.Clear();
            var userID = _services.Session.CurrentUser?.UserNumber;
            foreach (var c in comments)
                Comments.Add(new CommentItemViewModel(c, _services, userID, RemoveLocally));
        }
        finally
        {
            IsLoading = false;
            IsEmpty = Comments.Count == 0;
        }
    }

    private async Task PostCommentAsync()
    {
        var text = NewComment.Trim();
        var user = _services.Session.CurrentUser;
        if (string.IsNullOrEmpty(text) || user is null || user.UserNumber <= 0) return;
        IsPosting = true;
        try
        {
            var fields = new Dictionary<string, object?>
            {
                ["text"] = text,
                ["UserID"] = (long)user.UserNumber,
                ["Username"] = user.Username,
                ["ProfilePic"] = user.ProfilePic ?? "",
                ["timestamp"] = DateTimeOffset.UtcNow,
            };
            await _services.Firestore.AddCommentAsync(Post.Model.Id, fields);
            NewComment = "";
            Post.AdjustCommentCount(1);
            await LoadAsync();
        }
        finally { IsPosting = false; }
    }

    private void RemoveLocally(CommentItemViewModel item)
    {
        if (Comments.Remove(item))
        {
            Post.AdjustCommentCount(-1);
            IsEmpty = Comments.Count == 0;
        }
    }

    private void OnPostStateChanged()
    {
        OnPropertyChanged(nameof(CanPost));
        PostCommentCommand.NotifyCanExecuteChanged();
    }
}
