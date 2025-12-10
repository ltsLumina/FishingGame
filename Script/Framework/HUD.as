class AFishHUD : AHUD
{
    UPROPERTY()
    TSubclassOf<UUserWidget> HUDWidgetClass;

    UPROPERTY(BlueprintReadOnly, NotVisible)
    UUserWidget HUDWidget;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HUDWidget = WidgetBlueprint::CreateWidget(HUDWidgetClass, Gameplay::GetPlayerController(0));
        HUDWidget.AddToViewport();

        Widget::SetInputMode_GameAndUIEx(Gameplay::GetPlayerController(0), HUDWidget, EMouseLockMode::LockInFullscreen);
        Gameplay::GetPlayerController(0).bShowMouseCursor = true;

        AddNotification("Welcome to Fishing Game!", 3.5f);
        
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintEvent, DisplayName = "Add Notification")
    void AddNotificationEvent(FText Title, float Duration = 3.5f) { }

    /**
     * Helper overload to add notification with FString title.
     */
    UFUNCTION(DisplayName = "Add Notification", Category = "HUD")
    void BP_AddNotification(FText Title, float Duration = 3.5f)
    {
        AddNotificationEvent(Title, Duration);
    }

    /**
     * Helper overload to add notification with FString title.
     */
    void AddNotification(FString Title, float Duration = 3.5f)
    {
        AddNotificationEvent(FText::FromString(Title), Duration);
    }
};

UFUNCTION(BlueprintPure, Category = "HUD")
AFishHUD GetFishHUD()
{
    return Cast<AFishHUD>(Gameplay::GetPlayerController(0).GetHUD());
}