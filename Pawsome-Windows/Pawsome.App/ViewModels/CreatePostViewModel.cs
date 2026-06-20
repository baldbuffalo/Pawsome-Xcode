using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Xaml.Media.Imaging;
using Pawsome.App.Services;

namespace Pawsome.App.ViewModels;

/// <summary>Backs the "New Post" page: pick an image, fill fields, upload.</summary>
public sealed class CreatePostViewModel : ObservableObject
{
    private readonly AppServices _services;
    private byte[]? _jpegBytes;

    public CreatePostViewModel(AppServices services)
    {
        _services = services;
        SubmitCommand = new AsyncRelayCommand(SubmitAsync, () => CanSubmit);
    }

    /// <summary>Raised after a successful post so the host can navigate back and refresh.</summary>
    public event Action? PostCreated;

    private BitmapImage? _preview;
    public BitmapImage? Preview { get => _preview; private set => SetProperty(ref _preview, value); }

    public bool HasImage => _jpegBytes is not null;

    private string _catName = "";
    public string CatName { get => _catName; set { if (SetProperty(ref _catName, value)) OnInputChanged(); } }

    private string _age = "";
    public string Age { get => _age; set { if (SetProperty(ref _age, value)) OnInputChanged(); } }

    private string _description = "";
    public string Description { get => _description; set { if (SetProperty(ref _description, value)) OnInputChanged(); } }

    private bool _isPosting;
    public bool IsPosting
    {
        get => _isPosting;
        private set { if (SetProperty(ref _isPosting, value)) OnInputChanged(); }
    }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public bool CanSubmit =>
        HasImage &&
        !IsPosting &&
        !string.IsNullOrWhiteSpace(CatName) &&
        !string.IsNullOrWhiteSpace(Age) &&
        !string.IsNullOrWhiteSpace(Description);

    public IAsyncRelayCommand SubmitCommand { get; }

    public void SetImage(byte[] jpeg, BitmapImage preview)
    {
        _jpegBytes = jpeg;
        Preview = preview;
        OnPropertyChanged(nameof(HasImage));
        OnInputChanged();
    }

    private void OnInputChanged()
    {
        OnPropertyChanged(nameof(CanSubmit));
        SubmitCommand.NotifyCanExecuteChanged();
    }

    private async Task SubmitAsync()
    {
        var uid = _services.Session.CurrentUid;
        var user = _services.Session.CurrentUser;
        if (uid is null || user is null || _jpegBytes is null) return;

        IsPosting = true;
        Error = null;
        try
        {
            if (!_services.GitHub.HasToken)
                throw new InvalidOperationException(
                    "No image-upload token is configured. Add a GitHub token in Profile, or set the PAWSOME_GITHUB_TOKEN environment variable.");

            var filename = $"{uid}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}.jpg";
            var imageUrl = await _services.GitHub.UploadImageAsync(_jpegBytes, filename, "postImages");

            var fields = new Dictionary<string, object?>
            {
                ["catName"] = CatName.Trim(),
                ["description"] = Description.Trim(),
                ["age"] = Age.Trim(),
                ["imageURL"] = imageUrl,
                ["ownerUID"] = uid,
                ["ownerUsername"] = user.Username,
                ["ownerProfilePic"] = user.ProfilePic ?? "",
                ["timestamp"] = DateTimeOffset.UtcNow,
                ["likes"] = new List<object?>(),
                ["commentCount"] = 0L,
            };

            await _services.Firestore.CreatePostAsync(fields);
            PostCreated?.Invoke();
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsPosting = false;
        }
    }
}
