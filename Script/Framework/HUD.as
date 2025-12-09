class AFishHUD : AHUD
{
    UFishHUDWidget HUDWidget;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        auto Widget = WidgetBlueprint::CreateWidget(UFishHUDWidget, Gameplay::GetPlayerController(0));
        HUDWidget = Cast<UFishHUDWidget>(Widget);
        HUDWidget.AddToViewport();

        Widget::SetInputMode_GameAndUIEx(Gameplay::GetPlayerController(0), HUDWidget, EMouseLockMode::LockInFullscreen);
        Gameplay::GetPlayerController(0).bShowMouseCursor = true;

        AddNotification(FText::FromString("Welcome to Fishing Game!"), 5.0f);
        
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    UFUNCTION()
    void AddNotification(FText Title, float Duration = 5.0f)
    {
        auto Widget = WidgetBlueprint::CreateWidget(UNotification, Gameplay::GetPlayerController(0));
        auto Notification = Cast<UNotification>(Widget);
        Notification.Duration = Duration;
        Notification.SetPadding(FMargin(0, 10));
        HUDWidget.NotificationBox.AddChild(Notification);
    }
};