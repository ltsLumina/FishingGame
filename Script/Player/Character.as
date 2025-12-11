class AFishCharacter : AFishEntity
{
	UPROPERTY(Category = "Components", NotVisible, BlueprintHidden)
	UAbilityHandlerComponent AbilityHandler;

	UPROPERTY(Category = "Components", NotVisible, BlueprintHidden)
	UFishingComponent FishingComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AbilityHandler = UAbilityHandlerComponent::Get(this); // using BP child so I need to get it here.
		FishingComponent = UFishingComponent::Get(this); // using BP child so I need to get it here.

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

		auto XPComponent = PS.ExperienceComponent;
		if (XPComponent == nullptr)
			return;

		EFishingState FishingState = FishingComponent.CurrentState;

		FText CurrentFish = FishingComponent.CurrentFish != nullptr ? FishingComponent.CurrentFish.FishName : FText::FromString("None");

		float ExperiencePoints = XPComponent.ExperienceData.CurrentXP;
		float ToNextLevel = XPComponent.GetXPToLevelUp();
		ExperienceLevel = XPComponent.ExperienceData.Level;
		float BiteTimer = FishingComponent.BiteTimer;
		TArray<FString> MoochedFishNames;
		for (TSubclassOf<AFish> FishClass : FishingComponent.MoochedFish)
		{
			MoochedFishNames.Add(FishClass.DefaultObject.FishName.ToString());
		}
		FString Joined = FString::Join(MoochedFishNames, ",");
		FText FishingHole = IsValid(FishingComponent.CurrentFishingHole) ? FishingComponent.CurrentFishingHole.HoleName : FText::FromString("None");

		InfoText = FText::FromString(f"{FishingState :n}\n{CurrentFish}\nLevel {ExperienceLevel} ({ExperiencePoints}/{Math::FloorToInt(ToNextLevel)})\n{RoundTo(BiteTimer, 2)}s\n{Joined}\n{FishingHole}");
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

	UFUNCTION(BlueprintEvent)
	void HotbarSlotPressed(int SlotIndex)
	{}
};

UFUNCTION(BlueprintPure)
AFishCharacter GetFishCharacterBase(int PlayerIndex = 0)
{
	auto PC = Gameplay::GetPlayerController(PlayerIndex);
	if (PC == nullptr)
	{
		return nullptr;
	}

	auto Char = Cast<AFishCharacter>(PC.GetControlledPawn());
	if (Char == nullptr)
	{
		return nullptr;
	}

	return Char;
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