UCLASS(NotBlueprintable)
class UFishWidgetBase : UUserWidget
{
	/**
	 * The fish character that owns this widget.
	 * Will always point to the local player's character on the local machine, and be null on remote clients.
	 */
	UPROPERTY(Category = "Fish Widget", BlueprintReadOnly, NotVisible)
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

	UPROPERTY(Category = "Initialization", NotVisible, BlueprintReadOnly)
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

		ReceivePostInitialize(Character, FishState);
		PostInitialize(Character, FishState);

		System::ClearTimer(this, "Initialize");
	}

	/**
	 * Called after the widget has been initialized and Construct has run successfully.
	 * References to Character and FishState are guaranteed to be valid here.
	 */
	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InFishState)
	{}

	/**
	 * Called after the widget has been initialized and Construct has run successfully.
	 * References to Character and FishState are guaranteed to be valid here.
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Post Initialize")
	void ReceivePostInitialize(AFishCharacter InCharacter, AFishPlayerState InFishState)
	{}
}

enum EWidgetFadeState
{
	FadeIn,
	FadeOut,
	None
}

delegate void FOnWidgetFadeComplete(EWidgetFadeState FadeState);

UCLASS(Abstract, Blueprintable)
class UFishWidget : UFishWidgetBase
{
	UPROPERTY(Category = "Widget | Customization", EditDefaultsOnly)
	USoundBase ShowSound;

	UPROPERTY(Category = "Widget | Customization", EditDefaultsOnly)
	USoundBase HideSound;

	/**
	 * In seconds, how long it takes the widget to fade in/out.
	 */
	UPROPERTY(Category = "Widget | Customization", EditDefaultsOnly, Meta = (Units = "s", UIMin = "0.0", UIMax = "1.0", Delta = "0.05"))
	float FadeTime = 0.15f;

	UPROPERTY(Category = "Widget | Customization", NotVisible, BlueprintReadOnly)
	bool IsFadingIn;

	UPROPERTY(Category = "Widget | Customization", NotVisible, BlueprintReadOnly)
	bool IsFadingOut;

	FOnWidgetFadeComplete OnFadeComplete;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InFishState) override
	{
		Super::PostInitialize(InCharacter, InFishState);

		IsFadingIn = true;

		OnVisibilityChanged.AddUFunction(this, n"HandleVisibilityChanged");
	}

	ESlateVisibility FadeInVisibility;
	ESlateVisibility FadeOutVisibility;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (IsFadingIn)
		{
			RenderOpacity = Math::Clamp(RenderOpacity + (InDeltaTime / FadeTime), 0.0f, 1.0f);
			if (RenderOpacity >= 1.0f)
			{
				IsFadingIn = false;
				SetVisibility(FadeInVisibility);

				OnFadeComplete.ExecuteIfBound(EWidgetFadeState::FadeIn);
			}
		}

		if (IsFadingOut)
		{
			RenderOpacity = Math::Clamp(RenderOpacity - (InDeltaTime / FadeTime), 0.0f, 1.0f);
			if (RenderOpacity <= 0.0f)
			{
				IsFadingOut = false;
				SetVisibility(FadeOutVisibility);

				OnFadeComplete.ExecuteIfBound(EWidgetFadeState::FadeOut);
			}
		}

		BP_Tick(MyGeometry, InDeltaTime);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(FGeometry MyGeometry, float InDeltaTime)
	{}

	bool IgnoreVisiblityChange = false;

	UFUNCTION(Category = "Fish Widget | Visibility", Meta = (AdvancedDisplay = "FadeIn, FadeInCompleted"))
	void Show(ESlateVisibility NewVisibility = ESlateVisibility::Visible, bool FadeIn = true, FOnWidgetFadeComplete FadeInCompleted = FOnWidgetFadeComplete())
	{
		IgnoreVisiblityChange = true;
		SetVisibility(ESlateVisibility::HitTestInvisible); // not hit-testable (self & children) -- prevents interaction during fade-in

		if (FadeIn)
		{
			RenderOpacity = 0.0f;
			IsFadingIn = true;
			FadeInVisibility = NewVisibility;
			OnFadeComplete = FadeInCompleted;
		}
	}

	UFUNCTION(Category = "Fish Widget | Visibility", Meta = (AdvancedDisplay = "FadeOut, FadeOutCompleted"))
	void Hide(ESlateVisibility NewVisibility = ESlateVisibility::Collapsed, bool FadeOut = true, FOnWidgetFadeComplete FadeOutCompleted = FOnWidgetFadeComplete())
	{
		IgnoreVisiblityChange = true;
		SetVisibility(ESlateVisibility::HitTestInvisible); // not interactable -- prevents interaction during fade-out

		if (FadeOut)
		{
			RenderOpacity = 1.0f;
			IsFadingOut = true;
			FadeOutVisibility = NewVisibility;
			OnFadeComplete = FadeOutCompleted;
		}
	}

	UFUNCTION(Category = "Fish Widget", DisplayName = "Remove From Parent", Meta = (AdvancedDisplay = "FadeOut, FadeOutCompleted"), Keywords = "remove from parent")
	void RemoveFromParent_Internal(bool FadeOut = true, FOnWidgetFadeComplete FadeOutCompleted = FOnWidgetFadeComplete())
	{
		if (FadeOut)
		{
			RenderOpacity = 1.0f;
			IsFadingOut = true;
			FadeOutVisibility = ESlateVisibility::Collapsed;
			OnFadeComplete = FadeOutCompleted;
			System::SetTimer(this, n"RemoveFromParentTimer", FadeTime, false);
		}
		else
		{
			RemoveFromParent();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void RemoveFromParentTimer()
	{
		RemoveFromParent();
	}

	UFUNCTION(NotBlueprintCallable)
	private void HandleVisibilityChanged(ESlateVisibility InVisibility)
	{
		switch (InVisibility)
		{
			case ESlateVisibility::Visible:
			case ESlateVisibility::SelfHitTestInvisible:
			case ESlateVisibility::HitTestInvisible:
				if (!IgnoreVisiblityChange)
				{
					BecameVisible(InVisibility);
				}
				else
				{
					IgnoreVisiblityChange = false;
				}

				Gameplay::PlaySound2D(ShowSound, 1.0f, 1.0f, 0.0f, nullptr, GetOwningPlayerPawn(), true);
				break;

			case ESlateVisibility::Collapsed:
			case ESlateVisibility::Hidden:
				BecameHidden(InVisibility);
				{
					Gameplay::PlaySound2D(HideSound, 1.0f, 1.0f, 0.0f, nullptr, GetOwningPlayerPawn(), true);
				}
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
			Hide(Hidden);
		}
		else
		{
			Show(Visible);
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
};

namespace Widget
{
	/**
	 * Creates and returns a new FishWidget of the specified class, adding it to the viewport.
	 * The widget will automatically fade in upon creation.
	 */
	UFUNCTION(Category = "Fish Widget", Meta = (Keywords = "new widget,create,construct,widget", AdvancedDisplay = "InitialVisibility"))
	UFishWidget ConstructWidget(TSubclassOf<UFishWidget> Widget, APlayerController OwningPlayer = nullptr, ESlateVisibility InitialVisibility = ESlateVisibility::Visible)
	{
		UFishWidget NewWidget = Cast<UFishWidget>(WidgetBlueprint::CreateWidget(Widget, OwningPlayer));
		if (NewWidget != nullptr)
		{
			NewWidget.SetVisibility(InitialVisibility);
			NewWidget.AddToViewport(0);
		}
		return NewWidget;
	}
}