class UFishWidget : UUserWidget
{
	/**
	 * The fish character that owns this widget.
	 * Will always point to the local player's character on the local machine, and be null on remote clients.
	 */
	UPROPERTY(BlueprintReadOnly, NotVisible)
	AFishCharacter Character;

	/**
	 * The fish player state that owns this widget.
	 * Will always point to the local player's state on the local machine, and be null on remote clients.
	 */
	UPROPERTY(BlueprintReadOnly, NotVisible)
	AFishPlayerState PlayerState;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		bool HasOwningPlayerPawn = GetOwningPlayerPawn() != nullptr;
		if (HasOwningPlayerPawn) Character = Cast<AFishCharacter>(GetOwningPlayerPawn());
		else Character = GetFishCharacterBase(0);
		
		if (IsValid(Character))
			PlayerState = Cast<AFishPlayerState>(Character.PlayerState);

		if (Character == nullptr || PlayerState == nullptr)
		{
			System::SetTimer(this, n"Construct", 0.1f, false);
			return;
		}

		OnVisibilityChanged.AddUFunction(this, n"HandleVisibilityChanged");
		OnVisibilityChanged.AddUFunction(this, n"OnVisibilityChangedEvent");

		BP_Construct();
		ConstructFadeIn();
	}

	UFUNCTION(BlueprintEvent)
	void ConstructFadeIn()
	{ }

	UFUNCTION(NotBlueprintCallable)
	private void HandleVisibilityChanged(ESlateVisibility InVisibility)
	{
		switch (InVisibility)
		{
			case ESlateVisibility::Visible:
			case ESlateVisibility::SelfHitTestInvisible:
			case ESlateVisibility::HitTestInvisible:
				BecameVisible(InVisibility);
				break;

			case ESlateVisibility::Collapsed:
			case ESlateVisibility::Hidden:
				BecameHidden(InVisibility);
				break;
		}

		OnVisibilityChangedEvent(InVisibility);
	}

	/**
	 * Toggles the visibility of the widget between two states.
	 * @param Visible The visibility state to set when the widget becomes visible.
	 * @param Hidden The visibility state to set when the widget becomes hidden.
	 */
	UFUNCTION()
	void ToggleVisibility(ESlateVisibility Visible = ESlateVisibility::Visible, ESlateVisibility Hidden = ESlateVisibility::Collapsed)
	{
		if (IsVisible())
		{
			SetVisibility(Hidden);
		}
		else
		{
			SetVisibility(Visible);
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	UFUNCTION(BlueprintEvent)
	void BecameVisible(ESlateVisibility NewVisibility)
	{}

	UFUNCTION(BlueprintEvent)
	void BecameHidden(ESlateVisibility NewVisibility)
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "On Visibility Changed")
	void OnVisibilityChangedEvent(ESlateVisibility NewVisibility)
	{}

	UFUNCTION()
	void Show(ESlateVisibility NewVisibility = ESlateVisibility::Visible)
	{
		SetVisibility(NewVisibility);
	}

	UFUNCTION()
	void Hide(ESlateVisibility NewVisibility = ESlateVisibility::Hidden)
	{
		SetVisibility(NewVisibility);
	}
};

UFUNCTION(DisplayName = "Show (Static)")
void Show(UFishWidget Widget, ESlateVisibility NewVisibility = ESlateVisibility::Visible)
{
	Widget.SetVisibility(NewVisibility);
}

UFUNCTION(DisplayName = "Hide (Static)")
void Hide(UFishWidget Widget, ESlateVisibility NewVisibility = ESlateVisibility::Hidden)
{
	Widget.SetVisibility(NewVisibility);
}