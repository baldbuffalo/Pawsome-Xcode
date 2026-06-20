using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace Pawsome.App;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        Title = "Pawsome";
        SystemBackdrop = new MicaBackdrop();

        if (AppWindow is not null)
        {
            AppWindow.SetIcon("Assets/app.ico");
            AppWindow.Title = "Pawsome";
        }
    }

    public Frame RootFrame => RootFrameElement;
}
