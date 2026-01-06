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

	UPROPERTY(Category = "Stats", EditDefaultsOnly, Meta = (Categories = "Stat"))
	private TMap<FGameplayTag, float> Stats;

	UPROPERTY(Category = "Stats", VisibleAnywhere, Meta = (Categories = "Stat"))
	private TMap<FGameplayTag, float> AdditiveModifiers;

	UPROPERTY(Category = "Stats", VisibleAnywhere, Meta = (Categories = "Stat"))
	private TMap<FGameplayTag, float> MultiplicativeModifiers;

#if EDITOR
	UPROPERTY(Category = "Stats", VisibleAnywhere)
	TMap<FString, float> CurrentStats;
#endif

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		PlayerState.InventoryComponent.OnRodUnequipped.AddUFunction(this, n"RodUnequipped");
		PlayerState.InventoryComponent.OnRodEquipped.AddUFunction(this, n"RodEquipped");
	}

	UFUNCTION(NotBlueprintCallable)
	private void RodUnequipped(UFishingRod OldRod)
	{
		auto RodStats = OldRod.Data.Stats;
		for (auto& StatPair : RodStats)
		{
			//RemoveModifier(StatPair.Key);
		}
	}

	UFUNCTION()
	private void RodEquipped(UFishingRod NewRod)
	{
		auto RodStats = NewRod.Data.Stats;
		for (auto& StatPair : RodStats)
		{
			//AddModifier(StatPair.Key, StatPair.Value);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentStats = TMap<FString, float>();
		for (auto& StatPair : Stats)
		{
			float ModifiedValue = StatPair.Value;
			
			// Apply additive modifiers first
			if (AdditiveModifiers.Contains(StatPair.Key))
			{
				ModifiedValue += AdditiveModifiers[StatPair.Key];
			}
			
			// Then apply multiplicative modifiers
			if (MultiplicativeModifiers.Contains(StatPair.Key))
			{
				ModifiedValue *= MultiplicativeModifiers[StatPair.Key];
			}
			
			CurrentStats.Add(StatPair.Key.ToString(), ModifiedValue);
		}
	}
#endif

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

	UFUNCTION(Category = "Stats", BlueprintPure, Meta = (Categories = "Stat", ReturnDisplayName="Has Stat", AdvancedDisplay="BaseValue"))
	bool GetStat(FGameplayTag StatTag, bool BaseValue = false, float &OutValue = -1.0f)
	{
		if (HasStat(StatTag))
		{
			if (BaseValue)
			{
				OutValue = Stats[StatTag];
			}
			else if (!HasModifier(StatTag))
			{
				OutValue = Stats[StatTag];
			}
			else
			{
				float ModifiedValue = Stats[StatTag];
				
				// additive modifiers first
				if (AdditiveModifiers.Contains(StatTag))
				{
					ModifiedValue += AdditiveModifiers[StatTag];
				}
				
				// multiplicative modifiers
				if (MultiplicativeModifiers.Contains(StatTag))
				{
					ModifiedValue *= MultiplicativeModifiers[StatTag];
				}
				
				OutValue = ModifiedValue;
			}
			return true;
		}
		return false;
	}

	UFUNCTION(Category = "Stats", BlueprintPure, Meta = (Categories = "Stat"))
	bool HasStat(FGameplayTag StatTag)
	{
		return Stats.Contains(StatTag);
	}

	/**
	 * Adds to a stat using a gameplay tag identifier.
	 * @param Amount The amount to add to the stat (can be negative to subtract).
	 * @param Type The type of stat (flat or percentage).
	 * @param StackingType The stacking type (additive or multiplicative). Decides how multiple modifiers to the same stat are combined.
	 * @note For percentage-based stats, provide the amount as a whole number (e.g., 25 for 25%).
	 */
	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat"))
	void AddModifier(FGameplayTag Stat, float Amount, EStatType Type, EStackingType StackingType)
	{
		if (!Stat.IsValid()) PrintError(f"Invalid Stat GameplayTag provided!}");

		float FinalAmount = Amount;
		if (Type == EStatType::Percentage)
		{
			FinalAmount = 1.0f + (Percent::To(Amount)); // convert percentage to multiplier
		}

		if (StackingType == EStackingType::Additive)
		{
			if (AdditiveModifiers.Contains(Stat))
			{
				AdditiveModifiers[Stat] += FinalAmount;
			}
			else
			{
				AdditiveModifiers.Add(Stat, FinalAmount);
			}
		}
		else if (StackingType == EStackingType::Multiplicative)
		{
			if (MultiplicativeModifiers.Contains(Stat))
			{
				MultiplicativeModifiers[Stat] *= FinalAmount;
			}
			else
			{
				MultiplicativeModifiers.Add(Stat, FinalAmount);
			}
		}
	}

	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat"))
	void RemoveModifier(FGameplayTag Stat)
	{
		if (AdditiveModifiers.Contains(Stat))
		{
			AdditiveModifiers.Remove(Stat);
		}
		if (MultiplicativeModifiers.Contains(Stat))
		{
			MultiplicativeModifiers.Remove(Stat);
		}
	}

	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat"))
	void ClearStatModifiers()
	{
		AdditiveModifiers.Empty();
		MultiplicativeModifiers.Empty();
	}

	private TArray<FStatModification> ActiveModifications;
	private int NextModificationIndex = 0;

	/**
	 * Adds a stat modifier that lasts for a specified duration.
	 * @param Stat The gameplay tag identifying the stat.
	 * @param Amount The amount to modify the stat by.
	 * @param Duration The duration (in seconds) the modifier should last.
	 * @param Type The type of stat (flat or percentage).
	 * @param ModifierType The stacking type (additive or multiplicative).
	 * @param Identifier An optional identifier for the modifier to allow for targeted removal.
	 * @param NewValue Output parameter to receive the modified stat value after applying the modifier. Shorthand for GetStat after adding the modifier.
	 * @return A timer handle that can be used to track the duration of the modifier.
	 */
	UFUNCTION(Category = "Stats", Meta = (AdvancedDisplay = "Identifier", ReturnDisplayName = "Timer Handle"))
	FTimerHandle AddModifierForDuration(FGameplayTag Modifier, float Amount, float Duration, EStatType Type, EStackingType ModifierType = EStackingType::Additive, FName Identifier = NAME_None, float&out NewValue = -1.0f)
	{
		AddModifier(Modifier, Amount, Type, ModifierType);
		GetStat(Modifier, false, NewValue);

		FStatModification Modification;

		NextModificationIndex++;
		Modification.TimerHandle = System::SetTimer(this, n"UndoStatModification", Duration, false);

		Modification = FStatModification(Identifier, NextModificationIndex, EStat::Gathering, Modifier, true, Amount);
		ActiveModifications.Add(Modification);

		return Modification.TimerHandle;
	}

	/**
	 * Checks if a stat modifier exists for the given gameplay tag.
	 * @param Modifier The gameplay tag identifying the stat.
	 * @param Value Optional value to check against (default is -1.0f, which ignores the value).
	 * @return True if the stat modifier exists, false otherwise.
	 */
	UFUNCTION(Category = "Stats", BlueprintPure, Meta = (AdvancedDisplay = "Value"))
	bool HasModifier(FGameplayTag Modifier, float Value = -1)
	{
		if (AdditiveModifiers.Contains(Modifier))
		{
			if (Value < 0.0f)
				return true;
			return Math::IsNearlyEqual(AdditiveModifiers[Modifier], Value);
		}
		if (MultiplicativeModifiers.Contains(Modifier))
		{
			if (Value < 0.0f)
				return true;
			return Math::IsNearlyEqual(MultiplicativeModifiers[Modifier], Value);
		}
		return false;
	}

	UFUNCTION(NotBlueprintCallable)
	void UndoStatModification()
	{
		if (ActiveModifications.Num() == 0)
			return;

		FStatModification Mod = ActiveModifications[0]; // FIFO (first in, first out) - not the australian thing lol

		RemoveModifier(Mod.StatTag);

		ActiveModifications.RemoveAt(0);
	}

	/**
	 * Removes a stat modifier associated with the given timer handle.
	 * @param TimerHandle The timer handle associated with the stat modifier to remove.
	 * @return True if the modifier was found and removed, false otherwise.
	 */
	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat"))
	bool KillModifier(FName Identifier)
	{
		for (int i = 0; i < ActiveModifications.Num(); i++)
		{
			if (ActiveModifications[i].ID == Identifier)
			{
				System::ClearAndInvalidateTimerHandle(ActiveModifications[i].TimerHandle);
				RemoveModifier(ActiveModifications[i].StatTag);
				ActiveModifications.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (Categories = "Stat"))
	bool GetModifier(FGameplayTag StatTag, float&out Value)
	{
		if (AdditiveModifiers.Contains(StatTag))
		{
			Value = AdditiveModifiers[StatTag];
			return true;
		}
		if (MultiplicativeModifiers.Contains(StatTag))
		{
			Value = MultiplicativeModifiers[StatTag];
			return true;
		}

		Value = -1.0f;
		return false;
	}

	UFUNCTION(Category = "Data")
	bool SaveStats()
	{
		auto SaveGame = NewObject(this, UStatsSaveGame);
		SaveGame.SavedGil = Gil;
		SaveGame.SavedStats = Stats;
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

		Gil = LoadedSave.SavedGil;
		Stats = LoadedSave.SavedStats;
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
	int Gathering = 0;

	// higher chance of catching rare fish
	UPROPERTY(Category = "Stats")
	int Perception = 0;

	/**
	 * Multiplier for reel speed (e.g. 1.25 = +25% reel speed)
	 * Stacks additively.
	 */
	UPROPERTY(Category = "Stats", Transient, Meta = (Units = "x", UIMin = "0.25", UIMax = "5.0"))
	float ReelSpeed = 1;
}

struct FStatModification
{
	UPROPERTY()
	FName ID;

	UPROPERTY()
	int Index;

	UPROPERTY()
	EStat Stat;

	UPROPERTY(Meta = (Categories = "Stat"))
	FGameplayTag StatTag;

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

	FStatModification(FName InID = NAME_None, int InIndex = 0, EStat InStat = EStat::Gathering, FGameplayTag InStatTag = FGameplayTag(), bool InbIsAdditive = true, float InAmount = 0.0f)
	{
		this.ID = InID;
		this.Index = Index;
		this.Stat = Stat;
		this.StatTag = InStatTag;
		this.bIsAdditive = bIsAdditive;
		this.Amount = Amount;
	}
}

namespace Stats
{
	UFUNCTION(BlueprintPure, Meta = (Categories = "Stat", ReturnDisplayName="Has Stat", AdvancedDisplay="BaseValue"))
	bool GetStat(AFishCharacter Character, FGameplayTag StatTag, bool BaseValue = false, float&out Value = -1.0f)
	{
		return Character.FishState.StatsComponent.GetStat(StatTag, BaseValue, Value);
	}


	UFUNCTION(BlueprintPure, Meta = (Categories = "Stat"))
	bool GetStatModifier(AFishCharacter Character, FGameplayTag StatTag, float&out Value)
	{
		return Character.FishState.StatsComponent.GetModifier(StatTag, Value);
	}
}

enum EStatType
{
	/**
	 * A stat that represents a flat value, such as "Gathering" or "Perception".
	 */
	Flat,
	/**
	 * A stat that represents a percentage value, such as "Cast Speed" or "Reel Speed".
	 */
	Percentage
}

enum EStackingType
{
	/**
	 * **- Has Diminishing Returns**
	 * **- Additive stacking (e.g., +10 +20 = +30)**
	 * 
	 * **Assume base 1.**
	 * If you have 10 traits that give +10% additive damage, then the first trait will add 10% damage, increasing the base to 1.1. 
	 * The last item will increase base damage from 1.9 to 2.0. 
	 * This step is only going to increase your actual damage by ~5%.
	 * 
	 * A large flat addition may be better than a percentage increase, if the flat addition is big enough
	 */
	Additive,
	/**
	 * **- No Diminishing Returns**
	 * **- Multiplicative stacking (e.g., 1.1 x 1.2 = 1.32)**
	 * 
	 * **Assume base 1.**
	 * Multiplicative in turn has no dminishing returns, which results in (1.1)^10 = 2.6
	 * 10 instances of 10% multiplicative increases it by 160%.
	 * 
	 * It's best for you if percentage increases stack multiplicatively when you have multiple of them.
	 */
	Multiplicative
}