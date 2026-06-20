using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pawsome.App.Services;

namespace Pawsome.App.ViewModels;

/// <summary>Sign-in screen view-model.</summary>
public sealed class LoginViewModel : ObservableObject
{
    private readonly AppServices _services;

    public LoginViewModel(AppServices services)
    {
        _services = services;
        SignInCommand = new AsyncRelayCommand(SignInAsync);
    }

    private bool _isBusy;
    public bool IsBusy { get => _isBusy; private set => SetProperty(ref _isBusy, value); }

    private string? _error;
    public string? Error { get => _error; private set => SetProperty(ref _error, value); }

    public IAsyncRelayCommand SignInCommand { get; }

    private async Task SignInAsync()
    {
        IsBusy = true;
        Error = null;
        try
        {
            await _services.Session.SignInWithGoogleAsync();
            App.NavigateRoot(typeof(Views.ShellPage));
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }
}
