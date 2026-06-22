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
        SignInCommand = new AsyncRelayCommand(SignInAsync);
        CancelCommand = new RelayCommand(Cancel);
    }

    private bool _isBusy;
    public bool IsBusy { get => _isBusy; private set => SetProperty(ref _isBusy, value); }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public IAsyncRelayCommand SignInCommand { get; }
    public IRelayCommand CancelCommand { get; }

    private async Task SignInAsync()
    {
        IsBusy = true;
        Error = null;

        // Auto-cancel after a few minutes so a closed/abandoned browser tab never
        // leaves the app stuck on the spinner.
        _cts = new CancellationTokenSource(TimeSpan.FromMinutes(3));
        try
        {
            await _services.Session.SignInWithGoogleAsync(_cts.Token);
            App.NavigateRoot(typeof(Views.ShellPage));
            App.BringToFront();
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
