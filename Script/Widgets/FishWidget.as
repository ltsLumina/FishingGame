class UFishWidget : UUserWidget
{
	/**
	 * The fish character that owns this widget.
	 * Will always point to the local player's character on the local machine, and be null on remote clients.
	 */
	UPROPERTY(Category ="Fish Widget", BlueprintReadOnly, NotVisible)
	AFishCharacter Character;

	/**
	 * The fish player state that owns this widget.
	 * Will always point to the local player's state on the local machine, and be null on remote clients.
	 */
	UPROPERTY(Category = "Fish Widget", BlueprintReadOnly, NotVisible)
	AFishPlayerState FishState;

	UPROPERTY(Category = "Initialization", BlueprintHidden, EditDefaultsOnly, meta = (Units = "s", UIMin = "0.01", UIMax = "1.0", AdvancedDisplay))
	float RetryDelay = 0.1f;

	UPROPERTY(Category = "Initialization", BlueprintHidden, EditDefaultsOnly, meta = (AdvancedDisplay))
	int MaxTries = 50;

	UPROPERTY(Category = "Initialization", BlueprintReadOnly, NotVisible)
	bool bInitialized = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Initialize();
	}

	int Tries = 0;
	float InitializationTime = 0.0f;

	UFUNCTION(NotBlueprintCallable)
	private void Initialize()
	{
		if (bInitialized)
			return;

		bool bHasOwningPlayerPawn = IsValid(GetOwningPlayerPawn());
		if (bHasOwningPlayerPawn) 
			Character = Cast<AFishCharacter>(GetOwningPlayerPawn());
		else 
		{
			Character = GetFishCharacterBase(0);
			PrintWarning(f"UFishWidget: ({GetName()}) OwningPlayerPawn is null, defaulting to GetFishCharacterBase(0). \nMake sure to set the Owning Player when creating the widget.");
		}
		
		if (IsValid(Character))
			FishState = Cast<AFishPlayerState>(Character.PlayerState);

		if (!IsValid(Character) || !IsValid(FishState))
		{
			if (Tries < MaxTries)
			{
				Tries++;
				System::SetTimer(this, n"Initialize", RetryDelay, false);
				return;
			}

			PrintError(f"UFishWidget: ({GetName()}) timed out! \nFailed to initialize: Character or FishState is null after multiple attempts.");
			return;
		}

		bInitialized = true;
		InitializationTime = Tries * RetryDelay;
		//Print(f"UFishWidget: ({GetName()}) initialized in {InitializationTime} seconds after {Tries} tries.", 5.0f, FLinearColor::Purple);

		ReceivePostInitialize(Character, FishState, InitializationTime);
		PostInitialize(Character, FishState, InitializationTime);

		System::ClearTimer(this, "Initialize");
	}

	/**
	 * Called after the widget has been initialized and Construct has run successfully.
	 * References to Character and FishState are guaranteed to be valid here.
	 */
	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InFishState, float InInitializationTime)
	{
		OnVisibilityChanged.AddUFunction(this, n"HandleVisibilityChanged");
		OnVisibilityChanged.AddUFunction(this, n"OnVisibilityChangedEvent");

		ConstructFadeIn(); // Calls the fade-in event on the W_FishWidget blueprint (blueprint-parent of this class)
	}

	/**
	 * Called after the widget has been initialized and Construct has run successfully.
	 * References to Character and FishState are guaranteed to be valid here.
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Post Initialize")
	void ReceivePostInitialize(AFishCharacter InCharacter, AFishPlayerState InFishState, float InInitializationTime)
	{}

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