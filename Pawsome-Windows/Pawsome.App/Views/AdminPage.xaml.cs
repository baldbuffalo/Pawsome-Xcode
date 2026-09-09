using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Pawsome.App.Services;

namespace Pawsome.App.Views;

public sealed partial class AdminPage : Page
{
    private static readonly Uri FunctionsBase = new("https://europe-west1-pawsome-90cb3.cloudfunctions.net/");
    private readonly AppServices _services = App.Instance.Services;
    private bool _busy;

    public AdminPage()
    {
        InitializeComponent();
        Loaded += async (_, _) => await RefreshAsync();
    }

    private async Task<JsonObject> CallAsync(string function, object? data = null)
    {
        var token = await _services.Auth.GetValidIdTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Post, new Uri(FunctionsBase, function));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Content = JsonContent.Create(new { data = data ?? new { } });
        using var response = await _services.Http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException(text);
        return JsonNode.Parse(text)?["data"]?.AsObject() ?? new JsonObject();
    }

    private async Task RefreshAsync()
    {
        if (_busy) return;
        _busy = true;
        try
        {
            var statsTask = CallAsync("adminGetStats");
            var postsTask = CallAsync("adminListDocuments", new { collectionPath = "posts", limit = 100 });
            var configTask = CallAsync("adminGetAppConfig");
            await Task.WhenAll(statsTask, postsTask, configTask);

            var stats = await statsTask;
            PostCount.Text = stats["posts"]?.GetValue<int>().ToString() ?? "0";
            UserCount.Text = stats["users"]?.GetValue<int>().ToString() ?? "0";

            var config = (await configTask)["fields"]?.AsObject() ?? new JsonObject();
            MaintenanceSwitch.IsOn = config["maintenanceMode"]?.GetValue<bool>() ?? false;
            AdsSwitch.IsOn = config["adsEnabled"]?.GetValue<bool>() ?? true;
            AnnouncementTitleBox.Text = config["announcementTitle"]?.GetValue<string>() ?? "";
            AnnouncementBodyBox.Text = config["announcementBody"]?.GetValue<string>() ?? "";

            var documents = (await postsTask)["documents"]?.AsArray();
            var rows = new List<PostRow>();
            if (documents is not null)
            {
                foreach (var node in documents)
                {
                    if (node is not JsonObject doc) continue;
                    var fields = doc["fields"]?.AsObject() ?? new JsonObject();
                    rows.Add(new PostRow(
                        doc["path"]?.GetValue<string>() ?? "",
                        fields["CatName"]?.GetValue<string>() ?? fields["catName"]?.GetValue<string>() ?? "Untitled",
                        fields["status"]?.GetValue<string>() ?? fields["Status"]?.GetValue<string>() ?? "UNKNOWN",
                        fields["location"]?.GetValue<string>() ?? fields["Location"]?.GetValue<string>() ?? ""));
                }
            }
            PostsList.ItemsSource = rows;
            ShowMessage("Admin data refreshed.", InfoBarSeverity.Informational);
        }
        catch (Exception ex)
        {
            ShowMessage(ex.Message, InfoBarSeverity.Error);
        }
        finally { _busy = false; }
    }

    private async void Refresh_Click(object sender, RoutedEventArgs e) => await RefreshAsync();

    private async void SaveSettings_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            await CallAsync("adminSetAppConfig", new
            {
                fields = new
                {
                    maintenanceMode = MaintenanceSwitch.IsOn,
                    adsEnabled = AdsSwitch.IsOn,
                    announcementTitle = AnnouncementTitleBox.Text.Trim(),
                    announcementBody = AnnouncementBodyBox.Text.Trim(),
                }
            });
            ShowMessage("Settings saved to Firebase.", InfoBarSeverity.Success);
        }
        catch (Exception ex) { ShowMessage(ex.Message, InfoBarSeverity.Error); }
    }

    private async void DeletePost_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button button || button.Tag is not string path || string.IsNullOrWhiteSpace(path)) return;
        try
        {
            await CallAsync("adminDeleteDocument", new { path });
            await RefreshAsync();
        }
        catch (Exception ex) { ShowMessage(ex.Message, InfoBarSeverity.Error); }
    }

    private void ShowMessage(string message, InfoBarSeverity severity)
    {
        MessageBar.Message = message;
        MessageBar.Severity = severity;
        MessageBar.IsOpen = true;
    }

    private sealed record PostRow(string Path, string Title, string Status, string Location);
}
