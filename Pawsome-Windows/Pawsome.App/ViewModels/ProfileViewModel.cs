using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.App.Services;
using Windows.Storage;

namespace Pawsome.App.ViewModels;

/// <summary>Profile screen: edit username, change avatar, sign out.</summary>
public sealed class ProfileViewModel : ObservableObject
{
    private readonly AppServices _services;

    public ProfileViewModel(AppServices services)
    {
        _services = services;
        _username = services.Session.CurrentUser?.Username ?? "";
        SaveUsernameCommand = new AsyncRelayCommand(SaveUsernameAsync);
        LogoutCommand = new RelayCommand(Logout);
    }

    private string _username;
    public string Username { get => _username; set => SetProperty(ref _username, value); }

    public string? ProfilePicUrl => _services.Session.CurrentUser?.ProfilePic;

    private bool _isUploading;
    public bool IsUploading { get => _isUploading; private set => SetProperty(ref _isUploading, value); }

    private string? _status;
    public string? Status { get => _status; private set => SetProperty(ref _status, value); }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public IAsyncRelayCommand SaveUsernameCommand { get; }
    public IRelayCommand LogoutCommand { get; }

    private async Task SaveUsernameAsync()
    {
        var trimmed = Username.Trim();
        var uid = _services.Session.CurrentUid;
        if (string.IsNullOrEmpty(trimmed) || uid is null || trimmed == _services.Session.CurrentUser?.Username)
            return;

        Status = null;
        Error = null;
        try
        {
            await _services.Firestore.UpdateUserAsync(uid, new Dictionary<string, object?> { ["username"] = trimmed });
            _services.Session.ApplyUsername(trimmed);
            Status = "✓ Saved";
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
    }

    /// <summary>Called by the page after the user picks a file (page owns the picker + window handle).</summary>
    public async Task UploadProfilePictureAsync(StorageFile file)
    {
        var uid = _services.Session.CurrentUid;
        if (uid is null) return;

        IsUploading = true;
        Error = null;
        try
        {
            if (!_services.GitHub.HasToken)
                throw new InvalidOperationException(
                    "No image-upload token configured. Set the PAWSOME_GITHUB_TOKEN environment variable to change your photo.");

            var jpeg = await _services.Images.EncodeJpegAsync(file, maxDimension: 400);
            var url = await _services.GitHub.UploadImageAsync(jpeg, $"{uid}.jpg", "profilePictures");
            await _services.Firestore.UpdateUserAsync(uid, new Dictionary<string, object?> { ["profilePic"] = url });
            _services.Session.ApplyProfilePic(url);
            OnPropertyChanged(nameof(ProfilePicUrl));
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsUploading = false;
        }
    }

    private void Logout()
    {
        _services.Session.SignOut();
        App.NavigateRoot(typeof(Views.LoginPage));
    }
}
