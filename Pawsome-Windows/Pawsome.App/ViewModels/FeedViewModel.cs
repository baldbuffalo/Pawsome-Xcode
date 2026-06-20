using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Dispatching;
using Pawsome.App.Services;
using Pawsome.Core.Models;

namespace Pawsome.App.ViewModels;

/// <summary>The home feed: loads posts, polls for near-real-time updates, and
/// merges changes in place so likes/scroll position survive a refresh.</summary>
public sealed class FeedViewModel : ObservableObject
{
    private readonly AppServices _services;
    private readonly IPostInteraction _interaction;
    private readonly DispatcherQueue _dispatcher;
    private DispatcherQueueTimer? _pollTimer;

    public ObservableCollection<PostItemViewModel> Posts { get; } = new();

    public FeedViewModel(AppServices services, IPostInteraction interaction, DispatcherQueue dispatcher)
    {
        _services = services;
        _interaction = interaction;
        _dispatcher = dispatcher;
        RefreshCommand = new AsyncRelayCommand(LoadAsync);
    }

    public string Greeting => $"Welcome back 👋";
    public string Username => _services.Session.CurrentUser?.Username ?? "there";

    private bool _isLoading = true;
    public bool IsLoading { get => _isLoading; private set => SetProperty(ref _isLoading, value); }

    private bool _isEmpty;
    public bool IsEmpty { get => _isEmpty; private set => SetProperty(ref _isEmpty, value); }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public IAsyncRelayCommand RefreshCommand { get; }

    public async Task LoadAsync()
    {
        try
        {
            Error = null;
            var posts = await _services.Firestore.GetPostsAsync();
            MergePosts(posts);
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsLoading = false;
            IsEmpty = Posts.Count == 0;
        }
    }

    public void StartPolling(TimeSpan? interval = null)
    {
        _pollTimer ??= _dispatcher.CreateTimer();
        _pollTimer.Interval = interval ?? TimeSpan.FromSeconds(10);
        _pollTimer.Tick -= OnPollTick;
        _pollTimer.Tick += OnPollTick;
        _pollTimer.Start();
    }

    public void StopPolling() => _pollTimer?.Stop();

    private async void OnPollTick(DispatcherQueueTimer sender, object args) => await LoadAsync();

    private void MergePosts(IReadOnlyList<Post> incoming)
    {
        var uid = _services.Session.CurrentUid;
        var incomingIds = incoming.Select(p => p.Id).ToHashSet();

        // Remove posts that no longer exist.
        for (var i = Posts.Count - 1; i >= 0; i--)
            if (!incomingIds.Contains(Posts[i].Model.Id))
                Posts.RemoveAt(i);

        // Insert new / update existing, keeping server order.
        for (var i = 0; i < incoming.Count; i++)
        {
            var post = incoming[i];
            var existing = Posts.FirstOrDefault(v => v.Model.Id == post.Id);

            if (existing is null)
            {
                var insertAt = Math.Min(i, Posts.Count);
                Posts.Insert(insertAt, new PostItemViewModel(post, _services, _interaction, uid));
            }
            else
            {
                existing.UpdateFrom(post);
                var currentIndex = Posts.IndexOf(existing);
                if (currentIndex != i && i < Posts.Count)
                    Posts.Move(currentIndex, i);
            }
        }

        IsEmpty = Posts.Count == 0;
    }
}
