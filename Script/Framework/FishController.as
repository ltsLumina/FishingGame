class AFishController : APlayerController
{
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
};