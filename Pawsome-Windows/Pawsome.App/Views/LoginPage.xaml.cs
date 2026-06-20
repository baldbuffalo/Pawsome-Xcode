using Microsoft.UI.Xaml.Controls;
using Pawsome.App.ViewModels;

namespace Pawsome.App.Views;

public sealed partial class LoginPage : Page
{
    public LoginViewModel ViewModel { get; }

    public LoginPage()
    {
        ViewModel = new LoginViewModel(App.Instance.Services);
        InitializeComponent();
    }
}
