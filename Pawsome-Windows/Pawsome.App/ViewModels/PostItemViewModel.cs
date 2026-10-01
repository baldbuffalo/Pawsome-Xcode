using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.App.Services;
using Pawsome.Core.Models;

namespace Pawsome.App.ViewModels;

/// <summary>A single post in the feed, using Android UserID for ownership.</summary>
public sealed class PostItemViewModel : ObservableObject
{
    private readonly AppServices _services;
    private readonly IPostInteraction _interaction;
    private readonly string? _currentUid;
    private readonly int? _currentUserID;

    public Post Model { get; private set; }

    public PostItemViewModel(Post model, AppServices services, IPostInteraction interaction, string? currentUid)
    {
        Model = model;
        _services = services;
        _interaction = interaction;
        _currentUid = currentUid;
        _currentUserID = services.Session.CurrentUser?.UserNumber;

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
    public bool CanDelete => _currentUserID is not null && Model.UserID == _currentUserID.Value;

    public IAsyncRelayCommand DeleteCommand { get; }
    public IRelayCommand OpenImageCommand { get; }

    public void UpdateFrom(Post fresh)
    {
        Model = fresh;
        OnPropertyChanged(nameof(TimeAgo));
        OnPropertyChanged(nameof(OwnerUsername));
        OnPropertyChanged(nameof(OwnerProfilePic));
    }
}
