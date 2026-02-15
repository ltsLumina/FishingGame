class AFishCharacter : AFishEntity
{
	UPROPERTY(Category = "Native Components", NotVisible)
	UAbilityHandlerComponent AbilityHandler;

	UPROPERTY(Category = "Native Components", NotVisible)
	UFishingComponent FishingComponent;

	UPROPERTY(Category = "Native Components", NotVisible)
	UEmotePlayerComponent EmotePlayerComponent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AbilityHandler = UAbilityHandlerComponent::Get(this);
		FishingComponent = UFishingComponent::Get(this);
		EmotePlayerComponent = UEmotePlayerComponent::Get(this);
	}

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

		FText CurrentFish = FishingComponent.CurrentFish != nullptr ? FishingComponent.CurrentFish.BaseData.ItemName : FText::FromString("None");

		float ExperiencePoints = XPComponent.CurrentXP;
		float ToNextLevel = XPComponent.GetExperienceAtNextLevel();
		ExperienceLevel = XPComponent.Level;
		float BiteTimer = FishingComponent.BiteTimer;
		TArray<FString> MoochedFishNames;
		for (auto& FishItem : FishingComponent.MoochedFish)
		{
			MoochedFishNames.Add(FishItem.BaseData.ItemName.ToString());
		}
		FString Joined = FString::Join(MoochedFishNames, ",");
		FText FishingHole = IsValid(FishingComponent.CurrentFishingHole) ? FishingComponent.CurrentFishingHole.HoleName : FText::FromString("None");

		InfoText = FText::FromString(f"{FishingState :n}\n{CurrentFish}\nLevel {ExperienceLevel} ({ExperiencePoints:.0}/{ToNextLevel:.0})\n{RoundTo(BiteTimer, 2)}s\n{Joined}\n{FishingHole}");
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
		SetActorLabel(f"{NewController.PlayerState.PlayerName} ({NewController.PlayerState.PlayerId})");
#endif
	}

	UFUNCTION(BlueprintEvent)
	void HotbarSlotPressed(int SlotIndex)
	{}

	UFUNCTION(Meta = (ExpandBoolAsExecs = "ReturnValue"), Category = "Pawn", DisplayName = "Is Locally Controlled")
	bool IsLocallyControlled_FishChar()
	{
		return IsLocallyControlled();
	}

	UFUNCTION()
	bool GetNearbyPlayers(float Radius = 1000.0f, TArray<AActor>&out NearbyPlayers = TArray<AActor>())
	{
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::Pawn);
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(this);
		return System::SphereOverlapActors(GetActorLocation(), Radius, ObjectTypes, AFishCharacter, IgnoreActors, NearbyPlayers);
	}
};

/**
 * Gets the FishCharacter for the specified player index (default 0).
 * Since GetPlayerController(0) always returns the local player, this function will also only return the local player's character.
 */
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

UFUNCTION(Category = "Editor", Meta = (ExpandBoolAsExecs = "ReturnValue", Keywords = "editor,pc,platform"), DisplayName = "Is Editor")
bool IsEditor_Expanded()
{
#if EDITOR
	return true;
#else
	return false;
#endif
}

UFUNCTION(Meta = (ExpandBoolAsExecs = "ReturnValue"), Category = "Pawn", DisplayName = "Is Locally Controlled")
bool IsLocallyControlled_Static(APawn Pawn)
{
	return Pawn.IsLocallyControlled();
}