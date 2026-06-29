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
        SignInCommand = new AsyncRelayCommand(() => RunAsync(_services.Session.SignInWithGoogleAsync));
        TwitterSignInCommand = new AsyncRelayCommand(() => RunAsync(_services.Session.SignInWithTwitterAsync));
        CancelCommand = new RelayCommand(Cancel);
    }

    private bool _isBusy;
    public bool IsBusy { get => _isBusy; private set => SetProperty(ref _isBusy, value); }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public IAsyncRelayCommand SignInCommand { get; }
    public IAsyncRelayCommand TwitterSignInCommand { get; }
    public IRelayCommand CancelCommand { get; }

    private async Task RunAsync(Func<CancellationToken, Task> signIn)
    {
        IsBusy = true;
        Error = null;
        _cts = new CancellationTokenSource(TimeSpan.FromMinutes(3));
        try
        {
            await signIn(_cts.Token);
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
            IsBusy = false;
            _cts?.Dispose();
            _cts = null;
        }
    }

    private void Cancel() => _cts?.Cancel();
}
