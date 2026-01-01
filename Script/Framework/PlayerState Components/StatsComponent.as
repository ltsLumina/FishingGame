event void FOnRodEquipped(UFishingRod NewRod);
event void FOnRodUnequipped(UFishingRod OldRod);

#if EDITOR
struct FDebugTraitInfo
{
	UPROPERTY()
	FString TraitName;

	UPROPERTY()
	FString Description;

	UPROPERTY()
	FString Effect;
}
#endif

enum EStat
{
	Gathering,
	Perception,
	/**
	 * Multiplier for cast speed (e.g. 1.25 = +25% cast speed)
	 * Stacks additively.
	 */
	CastSpeed,
	/**
	 * Multiplier for reel speed (e.g. 1.25 = +25% reel speed)
	 * Stacks additively.
	 */
	ReelSpeed,
	CatchMultiplier
}

class UStatsComponent : UFishComponentBase
{
	UPROPERTY(Category = "Rod", EditDefaultsOnly)
	URodData DefaultRodData;

	UPROPERTY(Category = "Rod", VisibleInstanceOnly)
	UFishingRod EquippedRod;

#if EDITOR
	UPROPERTY(Category = "Rod", VisibleInstanceOnly)
	TArray<FDebugTraitInfo> TraitInfos;
#endif

	UPROPERTY(Category = "Stats", SaveGame)
	FStats ModifiedStats; // Stats including rod modifiers

	UPROPERTY(Category = "Stats", SaveGame)
	FStats RodlessStats;  // Base stats without rod modifiers

	UPROPERTY(Category = "Stats", SaveGame)
	int Gil;

	UPROPERTY(Category = "Rod | Events")
	FOnRodEquipped OnRodEquipped;

