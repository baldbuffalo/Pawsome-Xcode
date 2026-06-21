using System.Threading;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.Core;
using Pawsome.App.Services;

namespace Pawsome.App.ViewModels;

/// <summary>Sign-in screen view-model.</summary>
public sealed class LoginViewModel : ObservableObject
{
    private readonly AppServices _services;
    private CancellationTokenSource? _cts;

    public LoginViewModel(AppServices services)
    {
        _services = services;
        _googleClientId = services.Secrets.Get(SecureStore.GoogleClientIdKey) ?? "";
        SignInCommand = new AsyncRelayCommand(SignInAsync);
        CancelCommand = new RelayCommand(Cancel);
    }

    private bool _isBusy;
    public bool IsBusy { get => _isBusy; private set => SetProperty(ref _isBusy, value); }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    private string _googleClientId;
    public string GoogleClientId { get => _googleClientId; set => SetProperty(ref _googleClientId, value); }

    public IAsyncRelayCommand SignInCommand { get; }
    public IRelayCommand CancelCommand { get; }

    private async Task SignInAsync()
    {
        // Persist a client id typed into the Advanced field so the flow can use it.
        var typed = GoogleClientId?.Trim();
        if (!string.IsNullOrEmpty(typed))
            _services.Secrets.Set(SecureStore.GoogleClientIdKey, typed);

        var hasClientId =
            !string.IsNullOrWhiteSpace(_services.Secrets.Get(SecureStore.GoogleClientIdKey)) ||
            !string.IsNullOrWhiteSpace(PawsomeConfig.GoogleDesktopClientId);

        if (!hasClientId)
        {
            Error = "Add a Google \"Desktop app\" OAuth client ID under Advanced below, then try again.";
            return;
        }

        IsBusy = true;
        Error = null;

        // Auto-cancel after a few minutes so a closed/abandoned browser tab never
        // leaves the app stuck on the spinner.
        _cts = new CancellationTokenSource(TimeSpan.FromMinutes(3));
        try
        {
            await _services.Session.SignInWithGoogleAsync(_cts.Token);
            App.NavigateRoot(typeof(Views.ShellPage));
        }
        catch (OperationCanceledException)
        {
            Error = "Sign-in was canceled. Tap \"Sign in with Google\" to try again.";
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsBusy = false;
            _cts?.Dispose();
            _cts = null;
        }
    }

    private void Cancel() => _cts?.Cancel();
}
