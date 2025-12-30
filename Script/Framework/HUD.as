class AFishHUD : AHUD
{
	UPROPERTY()
	TSubclassOf<UUserWidget> HUDWidgetClass;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UUserWidget HUDWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BP_BeginPlay();

		System::SetTimer(this, n"LatePlay", 0.3f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void LatePlay()
	{
		HUDWidget = WidgetBlueprint::CreateWidget(HUDWidgetClass, GetOwningPlayerController());
		HUDWidget.AddToViewport();

		Widget::SetInputMode_GameAndUIEx(GetOwningPlayerController(), HUDWidget, EMouseLockMode::LockInFullscreen);
		GetOwningPlayerController().bShowMouseCursor = true;

		AddNotification("Welcome to Fishing Game!", 3.5f);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Add Notification")
	void AddNotificationEvent(FText Title, float Duration = 3.5f)
	{}

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

namespace Notifications
{
	UFUNCTION(Category = "Notifications", DisplayName = "Add Notification")
	void AddNotification(FString Title, float Duration = 3.5f)
	{
		if (Title.Len() > 30) PrintWarning("Notification title too long! Max 30 characters.", 5.0f);

		AFishHUD FishHUD = GetFishHUD();
		if (FishHUD != nullptr)
		{
			FishHUD.AddNotification(Title, Duration);
		}
	}

}