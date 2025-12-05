class AFishCharacter : AFishEntity
{
	UPROPERTY(Category = "Components", NotVisible, BlueprintHidden)
	UAbilityHandlerComponent AbilityHandler;

	UPROPERTY(Category = "Components", NotVisible, BlueprintHidden)
	UInventoryComponent InventoryComponent;

	UPROPERTY(Category = "Components", NotVisible, BlueprintHidden)
	UFishingStateComponent FishingState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AbilityHandler = UAbilityHandlerComponent::Get(this); // using BP child so I need to get it here.
		InventoryComponent = UInventoryComponent::Get(this); // using BP child so I need to get it here.
		FishingState = UFishingStateComponent::Get(this); // using BP child so I need to get it here.

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	FText InfoText;
	int ExperienceLevel;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UTextRenderComponent TextRender = UTextRenderComponent::Get(this);
		if (TextRender == nullptr)
			return;

		auto PS = Cast<AFishPlayerState>(PlayerState);
		if (PS == nullptr)
			return;

		EFishingState State = FishingState.CurrentState;
		FString NiceName = String::RightChop(f"{State}", 15); // Remove "FishingState::"
		NiceName = String::LeftChop(NiceName, 4);			  // Remove " (0)"

		FText CurrentFish = FishingState.CurrentFish != nullptr ? FishingState.CurrentFish.FishName : FText::FromString("None");

		float ExperiencePoints = PS.Stats.ExperiencePoints;
		float ToNextLevel = PS.GetXPToLevelUp();
		ExperienceLevel = PS.Stats.ExperienceLevel;
		float BiteTimer = FishingState.BiteTimer;
		TArray<FString> MoochedFishNames;
		for (TSubclassOf<AFish> FishClass : FishingState.MoochedFish)
		{
			MoochedFishNames.Add(FishClass.DefaultObject.FishName.ToString());
		}
		FString Joined = FString::Join(MoochedFishNames, ",");
		FText FishingHole = FishingState.CurrentFishingHole.HoleName;

		InfoText = FText::FromString(f"{NiceName}\n{CurrentFish}\nLevel {ExperienceLevel} ({ExperiencePoints}/{Math::FloorToInt(ToNextLevel)})\n{RoundTo(BiteTimer, 2)}s\n{Joined}\n{FishingHole}");
		TextRender.SetText(InfoText);

		BP_Tick(DeltaSeconds);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(float DeltaSeconds)
	{}

	UFUNCTION(BlueprintOverride)
	void Possessed(AController NewController)
	{
#if EDITOR
		// Can't be in BeginPlay because PlayerState isn't set yet
		SetActorLabel(f"FishCharacter ({NewController.PlayerState.PlayerId})");
#endif
	}

	UFUNCTION(Client, NotBlueprintCallable)
    void AddFish_Client(UItem Item)
    {
        if (InventoryComponent == nullptr)
            InventoryComponent = UInventoryComponent::Get(this);

        if (InventoryComponent != nullptr)
            InventoryComponent.AddItem(Item);
        
    }

	UFUNCTION(BlueprintEvent)
	void HotbarSlotPressed(int SlotIndex)
	{}
};

UFUNCTION(BlueprintPure)
AFishCharacter GetFishCharacterBase(int PlayerIndex = 0)
{
	return Cast<AFishCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}

UFUNCTION(BlueprintPure, Category = "Math", Meta = (CompactNodeTitle = "Round", Keywords = "round,decimal,places"))
float RoundTo(float Value, int DecimalPlaces)
{
	float Multiplier = Math::Pow(10.0f, DecimalPlaces);
	return Math::RoundToFloat(Value * Multiplier) / Multiplier;
}

/**
 * Whether the game is currently running in the editor.
 */
UFUNCTION(BlueprintPure, Category = "Editor", Meta = (CompactNodeTitle = "Editor", Keywords = "editor,pc,platform"))
bool IsEditor()
{
#if EDITOR
	return true;
#else
	return false;
#endif
}