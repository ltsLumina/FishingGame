event void FOnInteract(AFishNPC NPC, ESelectionState State);
event void FOnBeginDialogue(AFishNPC NPC);
event void FOnEndDialogue(AFishNPC NPC);

enum ESelectionState
{
	Selected,
	Deselected
}

UCLASS(Meta=(PrioritizeCategories="Interaction"))
class AFishController : APlayerController
{
	UPROPERTY(Category = "Interaction", EditDefaultsOnly)
    float ClickCooldown = 0.15f;
	
	UPROPERTY(Category = "Interaction", VisibleInstanceOnly)
    bool CanClick = true;

	UPROPERTY(Category = "Interaction", VisibleInstanceOnly)
	bool IsAnythingSelected;

	UPROPERTY(Category = "Interaction", VisibleInstanceOnly)
	AFishNPC SelectedNPC;

	UPROPERTY(Category = "Interaction", VisibleInstanceOnly)
	AFishNPC PreviousNPC;

	UPROPERTY(Category = "Interaction", VisibleAnywhere)
	TMap<TSoftObjectPtr<AFishNPC>, FGameTime> InteractHistory;

	UPROPERTY(Category = "Interaction | Events")
	FOnInteract OnInteract;

	UPROPERTY(Category = "Interaction | Events")
	FOnBeginDialogue OnBeginDialogue;

	UPROPERTY(Category = "Interaction | Events")
	FOnEndDialogue OnEndDialogue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto InputComponent = UInputComponent::GetOrCreate(this);

		InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"AnyKey"));
		InputComponent.BindKey(EKeys::LeftMouseButton, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"Draw"));
		InputComponent.BindKey(EKeys::LeftMouseButton, EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"Undraw"));
	}

	UFUNCTION()
	void AnyKey(FKey PressedKey)
	{
		TArray<FKey> AllowedKeys;
		AllowedKeys.Add(EKeys::One);
		AllowedKeys.Add(EKeys::Two);
		AllowedKeys.Add(EKeys::Three);
		AllowedKeys.Add(EKeys::Four);
		AllowedKeys.Add(EKeys::Five);
		AllowedKeys.Add(EKeys::Six);
		AllowedKeys.Add(EKeys::Seven);
		AllowedKeys.Add(EKeys::Eight);
		AllowedKeys.Add(EKeys::Nine);
		AllowedKeys.Add(EKeys::Zero);

		if (AllowedKeys.Contains(PressedKey))
		{
			int SlotIndex = AllowedKeys.FindIndex(PressedKey);
			TArray<UUserWidget> Widgets;
			Widget::GetAllWidgetsOfClass(Widgets, UHotbar, false);
			if (Widgets.Num() == 0)
				return;

			UHotbar Hotbar = Cast<UHotbar>(Widgets[0]);
			if (Hotbar == nullptr)
				return;

			auto Slot = Cast<UHotbarSlot>(Hotbar.HotbarGrid.GetChildAt(SlotIndex));
			if (Slot == nullptr)
				return;

			Slot.Invoke();

			auto FishCharacter = GetFishCharacterBase();
			FishCharacter.HotbarSlotPressed(SlotIndex);
		}
	}

	bool IsDrawing;

	UFUNCTION()
	void Draw(FKey PressedKey)
	{
		IsDrawing = true;
	}

	UFUNCTION()
	void Undraw(FKey PressedKey)
	{
		IsDrawing = false;
	}

	UFUNCTION()
	void Click()
	{
        if (!CanClick) return;
        CanClick = false;
        System::SetTimer(this, n"ResetClick", ClickCooldown, false);

		FHitResult Hit;
		GetHitResultUnderCursorByChannel(ETraceTypeQuery::TraceTypeQuery3, false, Hit); // TraceTypeQuery3 = Selection
		if (Hit.bBlockingHit)
		{
			auto HitNPC = Cast<AFishNPC>(Hit.GetActor());
			if (IsValid(HitNPC))
			{
				if (HitNPC != SelectedNPC && IsValid(SelectedNPC)) // Clicked on a different NPC
				{
					// If there's already a selected NPC, deselect it first
					SelectedNPC.Deselect(this);
				}

				if (HitNPC.IsInRange(GetControlledPawn()))
				{
					HitNPC.ToggleSelection(this);
					PreviousNPC = SelectedNPC;
					
					SelectedNPC = HitNPC;
                    IsAnythingSelected = true;

					// Record interaction time
					InteractHistory.Add(SelectedNPC, TimeManager::GetGameTime());
				}
			}
			else // Clicked on something that's not an NPC (global deselect)
			{
                if (SelectedNPC == nullptr) return;
				DeselectNPC(SelectedNPC);
			}
		}
        else // Clicked on nothing (global deselect)
        {
            if (SelectedNPC == nullptr) return;

            SelectedNPC.Deselect(this);
            DeselectCurrentSelected();
        }
	}

    UFUNCTION(NotBlueprintCallable)
    private void ResetClick()
    {
        CanClick = true;
    }

	UFUNCTION()
	void SelectNPC(AFishNPC NPC)
	{
        NPC.Select(this);
        SelectedNPC = NPC;
        IsAnythingSelected = true;
	}

    UFUNCTION()
    void DeselectNPC(AFishNPC NPC)
    {
        if (NPC == nullptr) return;

        NPC.Deselect(this);
        SelectedNPC = nullptr;
        IsAnythingSelected = false;
    }

	UFUNCTION()
	void DeselectCurrentSelected()
	{
		if (SelectedNPC != nullptr)
		{
			SelectedNPC = nullptr;
			IsAnythingSelected = false;
		}
	}

	/**
	 * Checks if the specified NPC was interacted with within the given time window.
	 * @param NPC The NPC to check.
	 * @param TimeWindowInSeconds The time window in seconds.
	 * @return True if the NPC was interacted with within the time window, false otherwise.
	 */
	UFUNCTION(BlueprintPure)
	bool WasRecentlyInteractedWith(AFishNPC NPC, float TimeWindowInSeconds)
	{
		if (!InteractHistory.Contains(NPC))
		{
			return false;
		}

		FGameTime LastInteractionTime = InteractHistory[NPC];

		float TimeDifference = TimeManager::TimeSince(LastInteractionTime);
		return TimeDifference <= TimeWindowInSeconds;
	}

	/**
	 * Checks if the specified NPC was interacted with within the last N interactions.
	 * @param NPC The NPC to check.
	 * @param InteractionsAgo The number of interactions to look back.
	 * @return True if the NPC was interacted with within the last N interactions, false otherwise
	 */
	UFUNCTION(BlueprintPure, DisplayName = "Was Recently Interacted With", Category = "Interaction")
	bool WasRecentlyInteractedWith_Index(AFishNPC NPC, int InteractionsAgo)
	{
		if (!InteractHistory.Contains(NPC))
		{
			return false;
		}

		TArray<TSoftObjectPtr<AFishNPC>> Keys;
		InteractHistory.GetKeys(Keys);
		int Index = Keys.FindIndex(NPC);
		if (Index == Array::INDEX_NONE)
		{
			return false;
		}

		return Index >= Keys.Num() - InteractionsAgo - 1;
	}
};

/**
 * Gets the FishController for the local player.
 * Calling it on the Listen-Server will return the Listen-Server's PlayerController
 * Calling it on a Client will return the Client's PlayerController
 */
UFUNCTION(BlueprintPure, Category = "Controller")
AFishController GetFishControllerBase()
{
	auto PC = Gameplay::GetPlayerController(0);
	if (PC == nullptr)
	{
		return nullptr;
	}

	auto FC = Cast<AFishController>(PC);
	if (FC == nullptr)
	{
		return nullptr;
	}

	return FC;
}