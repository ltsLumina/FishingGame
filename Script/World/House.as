class AHouse : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent)
    UTextRenderComponent DebugText;
    default DebugText.bIsEditorOnly = true;

    UPROPERTY(DefaultComponent)
    UInteractableComponent Interactable;

    UPROPERTY()
    AInterior Interior;

    UFUNCTION()
    void Enter()
    {
        auto Pawn = Gameplay::GetPlayerPawn(0);
        FVector WorldPosition = Interior.GetActorTransform().TransformPosition(Interior.EnterPosition);
        Pawn.Teleport(WorldPosition, Pawn.ActorRotation);
    }
};

class UInteractableComponent : USceneComponent
{
    UPROPERTY()
    TSubclassOf<UFishWidget> PromptWidget;

    UFishWidget Widget;

    bool IsShowing;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        auto _Widget = WidgetBlueprint::CreateWidget(PromptWidget, Gameplay::GetPlayerController(0));
        Widget = Cast<UFishWidget>(_Widget);
        Widget.SetDesiredSizeInViewport(FVector2D(200, 100));
        Widget.AddToViewport();
        HidePrompt();
    }

    UFUNCTION()
    void ShowPrompt()
    {
        Widget.SetVisibility(ESlateVisibility::Visible);
        IsShowing = true;
    }

    UFUNCTION()
    void HidePrompt()
    {
        Widget.SetVisibility(ESlateVisibility::Hidden);
        IsShowing = false;
    }
}