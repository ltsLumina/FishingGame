class AFishController : APlayerController
{
    bool CanClick = true;
    float ClickCooldown = 0.15f;

	UPROPERTY()
	bool IsAnythingSelected;

	UPROPERTY()
	AFishNPC SelectedNPC;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto InputComponent = UInputComponent::GetOrCreate(this);

		InputComponent.BindKey(EKeys::AnyKey, EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"AnyKey"));
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

	UFUNCTION()
	void Click()
	{
        if (!CanClick) return;
        CanClick = false;
        System::SetTimer(this, n"ResetClick", ClickCooldown, false);

		FHitResult Hit;
		GetHitResultUnderCursorByChannel(ETraceTypeQuery::Visibility, false, Hit);
		if (Hit.bBlockingHit)
		{
			auto HitNPC = Cast<AFishNPC>(Hit.GetActor());
			if (IsValid(HitNPC))
			{
				if (HitNPC != SelectedNPC && IsValid(SelectedNPC)) // Clicked on a different NPC
				{
					// If there's already a selected NPC, deselect it first
					SelectedNPC.Deselect();
				}

				if (HitNPC.IsInRange(GetControlledPawn()))
				{
					HitNPC.ToggleSelection();
					SelectedNPC = HitNPC;
                    IsAnythingSelected = true;
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

            SelectedNPC.Deselect();
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
        NPC.Select();
        SelectedNPC = NPC;
        IsAnythingSelected = true;
	}

    UFUNCTION()
    void DeselectNPC(AFishNPC NPC)
    {
        if (NPC == nullptr) return;

        NPC.Deselect();
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
};

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