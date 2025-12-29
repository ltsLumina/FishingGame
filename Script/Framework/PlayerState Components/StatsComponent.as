event void FOnRodEquipped(UFishingRod NewRod);
event void FOnRodUnequipped(UFishingRod OldRod);

class UStatsComponent : UFishComponentBase
{
	UPROPERTY(Category = "Rod", EditDefaultsOnly)
	URodData DefaultRodData;

	UPROPERTY(Category = "Rod", VisibleInstanceOnly)
	UFishingRod EquippedRod;

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

		// temporary: equip default rod with random traits
		EquipRod(GenerateRod(DefaultRodData));

		OnRodEquipped.AddUFunction(this, n"HandleRodEquipped");
		OnRodUnequipped.AddUFunction(this, n"HandleRodUnequipped");
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay()
	{}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodEquipped(UFishingRod NewRod)
	{
		ModifiedStats = Stats::ApplyStats(RodlessStats, NewRod.Data.BaseStats);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodUnequipped(UFishingRod OldRod)
	{
		ModifiedStats = RodlessStats;
	}

	UFishingRod GenerateRod(URodData RodData)
	{
		UFishingRod NewRod = NewObject(this, UFishingRod);
		NewRod.Data = RodData;
		NewRod.Traits = RollTraits(NewRod);
		return NewRod;
	}

	TArray<TSubclassOf<UTrait>> RollTraits(UFishingRod Rod)
	{
		auto Data = Rod.Data;
		auto Traits = Data.Traits;

		int TraitCount = 0;
        auto TraitCountProbabilities = Traits.TraitCountChances;

        float Total = 0.0f;
        for (float Value : TraitCountProbabilities)
            Total += Value;

        if (Total > 0.0f)
        {
            float RandomRoll = Math::RandRange(0.0f, Total);
            float CumulativeChance = 0.0f;
            for (int i = 0; i < TraitCountProbabilities.Num(); i++)
            {
                CumulativeChance += TraitCountProbabilities[i];
                if (RandomRoll <= CumulativeChance)
                {
                    TraitCount = i;
                    break;
                }
            }
        }		

		TArray<TSubclassOf<UTrait>> SelectedTraits;

		TArray<TSubclassOf<UTrait>> AvailableTraits = Traits.PossibleTraits;
        for (int i = 0; i < TraitCount; i++)
        {
            if (AvailableTraits.Num() == 0)
                break;

            int RandomIndex = Math::RandRange(0, AvailableTraits.Num() - 1);
            SelectedTraits.Add(AvailableTraits[RandomIndex]);
            AvailableTraits.RemoveAt(RandomIndex);
        }

		return SelectedTraits;
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
				Trait.ApplyTrait(Character, NewRod);
			}

			OnRodEquipped.Broadcast(EquippedRod);

			// debug print

			Print(f"Equipped rod: {EquippedRod.Data.Name} with {EquippedRod.Traits.Num()} traits.", 5.0f, FLinearColor::Green);
			TArray<FString> TraitNames;
			for (auto& TraitClass : EquippedRod.Traits)
			{
				auto Trait = TraitClass.GetDefaultObject();
				TraitNames.Add(Trait.TraitName.ToString());
			}
			Print("Traits: " + String::JoinStringArray(TraitNames, ", "), 5.0f, FLinearColor::Green);
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

	UFUNCTION(Category = "Data")
	bool SaveStats()
	{
		auto SaveGame = NewObject(this, UStatsSaveGame);
		SaveGame.SavedStats = ModifiedStats;
		SaveGame.SavedGil = Gil;
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

		return true;
	}
};

struct FStats
{
	UPROPERTY(Category = "Stats", SaveGame)
	int Gathering = 100;

	// higher chance of catching rare fish
	UPROPERTY(Category = "Stats", SaveGame)
	int Perception = 100;

	UPROPERTY(Category = "Stats")
	float CastSpeed = 1;

	UPROPERTY(Category = "Stats")
	float ReelSpeed = 1;

	// amount of fish caught per cast
	UPROPERTY(Category = "Stats")
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
	UFUNCTION(Category = "Stats", BlueprintPure, Meta = (AdvancedDisplay="bModified"))
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
		NewStats.CatchMultiplier += InRodStats.CatchMultiplier;
		return NewStats;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	int GetGathering(const FStats& Stats)
	{
		return Stats.Gathering;
	}

	UFUNCTION(Category = "Stats")
	int SetGathering(FStats& Stats, int Amount)
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
	int SetPerception(FStats& Stats, int Amount)
	{
		Stats.Perception = Amount;
		return Stats.Perception;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	float GetCastSpeed(const FStats& Stats)
	{
		return Stats.CastSpeed;
	}

	UFUNCTION(Category = "Stats")
	float SetCastSpeed(FStats& Stats, float Amount)
	{
		Stats.CastSpeed = Amount;
		return Stats.CastSpeed;
	}

	UFUNCTION(Category = "Stats", BlueprintPure)
	float GetReelSpeed(const FStats& Stats)
	{
		return Stats.ReelSpeed;
	}

	UFUNCTION(Category = "Stats")
	float SetReelSpeed(FStats& Stats, float Amount)
	{
		Stats.ReelSpeed = Amount;
		return Stats.ReelSpeed;
	}
}