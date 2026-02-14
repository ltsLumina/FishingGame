event void FOnFishingHoleEntered(UFishingHoleComponent NewHole);
event void FOnFishingHoleExited(UFishingHoleComponent ExitingHole);
event void FOnSpectralShift();

struct FFishingHoleTableRow
{
	UPROPERTY()
	TArray<TSoftObjectPtr<UFishItem>> CatchableFish;
	
	UPROPERTY(Category = "Debug")
	private FGameplayTag Helper;
}

UCLASS(ClassGroup = "Fishing", Meta = (PrioritizeCategories = "Fishing"))
class UFishingHoleComponent : UActorComponent
{
	default bReplicates = true;

	UPROPERTY(Category = "Fishing | Area", EditInstanceOnly, Meta = (Categories="Hole"))
	FGameplayTag HoleTag;

	UPROPERTY(Category = "Fishing | Area", EditInstanceOnly, Meta = (Categories="Licence"))
	FGameplayTag RequiredLicence = GameplayTags::Licence_Zone1;

	UPROPERTY(Category = "Fishing | Area", DisplayName = "Name")
	FText HoleName;
	default HoleName = FText::FromName(GetName());

	UPROPERTY(Category = "Fishing | Area", VisibleInstanceOnly, Replicated)
	TArray<TSoftObjectPtr<UFishItem>> CatchableFish;

	UPROPERTY(Category = "Fishing | Area", VisibleInstanceOnly, Replicated)
	TArray<AFishCharacter> NearbyPlayers;

	UPROPERTY(Category = "Fishing | Spectral", VisibleInstanceOnly, Replicated)
	bool IsSpectral;

	UPROPERTY(Category = "Fishing | Spectral", EditAnywhere)
	TArray<TSubclassOf<UTrait>> SpectralTraits;

	UPROPERTY(Category = "Events")
	FOnSpectralShift OnSpectralShift;

	UPROPERTY(Category = "Events")
	FOnFishingHoleEntered OnHoleEntered;

	UPROPERTY(Category = "Events")
	FOnFishingHoleExited OnHoleExited;

	AFishCharacter Character;
	UFishingComponent FishingComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Table = GetFishGameStateBase().FishingHoleDataTable;
		TArray<FGameplayTag> Tags;
		DataTableGameplayTag::GetDataTableRowTags(Table, Tags);

		for (FGameplayTag Tag : Tags)
		{
			if (Tag.MatchesTagExact(HoleTag))
			{
				FFishingHoleTableRow Row;
				if (Table.FindRow(Tag.TagName, Row))
				{
					CatchableFish = Row.CatchableFish;
					break;
				}
				else
				{
					PrintError("Fishing Hole Component could not find row for tag: " + Tag.ToString());
				}
			}
		}
		
		System::SetTimerForNextTick(this, "ValidateCatchableFish");
	}

	UFUNCTION(NotBlueprintCallable)
	void ValidateCatchableFish()
	{
		if (CatchableFish.Num() == 0)
		{
			PrintError(f"Fishing Hole {HoleName} has no catchable fish set!");
			return;
		}

		for (int i = 0; i < CatchableFish.Num(); i++)
		{
			if (CatchableFish[i].IsNull())
			{
#if EDITOR
				PrintError(f"Fishing Hole {HoleName} ({GetOwner().GetActorLabel()}) has null entries in its catchable fish list!");
#endif
				CatchableFish.RemoveAt(i);
				return;
			}
		}
	}

	UFUNCTION()
	void Enter(AActor OtherActor)
	{
		Character = Cast<AFishCharacter>(OtherActor);
		if (Character == nullptr)
			return;

		FishingComponent = UFishingComponent::Get(Character);
		if (FishingComponent == nullptr)
			return;

		NearbyPlayers.AddUnique(Character);
		OnHoleEntered.Broadcast(this);

		FishingComponent.UpdateCatchableFish(this);
		
		FishingComponent.OnSelectBait.AddUFunction(this, n"UpdateCatchableFish");
		FishingComponent.OnFishHooked.AddUFunction(this, n"TrySpectralShift");
	}

	UFUNCTION()
	void Exit(AActor OtherActor)
	{
		Character = Cast<AFishCharacter>(OtherActor);
		if (Character == nullptr)
			return;

		FishingComponent = UFishingComponent::Get(Character);
		if (FishingComponent == nullptr)
			return;

		if (IsSpectral)
		{
			// Remove spectral traits
		}

		NearbyPlayers.RemoveSingleSwap(Character);
		OnHoleExited.Broadcast(this);

		FishingComponent.UpdateCatchableFish(nullptr); // clears the catchable fish

		FishingComponent.OnSelectBait.Unbind(this, n"UpdateCatchableFish");
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCatchableFish(UBait _)
	{
		FishingComponent.UpdateCatchableFish(this);
	}

	UFUNCTION()
	private void TrySpectralShift(UFishItem FishItem, UBait Bait, UFishingHoleComponent FishingHole)
	{
		Server_TrySpectralShift(Bait);
	}


	UFUNCTION(Server)
	void Server_TrySpectralShift(UBait Bait, bool Override = false)
	{
		Multicast_TrySpectralShift(Bait, Override);
	}

	UFUNCTION(NetMulticast, Meta = (AdvancedDisplay = "bOverride", ReturnDisplayName = "Success"))
	bool Multicast_TrySpectralShift(UBait Bait, bool Override = false)
	{
		if (IsSpectral) // acts as a cooldown
			return false;

		if (!Override && !Bait.IsSpectral)
			return false;

		IsSpectral = Percent::RollPercentChance(Bait::GetSpectralChance(Bait));
		if (!IsSpectral && !Override)
			return false;

		Print("The fishing hole has spectral shifted!", 5.0f, FLinearColor::Purple);

		FishingComponent.UpdateCatchableFish(this);
		for (AFishCharacter PlayerChar : NearbyPlayers)
		{
			for (TSubclassOf<UTrait> TraitClass : SpectralTraits)
			{
				UTrait Trait = Cast<UTrait>(NewObject(this, TraitClass));
				Trait.Init(FishingComponent, PlayerChar.FishState.StatsComponent, PlayerChar.FishState.TokenComponent);
				Trait.ApplyTrait(PlayerChar, PlayerChar.FishState);
				AppliedTraits.Add(Trait);
			}
		}

		OnSpectralShift.Broadcast();
		BP_SpectralShift();

		return IsSpectral;
	}

	// entirely for avoiding GC of traits
	UPROPERTY(NotVisible, Transient, Replicated)
	TArray<UTrait> AppliedTraits;

	UFUNCTION(BlueprintEvent)
	void BP_SpectralShift()
	{}
}