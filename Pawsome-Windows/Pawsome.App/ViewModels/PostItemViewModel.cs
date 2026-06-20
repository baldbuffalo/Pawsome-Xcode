using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.App.Services;
using Pawsome.Core.Models;

namespace Pawsome.App.ViewModels;

/// <summary>A single post in the feed, with optimistic like/comment state.</summary>
public sealed class PostItemViewModel : ObservableObject
{
    private readonly AppServices _services;
    private readonly IPostInteraction _interaction;
    private readonly string? _currentUid;

    public Post Model { get; private set; }

    public PostItemViewModel(Post model, AppServices services, IPostInteraction interaction, string? currentUid)
    {
        Model = model;
        _services = services;
        _interaction = interaction;
        _currentUid = currentUid;

        _isLiked = model.IsLikedBy(currentUid);
        _likeCount = model.LikeCount;
        _commentCount = model.CommentCount;

        ToggleLikeCommand = new AsyncRelayCommand(ToggleLikeAsync);
        OpenCommentsCommand = new AsyncRelayCommand(() => _interaction.ShowCommentsAsync(this));
        DeleteCommand = new AsyncRelayCommand(() => _interaction.ConfirmDeleteAsync(this));
        OpenImageCommand = new RelayCommand(() => _interaction.ShowImage(Model.ImageUrl));
    }

    public string CatName => Model.CatName;
    public string AgeText => string.IsNullOrWhiteSpace(Model.Age) ? "" : $"{Model.Age} yrs";
    public string Description => Model.Description;
    public bool HasDescription => !string.IsNullOrWhiteSpace(Model.Description);
    public string OwnerUsername => Model.OwnerUsername;
    public string OwnerProfilePic => Model.OwnerProfilePic;
    public string ImageUrl => Model.ImageUrl;
    public string TimeAgo => Model.TimeAgo;
    public bool CanDelete => _currentUid is not null && Model.OwnerUid == _currentUid;

    private bool _isLiked;
    public bool IsLiked { get => _isLiked; private set => SetProperty(ref _isLiked, value); }

    private int _likeCount;
    public int LikeCount { get => _likeCount; private set => SetProperty(ref _likeCount, value); }

    private int _commentCount;
    public int CommentCount { get => _commentCount; private set => SetProperty(ref _commentCount, value); }

    public IAsyncRelayCommand ToggleLikeCommand { get; }
    public IAsyncRelayCommand OpenCommentsCommand { get; }
    public IAsyncRelayCommand DeleteCommand { get; }
    public IRelayCommand OpenImageCommand { get; }

    private async Task ToggleLikeAsync()
    {
        if (_currentUid is null) return;

        var like = !IsLiked;
        IsLiked = like;
        LikeCount += like ? 1 : -1;

        try
        {
            await _services.Firestore.ToggleLikeAsync(Model.Id, _currentUid, like);
        }
        catch
        {
            IsLiked = !like;             // revert optimistic update on failure
            LikeCount += like ? -1 : 1;
        }
    }

    public void AdjustCommentCount(int delta) => CommentCount = Math.Max(0, CommentCount + delta);

    /// <summary>Reconciles this item with fresh server data during a refresh.</summary>
    public void UpdateFrom(Post fresh)
    {
        Model = fresh;
        LikeCount = fresh.LikeCount;
        CommentCount = fresh.CommentCount;
        IsLiked = fresh.IsLikedBy(_currentUid);
        OnPropertyChanged(nameof(TimeAgo));
        OnPropertyChanged(nameof(OwnerUsername));
        OnPropertyChanged(nameof(OwnerProfilePic));
    }
}
