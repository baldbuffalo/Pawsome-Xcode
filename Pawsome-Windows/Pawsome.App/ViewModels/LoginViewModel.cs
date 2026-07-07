using System.Threading;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
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
        SignInCommand = new AsyncRelayCommand(() => RunGoogleAsync());
        TwitterSignInCommand = new AsyncRelayCommand(() => RunTwitterAsync());
        CancelCommand = new RelayCommand(Cancel);
    }

    private bool _isBusyGoogle;
    public bool IsBusyGoogle { get => _isBusyGoogle; private set => SetProperty(ref _isBusyGoogle, value); }

    private bool _isBusyTwitter;
    public bool IsBusyTwitter { get => _isBusyTwitter; private set => SetProperty(ref _isBusyTwitter, value); }

    public bool IsBusy => IsBusyGoogle || IsBusyTwitter;

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public IAsyncRelayCommand SignInCommand { get; }
    public IAsyncRelayCommand TwitterSignInCommand { get; }
    public IRelayCommand CancelCommand { get; }

    private async Task RunGoogleAsync()
    {
        IsBusyGoogle = true;
        Error = null;
        _cts = new CancellationTokenSource(TimeSpan.FromMinutes(3));
        try
        {
            await _services.Session.SignInWithGoogleAsync(_cts.Token);
            App.NavigateRoot(typeof(Views.ShellPage));
            App.BringToFront();
        }
        catch (OperationCanceledException)
        {
            Error = "Sign-in was canceled. Tap a sign-in button to try again.";
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsBusyGoogle = false;
            _cts?.Dispose();
            _cts = null;
        }
    }

    private async Task RunTwitterAsync()
    {
        IsBusyTwitter = true;
        Error = null;
        _cts = new CancellationTokenSource(TimeSpan.FromMinutes(3));
        try
        {
            await _services.Session.SignInWithTwitterAsync(_cts.Token);
            App.NavigateRoot(typeof(Views.ShellPage));
            App.BringToFront();
        }
        catch (OperationCanceledException)
        {
            Error = "Sign-in was canceled. Tap a sign-in button to try again.";
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsBusyTwitter = false;
            _cts?.Dispose();
            _cts = null;
        }
    }

    private void Cancel() => _cts?.Cancel();
}
