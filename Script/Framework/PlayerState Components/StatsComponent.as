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
	UPROPERTY(Category = "Stats", SaveGame)
	int Gil;
	
	UPROPERTY(Category = "Stats", SaveGame)
	FStats ModifiedStats; // Stats including rod modifiers

	UPROPERTY(Category = "Stats", SaveGame)
	FStats RodlessStats;  // Base stats without rod modifiers


	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		RodlessStats = FStats(); // initialize base stats

		PlayerState.InventoryComponent.OnRodUnequipped.AddUFunction(this, n"RodUnequipped");
	}

	UFUNCTION(NotBlueprintCallable)
	private void RodUnequipped(UFishingRod OldRod)
	{
		ModifiedStats = RodlessStats;
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

	private TArray<FStatModification> ActiveModifications;
	private int NextModificationIndex = 0;

	UFUNCTION(Category = "Stats")
	FTimerHandle SetStatForDuration(EStat Stat, float Value, float Duration)
	{
		// Store the current value so we can revert to it
		float PreviousValue;
		switch (Stat)
		{
			case EStat::Gathering:
				PreviousValue = ModifiedStats.Gathering;
				Stats::SetGathering(ModifiedStats, int(Value));
				break;
			case EStat::Perception:
				PreviousValue = ModifiedStats.Perception;
				Stats::SetPerception(ModifiedStats, int(Value));
				break;
			case EStat::CastSpeed:
				PreviousValue = ModifiedStats.CastSpeed;
				Stats::SetCastSpeed(ModifiedStats, Value);
				break;
			case EStat::ReelSpeed:
				PreviousValue = ModifiedStats.ReelSpeed;
				Stats::SetReelSpeed(ModifiedStats, Value);
				break;
			case EStat::CatchMultiplier:
				PreviousValue = ModifiedStats.CatchMultiplier;
				Stats::SetCatchMultiplier(ModifiedStats, int(Value));
				break;
		}

		// Track this modification
		FStatModification Modification;
		NextModificationIndex++;
		Modification.Index = NextModificationIndex;
		Modification.Stat = Stat;
		Modification.bIsAdditive = false;
		Modification.PreviousValue = PreviousValue;
		Modification.TimerHandle = System::SetTimer(this, n"UndoStatModification", Duration, false);
		ActiveModifications.Add(Modification);

		return Modification.TimerHandle;
	}

	/**
	 * Adds to a stat for a limited duration, then reverts the change.
	 * @ID Optional ID to identify this modification for later removal.
	 */
	UFUNCTION(Category = "Stats", Meta = (AdvancedDisplay = "ID"))
	FTimerHandle AddStatForDuration(EStat Stat, float Amount, float Duration, FName ID = NAME_None)
	{
		AddStat(Stat, Amount);

		FStatModification Modification;

		NextModificationIndex++;
		Modification.TimerHandle = System::SetTimer(this, n"UndoStatModification", Duration, false);
		
		Modification = FStatModification(ID, NextModificationIndex, Stat, true, Amount);
		ActiveModifications.Add(Modification);

		return Modification.TimerHandle;
	}

	UFUNCTION(Category = "Stats")
	void ClearStatModification(FName ModificationID)
	{
		if (ModificationID == NAME_None)
			PrintWarning("ClearStatModification called with invalid ModificationID.", 5.0f);
		
		for (int i = 0; i < ActiveModifications.Num(); i++)
		{
			if (ActiveModifications[i].ID == ModificationID)
			{
				System::ClearAndInvalidateTimerHandle(ActiveModifications[i].TimerHandle);
				ActiveModifications.RemoveAt(i);
				return;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UndoStatModification()
	{
		if (ActiveModifications.Num() == 0)
			return;

		FStatModification Mod = ActiveModifications[0]; // FIFO (first in, first out) - not the australian thing lol

		if (Mod.bIsAdditive)
		{
			// Reverse the additive modification
			AddStat(Mod.Stat, -Mod.Amount);
		}
		else
		{
			// Restore the previous value
			switch (Mod.Stat)
			{
				case EStat::Gathering:
					Stats::SetGathering(ModifiedStats, int(Mod.PreviousValue));
					break;
				case EStat::Perception:
					Stats::SetPerception(ModifiedStats, int(Mod.PreviousValue));
					break;
				case EStat::CastSpeed:
					Stats::SetCastSpeed(ModifiedStats, Mod.PreviousValue);
					break;
				case EStat::ReelSpeed:
					Stats::SetReelSpeed(ModifiedStats, Mod.PreviousValue);
					break;
				case EStat::CatchMultiplier:
					Stats::SetCatchMultiplier(ModifiedStats, int(Mod.PreviousValue));
					break;
			}
		}

		ActiveModifications.RemoveAt(0);
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
	ELoadResult LoadStats()
	{
		// Gameplay::DeleteGameInSlot("PlayerStats", 0); // TEMPORARY TO TEST ROD EQUIPPING

		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerStats", 0);
		if (SaveGame == nullptr)
			return ELoadResult::SuccessNoData;

		auto LoadedSave = Cast<UStatsSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		ModifiedStats = LoadedSave.SavedStats;
		Gil = LoadedSave.SavedGil;
		return ELoadResult::Success;
	}
};

UFUNCTION(Category = "Stats", BlueprintPure)
int GetGil()
{
	return GetFishCharacterBase().FishState.StatsComponent.Gil;
}

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
	UPROPERTY(Category = "Stats", Transient, Meta=(Units="x", Delta="0.25", UIMin="0.1", UIMax="5.0"))
	float CastSpeed = 1;

	/**
	 * Multiplier for reel speed (e.g. 1.25 = +25% reel speed)
	 * Stacks additively.
	 */
	UPROPERTY(Category = "Stats", Transient, Meta=(Units="x", UIMin="0.25", UIMax="5.0"))
	float ReelSpeed = 1;

	// amount of fish caught per cast
	UPROPERTY(Category = "Stats", Transient, Meta=(Units="x", UIMin="1", UIMax="10"))
	int CatchMultiplier = 1;
}

struct FStatModification
{
	UPROPERTY()
	FName ID;

	UPROPERTY()
	int Index;

	UPROPERTY()
	EStat Stat;

	UPROPERTY()
	bool bIsAdditive;

	UPROPERTY()
	float Amount;		 // Used for additive modifications

	UPROPERTY()
	float PreviousValue; // Used for set modifications

	/**
	 * Handle to the timer that will call UndoStatModification when the duration expires.
	 */
	UPROPERTY()
	FTimerHandle TimerHandle;

	FStatModification(FName InID = NAME_None, int InIndex = 0, EStat InStat = EStat::Gathering, bool InbIsAdditive = true, float InAmount = 0.0f)
	{
		this.ID = InID;
		this.Index = Index;
		this.Stat = Stat;
		this.bIsAdditive = bIsAdditive;
		this.Amount = Amount;
	}
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
	int GetGathering(FStats & Stats)
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
	int GetPerception(FStats & Stats)
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
	float GetCastSpeed(FStats & Stats)
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
	float GetReelSpeed(FStats & Stats)
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
	int GetCatchMultiplier(FStats & Stats)
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