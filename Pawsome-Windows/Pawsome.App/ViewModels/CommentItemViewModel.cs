using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.App.Services;
using Pawsome.Core.Models;

namespace Pawsome.App.ViewModels;

/// <summary>A single comment, with inline edit and delete for the author.</summary>
public sealed class CommentItemViewModel : ObservableObject
{
    private readonly AppServices _services;
    private readonly Action<CommentItemViewModel> _onDeleted;

    public PostComment Model { get; private set; }

    public CommentItemViewModel(PostComment model, AppServices services, string? currentUid, Action<CommentItemViewModel> onDeleted)
    {
        Model = model;
        _services = services;
        _onDeleted = onDeleted;
        CanModify = model.IsOwnedBy(currentUid);

        DeleteCommand = new AsyncRelayCommand(DeleteAsync);
        BeginEditCommand = new RelayCommand(() => { EditText = Text; IsEditing = true; });
        CancelEditCommand = new RelayCommand(() => IsEditing = false);
        SaveEditCommand = new AsyncRelayCommand(SaveEditAsync);
    }

    public string Text => Model.Text;
    public string OwnerUsername => Model.OwnerUsername;
    public string OwnerProfilePic => Model.OwnerProfilePic;
    public string TimeAgo => Model.TimeAgo;
    public bool CanModify { get; }

    private bool _isEditing;
    public bool IsEditing { get => _isEditing; private set => SetProperty(ref _isEditing, value); }

    private string _editText = "";
    public string EditText { get => _editText; set => SetProperty(ref _editText, value); }

    public IAsyncRelayCommand DeleteCommand { get; }
    public IRelayCommand BeginEditCommand { get; }
    public IRelayCommand CancelEditCommand { get; }
    public IAsyncRelayCommand SaveEditCommand { get; }

    private async Task DeleteAsync()
    {
        if (!CanModify) return;
        try
        {
            await _services.Firestore.DeleteCommentAsync(Model.PostId, Model.Id);
            _onDeleted(this);
        }
        catch { /* leave the comment in place if the delete failed */ }
    }

    private async Task SaveEditAsync()
    {
        var trimmed = EditText.Trim();
        if (string.IsNullOrEmpty(trimmed) || trimmed == Text) { IsEditing = false; return; }

        try
        {
            await _services.Firestore.UpdateCommentTextAsync(Model.PostId, Model.Id, trimmed);
            Model = new PostComment
            {
                Id = Model.Id,
                PostId = Model.PostId,
                Text = trimmed,
                OwnerUid = Model.OwnerUid,
                OwnerUsername = Model.OwnerUsername,
                OwnerProfilePic = Model.OwnerProfilePic,
                Timestamp = Model.Timestamp,
            };
            OnPropertyChanged(nameof(Text));
        }
        finally
        {
            IsEditing = false;
        }
    }
}
