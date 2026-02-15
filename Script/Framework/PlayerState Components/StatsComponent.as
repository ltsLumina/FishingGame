event void FOnModifierAdded(FStatModification Modification);
event void FOnModifierExpired(FStatModification ExpiredModification);

UCLASS(Abstract)
class UStatsComponent : UFishComponentBase
{
	UPROPERTY(Category = "Stats", EditDefaultsOnly, Meta = (Categories = "Stat", Units = "%", UIMin = 0, UIMax = 100, Delta = 0.5))
	TMap<FGameplayTag, float> Stats;
	default Stats.Add(GameplayTags::Stat_Fishing_ReelSpeed, 100.0f);   // Increases the reel-in animation's play rate. (Higher = Faster reeling)
	default Stats.Add(GameplayTags::Stat_Fishing_BiteRate, 100.0f);	   // Decreases the time for a fish to bite. (Higher = Quicker bites)
	default Stats.Add(GameplayTags::Stat_Fishing_CatchChance, 100.0f); // Increases the chance to sucessfully catch a fish. (Higher = Better odds)
	default Stats.Add(GameplayTags::Stat_Fishing_Luck, 0.0f);		   // Increases the chance for a fish to have a tag. (Higher = better rewards)

	UPROPERTY(Category = "Stats", VisibleInstanceOnly, Meta = (Categories = "Stat"))
	private TMap<FGameplayTag, float> AdditiveModifiers;

	UPROPERTY(Category = "Stats", VisibleInstanceOnly, Meta = (Categories = "Stat"))
	private TMap<FGameplayTag, float> MultiplicativeModifiers;

#if EDITOR
	UPROPERTY(Category = "Stats", VisibleInstanceOnly, Meta = (Units = "%", UIMin = 0, UIMax = 200))
	TMap<FString, float> CurrentStats;
#endif

	UPROPERTY(Category = "Stats", Meta = (TitleProperty = "{StatTag} ({RemainingTimeString})"))
	private TArray<FStatModification> ActiveModifications;

	UPROPERTY(Category = "Events")
	FOnModifierAdded OnModifierAdded;