	UPROPERTY(Category = "Rod | Events")
	FOnRodUnequipped OnRodUnequipped;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	void LatePlay() override
	{
		Super::LatePlay();
		BP_LatePlay();

		RodlessStats = FStats(); // initialize base stats

		if (EquippedRod == nullptr && !Gameplay::DoesSaveGameExist("PlayerStats", 0))
			EquipRod(FishingRod::GenerateRod(this, DefaultRodData));

		OnRodEquipped.AddUFunction(this, n"HandleRodEquipped");
		OnRodUnequipped.AddUFunction(this, n"HandleRodUnequipped");
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay()
	{}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodEquipped(UFishingRod NewRod)
	{
#if EDITOR
		TArray<FString> TraitNames;
		Print(f"Equipped rod: {EquippedRod.Data.Name} with {EquippedRod.Traits.Num()} traits.", 3.0f, FLinearColor::Green);
		for (auto& TraitClass : EquippedRod.Traits)
		{
			auto Trait = TraitClass.GetDefaultObject();

			FDebugTraitInfo Info;
			Info.TraitName = Trait.TraitName.ToString();
			Info.Description = Trait.Description.ToString();
			Info.Effect = Trait.Effect.ToString();

			TraitNames.Add(Info.TraitName);
			TraitInfos.Add(Info);
		}
		Print("Traits: " + String::JoinStringArray(TraitNames, ", "), 3.0f, FLinearColor::Green);
#endif
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodUnequipped(UFishingRod OldRod)
	{
		ModifiedStats = RodlessStats;

#if EDITOR
		TraitInfos.Empty();
#endif
	}

	void EquipRod(UFishingRod NewRod)
	{
		if (EquippedRod != nullptr)
		{
			OnRodUnequipped.Broadcast(EquippedRod);
			ModifiedStats = RodlessStats; // reset to base stats
		}

		EquippedRod = NewRod;

		if (EquippedRod != nullptr)
		{
			// apply rod stat modifiers
			for (auto& TraitClass : EquippedRod.Traits)
			{
				auto Trait = TraitClass.GetDefaultObject();
				Trait.ApplyTrait(Character, this, ModifiedStats, Character.FishingComponent, Character.FishingComponent.CurrentFishingHole, NewRod);
			}

			OnRodEquipped.Broadcast(EquippedRod);
		}
	}

	UFUNCTION(Category = "Gil")
	void GainGil(int Amount)
	{
		Gil += Math::Max(0, Amount);
	}

	UFUNCTION(Category = "Gil")
	bool SpendGil(int Amount)
	{
		if (Gil >= Amount)
		{
			Gil -= Amount;
			return true;
		}
		return false;
	}

	UFUNCTION(Category = "Stats")
	void AddStat(EStat Stat, float Amount)
	{
		switch (Stat)
		{
			case EStat::Gathering:
				ModifiedStats.Gathering += int(Amount);
				break;
			case EStat::Perception:
				ModifiedStats.Perception += int(Amount);
				break;
			case EStat::CastSpeed:
				AddPercentAdditive(ModifiedStats.CastSpeed, Amount);
				break;
			case EStat::ReelSpeed:
				AddPercentAdditive(ModifiedStats.ReelSpeed, Amount);
				break;
			case EStat::CatchMultiplier:
				ModifiedStats.CatchMultiplier += int(Amount);
				break;
		}
	}

	private FStats PreviousStats;

	UFUNCTION(Category = "Stats")
	FTimerHandle SetStatForDuration(EStat Stat, float Value, float Duration)
	{
		PreviousStats = ModifiedStats;

		switch (Stat)
		{
			case EStat::Gathering:
				Stats::SetGathering(ModifiedStats, int(Value));
				break;
			case EStat::Perception:
				Stats::SetPerception(ModifiedStats, int(Value));
				break;
			case EStat::CastSpeed:
				Stats::SetCastSpeed(ModifiedStats, Value);
				break;
			case EStat::ReelSpeed:
				Stats::SetReelSpeed(ModifiedStats, Value);
				break;
			case EStat::CatchMultiplier:
				Stats::SetCatchMultiplier(ModifiedStats, int(Value));
				break;
		}

		return System::SetTimer(this, n"UndoStatModifiers", Duration, false);
	}

	UFUNCTION(Category = "Stats")
	FTimerHandle AddStatForDuration(EStat Stat, float Amount, float Duration)
	{
		PreviousStats = ModifiedStats;
		
		AddStat(Stat, Amount);

		return System::SetTimer(this, n"UndoStatModifiers", Duration, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UndoStatModifiers()
	{
		// TODO: This will break in the future when stats change while the timer is active. E.g. switching rods.
		ModifiedStats = PreviousStats;

		EquipRod(EquippedRod); // re-apply rod traits to ensure correct stats, hopefully
	}

	UFUNCTION(Category = "Data")
	bool SaveStats()
	{
		auto SaveGame = NewObject(this, UStatsSaveGame);
		SaveGame.SavedStats = ModifiedStats;
		SaveGame.SavedGil = Gil;
		SaveGame.SavedRod = EquippedRod.Data;
		SaveGame.SavedRodTraits = EquippedRod.Traits;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerStats", 0);
	}

	UFUNCTION(Category = "Data")
	bool LoadStats()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerStats", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UStatsSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		ModifiedStats = LoadedSave.SavedStats;
		Gil = LoadedSave.SavedGil;

		auto LoadedRod = FishingRod::GenerateRod(this, LoadedSave.SavedRod);
		LoadedRod.Traits = LoadedSave.SavedRodTraits; // traits are saved separately to preserve randomization
		EquipRod(LoadedRod);

		// Print(f"Loaded rod ({LoadedSave.SavedRod.GetName()}) with " + LoadedSave.SavedRodTraits.Num() + " traits from save.", 2.0f, FLinearColor::Green);
		return true;
	}
};

struct FStats
{
	UPROPERTY(Category = "Stats")
	int Gathering = 100;

	// higher chance of catching rare fish
	UPROPERTY(Category = "Stats")
	int Perception = 100;

	/**
	 * Multiplier for cast speed (e.g. 1.25 = +25% cast speed)
	 * Stacks additively.
	 */
	UPROPERTY(Category = "Stats", Transient)
	float CastSpeed = 1;

	/**
	 * Multiplier for reel speed (e.g. 1.25 = +25% reel speed)
	 * Stacks additively.
	 */
	UPROPERTY(Category = "Stats", Transient)
	float ReelSpeed = 1;

	// amount of fish caught per cast
	UPROPERTY(Category = "Stats", Transient)
	int CatchMultiplier = 1;
}

namespace Stats
{
	const FName GATHERING = n"Gathering";
	const FName PERCEPTION = n"Perception";
	const FName CAST_SPEED = n"CastSpeed";
	const FName REEL_SPEED = n"ReelSpeed";
	const FName CATCH_MULTIPLIER = n"CatchMultiplier";

	/**
	 * Gets the player's stats, optionally modified by the equipped rod.
	 * @param Character The fish character whose stats to retrieve.
	 * @param bModified If true, returns stats modified by the equipped rod; if false, returns base stats without rod modifiers.
	 * @return The player's stats as an FStats struct.
	 */
	UFUNCTION(Category = "Stats", BlueprintPure, Meta = (AdvancedDisplay = "bModified"))
	FStats GetStats(AFishCharacter Character, bool bModified = true)
	{
		if (bModified)
		{
			return GetModifiedStats(Character);
		}
		else
		{
			return GetBaseStats(Character);
		}
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	FStats GetBaseStats(AFishCharacter Character)
	{
		return UStatsComponent::Get(Character.PlayerState).RodlessStats;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	FStats GetModifiedStats(AFishCharacter Character)
	{
		return UStatsComponent::Get(Character.PlayerState).ModifiedStats;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	FStats GetRodStats(UFishingRod Rod)
	{
		return Rod.Data.BaseStats;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	UStatsComponent GetStatsComponent(AFishCharacter Character)
	{
		return UStatsComponent::Get(Character.PlayerState);
	}

	/**
	 * Applies rod stats to player stats and returns the combined result.
	 * @note Does not modify the input stats, it simply returns a new FStats struct.
	 */
	UFUNCTION(Category = "Stats")
	FStats ApplyStats(FStats InPlayerStats, FStats InRodStats)
	{
		FStats NewStats = InPlayerStats;
		NewStats.Gathering += InRodStats.Gathering;
		NewStats.Perception += InRodStats.Perception;
		NewStats.ReelSpeed *= InRodStats.ReelSpeed;
		NewStats.CastSpeed *= InRodStats.CastSpeed;
		NewStats.CatchMultiplier *= InRodStats.CatchMultiplier;
		return NewStats;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	int GetGathering(const FStats& Stats)
	{
		return Stats.Gathering;
	}

	UFUNCTION(Category = "Stats")
	int SetGathering(FStats & Stats, int Amount)
	{
		Stats.Gathering = Amount;
		return Stats.Gathering;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	int GetPerception(const FStats& Stats)
	{
		return Stats.Perception;
	}

	UFUNCTION(Category = "Stats")
	int SetPerception(FStats & Stats, int Amount)
	{
		Stats.Perception = Amount;
		return Stats.Perception;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	float GetCastSpeed(const FStats& Stats)
	{
		return Stats.CastSpeed;
	}

	/**
	 * Sets the Cast Speed stat.
	 * Expects a decimal value (e.g. 1.25 for +25% Cast Speed).
	 */
	UFUNCTION(Category = "Stats")
	float SetCastSpeed(FStats & Stats, float Amount)
	{
		Stats.CastSpeed = Amount;
		return Stats.CastSpeed;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	float GetReelSpeed(const FStats& Stats)
	{
		return Stats.ReelSpeed;
	}

	/**
	 * Sets the Reel Speed stat.
	 * Expects a decimal value (e.g. 1.25 for +25% Reel Speed).
	 */
	UFUNCTION(Category = "Stats")
	float SetReelSpeed(FStats & Stats, float Amount)
	{
		Stats.ReelSpeed = Amount;
		return Stats.ReelSpeed;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	int GetCatchMultiplier(const FStats& Stats)
	{
		return Stats.CatchMultiplier;
	}

	UFUNCTION(Category = "Stats")
	int SetCatchMultiplier(FStats & Stats, int Amount)
	{
		Stats.CatchMultiplier = Amount;
		return Stats.CatchMultiplier;
	}
}