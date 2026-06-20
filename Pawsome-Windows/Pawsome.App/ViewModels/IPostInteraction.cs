namespace Pawsome.App.ViewModels;

/// <summary>
/// UI actions a post card needs that involve dialogs/windows. Implemented by the
/// hosting page so the view-models stay free of view concerns.
/// </summary>
public interface IPostInteraction
{
    Task ShowCommentsAsync(PostItemViewModel post);
    Task ConfirmDeleteAsync(PostItemViewModel post);
    void ShowImage(string imageUrl);
}