	UPROPERTY(Category = "Events")
	FOnModifierExpired OnModifierExpired;

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
		auto RodStats = OldRod.Data.BaseStats;
		for (auto& StatPair : RodStats)
		{
			RemoveModifier(StatPair.Key);
		}
	}

	UFUNCTION()
	private void RodEquipped(UFishingRod NewRod)
	{
		auto RodStats = NewRod.Data.BaseStats;
		for (auto& StatPair : RodStats)
		{
			AddModifier(StatPair.Key, StatPair.Value, EStatType::Flat, EStackingType::Additive);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		// 'CurrentStats' is an outliner-only thing to easily read the player's current stats.
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
#endif

		// Handles removing expired modifiers.
		for (int i = ActiveModifications.Num() - 1; i >= 0; i--)
		{
			FStatModification Entry = ActiveModifications[i];

			if (Entry.RemainingTime > 0.0f)
			{
				Entry.RemainingTime -= DeltaSeconds;
				if (Entry.RemainingTime < 0.0f)
				{
					Entry.RemainingTime = 0.0f;
				}
			}

			float TotalTime = Entry.Duration;
#if EDITOR
			Entry.RemainingTimeString = Entry.RemainingTime > 0.0f ? f"{Entry.RemainingTime:.1f}s/{TotalTime:.1f}s" : "Expired";
#endif
			ActiveModifications[i] = Entry;

			if (Entry.RemainingTime <= 0.0f)
			{
				FStatModification ExpiredEntry = FStatModification(Entry.StatTag, Entry.Amount, Entry.Duration, Entry.StatType, Entry.StackingType, Entry.ID);
				AddModifier(Entry.StatTag, -Entry.Amount, Entry.StatType, Entry.StackingType);
				ActiveModifications.RemoveAt(i);
				OnModifierExpired.Broadcast(ExpiredEntry);
			}
		}
	}

	UFUNCTION(Category = "Stats", BlueprintPure, Meta = (Categories = "Stat", ReturnDisplayName = "Has Stat", AdvancedDisplay = "BaseValue"))
	bool GetStat(FGameplayTag StatTag, bool BaseValue = false, float& OutValue = -1.0f)
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

	TMap<FGameplayTag, FName> TrackedModifiers;

	/**
	 * Adds to a stat using a gameplay tag identifier.
	 * @param Amount The amount to add to the stat (can be negative to subtract).
	 * @param StatType The type of stat (flat or percentage).
	 * @param StackingType The stacking type (additive or multiplicative). Decides how multiple modifiers to the same stat are combined.
	 * @note For percentage-based stats, provide the amount as a whole number (e.g., 25 for 25%).
	 */
	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat", AdvancedDisplay = "Identifier"))
	void AddModifier(FGameplayTag Stat, float Amount, EStatType StatType, EStackingType StackingType, FName Identifier = NAME_None)
	{
		if (!Stat.IsValid())
			PrintError(f"Invalid Stat GameplayTag provided!}");

		float FinalAmount = Amount;
		if (StatType == EStatType::Percentage)
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

		if (Identifier != NAME_None)
		{
			TrackedModifiers.Add(Stat, Identifier);
		}
	}

	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat", DeprecatedFunction, DeprecationMessage = "THIS FUNCTION SHOULD NOT BE USED. NEEDS TO BE REFACTORED TO SUBTRACT THE STAT, NOT REMOVE IT COMPLETELY."))
	void RemoveModifier(FGameplayTag Stat)
	{
		throw("THIS FUNCTION SHOULD NOT BE USED. NEEDS TO BE REFACTORED TO SUBTRACT THE STAT, NOT REMOVE IT COMPLETELY.");

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

	/**
	 * Adds a stat modifier that lasts for a specified duration.
	 * @param Stat The gameplay tag identifying the stat.
	 * @param Amount The amount to modify the stat by.
	 * @param Duration The duration (in seconds) the modifier should last.
	 * @param StatType The type of stat (flat or percentage).
	 * @param StackingType The stacking type (additive or multiplicative).
	 * @param Identifier An optional identifier for the modifier to allow for targeted removal.
	 * @param NewValue Output parameter to receive the modified stat value after applying the modifier. Shorthand for GetStat after adding the modifier.
	 * @return A timer handle that can be used to track the duration of the modifier.
	 */
	UFUNCTION(Category = "Stats", Meta = (AdvancedDisplay = "Identifier", ReturnDisplayName = "Timer Handle", Categories = "Stat"))
	void AddModifierForDuration(FGameplayTag Modifier, float Amount, float Duration, EStatType StatType, EStackingType StackingType = EStackingType::Additive, FName Identifier = NAME_None, float&out NewValue = -1.0f)
	{
		AddModifier(Modifier, Amount, StatType, StackingType);
		GetStat(Modifier, false, NewValue);

		FStatModification Modification = FStatModification(Modifier, Amount, Duration, StatType, StackingType, Identifier);
		Modification.Duration = Duration;
		Modification.RemainingTime = Duration;
		Modification.RemainingTimeString = Duration > 0.0f ? f"{Duration:.1f}s/{Duration:.1f}s" : "Expired";
		ActiveModifications.Add(Modification);
		OnModifierAdded.Broadcast(Modification);
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

		FStatModification Mod = ActiveModifications[0];						   // FIFO (first in, first out) - not the australian thing lol

		AddModifier(Mod.StatTag, -Mod.Amount, Mod.StatType, Mod.StackingType); // subtract the stat instead of removing it

		ActiveModifications.RemoveAt(0);
	}

	/**
	 * Removes a stat modifier associated with the given timer handle.
	 * @param Identifier The identifier of the modifier to remove.
	 * @return True if the modifier was found and removed, false otherwise.
	 */
	UFUNCTION(Category = "Stats", Meta = (Categories = "Stat"))
	bool KillModifier(FName Identifier)
	{
		for (int i = 0; i < ActiveModifications.Num(); i++)
		{
			if (ActiveModifications[i].ID == Identifier)
			{
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
		auto SaveGame = Gameplay::CreateSaveGameObject(UStatsSaveGame);
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

		Stats = LoadedSave.SavedStats;
		return ELoadResult::Success;
	}
};

struct FStatModification
{
	UPROPERTY(Meta = (Categories = "Stat"), BlueprintReadOnly, VisibleInstanceOnly)
	FGameplayTag StatTag;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	float Amount;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	EStatType StatType;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	EStackingType StackingType;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly, Meta = (Units = "s"))
	float Duration;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly, Meta = (Units = "s"))
	float RemainingTime;

	UPROPERTY(BlueprintHidden, VisibleInstanceOnly)
	FString RemainingTimeString;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	FName ID;

	FStatModification(FGameplayTag InStatTag, float InAmount, float InDuration, EStatType InStatType, EStackingType InStackingType, FName InID = NAME_None)
	{
		this.StatTag = InStatTag;
		this.Amount = InAmount;
		this.Duration = InDuration;
		this.StatType = InStatType;
		this.StackingType = InStackingType;
		this.ID = InID;
	}
}

namespace Stats
{
	/**
	 * @param Character The character of whom to get the stats of.
	 * @param StatTag The gameplay tag for which stat to get.
	 * @param AsDecimal If true, the value is returned as a decimal rather than the whole number it is stored as.
	 * @param BaseValue If true, returns the base value of the stat, ignoring all current modifications. Else returns the currently modified value of the stat.
	 * @param Value The returned value.
	 * @return True if the player has this stat, else false.
	 */
	UFUNCTION(BlueprintPure, Meta = (Categories = "Stat", ReturnDisplayName = "Has Stat", AdvancedDisplay = "BaseValue,AsDecimal"))
	bool GetStat(AFishCharacter Character, FGameplayTag StatTag, bool AsDecimal = false, bool BaseValue = false, float&out Value = -1.0f)
	{
		bool HasStat = Character.FishState.StatsComponent.GetStat(StatTag, BaseValue, Value);

		float Whole = Value;
		float Decimal = Percent::To(Value);
		Value = AsDecimal ? Decimal : Whole;

		return HasStat;
	}

	/**
	 *
	 */
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