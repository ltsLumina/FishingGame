namespace FishingRod
{
	UFishingRod GenerateRod(UObject Outer, URodData RodData)
	{
		UFishingRod NewRod = NewObject(Outer, UFishingRod);
		NewRod.Data = RodData;
		NewRod.Traits = RodData.Traits.IsCurated ? RodData.Traits.CuratedTraits : RollTraits(NewRod);
		return NewRod;
	}

	TArray<TSubclassOf<UTrait>> RollTraits(UFishingRod Rod)
	{
		auto Data = Rod.Data;
		auto Traits = Data.Traits;

		int TraitCount = 0;
		auto TraitCountProbabilities = Traits.TraitCountChances;

		// --- Trait count selection (unchanged) ---
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

			// --- Weighted random selection by rarity weight ---
			TArray<float> Weights;
			float WeightSum = 0.0f;
			for (auto& TraitClass : AvailableTraits)
			{
				auto TraitCDO = TraitClass.GetDefaultObject();
				float RarityWeight = Fish::GetRarityWeight(TraitCDO.Rarity);
				Weights.Add(RarityWeight);
				WeightSum += RarityWeight;
			}

			float Roll = Math::RandRange(0.0f, WeightSum);
			float Cumulative = 0.0f;
			int SelectedIndex = 0;
			for (int j = 0; j < Weights.Num(); j++)
			{
				Cumulative += Weights[j];
				if (Roll <= Cumulative)
				{
					SelectedIndex = j;
					break;
				}
			}

			SelectedTraits.Add(AvailableTraits[SelectedIndex]);
			AvailableTraits.RemoveAt(SelectedIndex);
		}

		return SelectedTraits;
	}
}

class URodData : UPrimaryDataAsset
{
	UPROPERTY(Category = "Rod")
	FRodDetails Details;

	UPROPERTY(Category = "Rod")
	FStats BaseStats;

	UPROPERTY(Category = "Rod")
	FRodTraits Traits;
};

struct FRodDetails
{
	UPROPERTY(DisplayName = "Name")
	FText RodName;

	UPROPERTY(Meta = (MultiLine))
	FText Lore;

	UPROPERTY()
	UTexture2D Icon;
};

struct FRodTraits
{
	UPROPERTY(Category = "Traits")
	bool IsCurated;

	UPROPERTY(Category = "Traits", Meta = (EditCondition = "IsCurated", EditConditionHides))
	TArray<TSubclassOf<UTrait>> CuratedTraits;

	/**
	 * Chance to get a certain number of traits on this rod.
	 * Key: Index of trait count (0 to 4)
	 * Value: Weight for random selection (0-100, percentage chance)
	 */
	UPROPERTY(Category = "Traits", Meta = (EditCondition = "!IsCurated", EditConditionHides))
	TArray<float> TraitCountChances;

	/**
	 * The possible traits this rod can have when generated.
	 * Key: Trait class
	 * Value: Weight for random selection (0-100, percentage chance)
	 * @see UFishingRod
	 */
	UPROPERTY(Category = "Traits", Meta = (EditCondition = "!IsCurated", EditConditionHides))
	TArray<TSubclassOf<UTrait>> PossibleTraits;
};

/**
 * Fishing rod item instance, like a Destiny weapon instance.
 * @see URodData for base data.
 */
class UFishingRod : UObject
{
	/**
	 * The base data for this rod.
	 */
	UPROPERTY(SaveGame)
	URodData Data;

	/**
	 * The traits this rod has been generated with.
	 */
	UPROPERTY(SaveGame)
	TArray<TSubclassOf<UTrait>> Traits;
}

UCLASS(Abstract)
class UTrait : UPrimaryDataAsset
{
	UPROPERTY(DisplayName = "Name")
	FText TraitName;

	UPROPERTY(Meta = (MultiLine))
	FText Description;

	UPROPERTY(Meta = (MultiLine))
	FText Effect;

	UPROPERTY()
	EFishRarity Rarity;

	UPROPERTY()
	bool IsEnhanced;

	/**
	 * Apply the effect of this trait to the given character.
	 */
	UFUNCTION(BlueprintEvent, Meta=(AdvancedDisplay="3"))
	void ApplyTrait(AFishCharacter Character, UStatsComponent Stats, FStats ModifiedStats, UFishingComponent FishingComponent, UFishingHoleComponent FishingHole, UFishingRod Rod)
	{}

	UFUNCTION()
	void AdjustStat(FStats& PlayerStats, EStat Stat, float Amount)
	{
		switch (Stat)
		{
			case EStat::Gathering:
				PlayerStats.Gathering += int(Amount);
				break;
			case EStat::Perception:
				PlayerStats.Perception += int(Amount);
				break;
			case EStat::CastSpeed:
				AddPercentMultiplicative(PlayerStats.CastSpeed, Amount);
				break;
			case EStat::ReelSpeed:
				AddPercentMultiplicative(PlayerStats.ReelSpeed, Amount);
				break;
			case EStat::CatchMultiplier:
				PlayerStats.CatchMultiplier += int(Amount);
				break;
		}
	}

	/**
	 * Add to a stat for the given character.
	 * @param Amount The amount to add to the stat (can be negative to subtract).
	 * @note For percentage-based stats, provide the amount as a whole number (e.g., 25 for 25%).
	 */
	UFUNCTION()
	void AddStat(UStatsComponent Stats, EStat Stat, float Amount)
	{
		Stats.AddStat(Stat, Amount);
	}

	/**
	 * Add multiple stats to the given character.
	 * @param StatAmounts A map of stats and their corresponding amounts to add.
	 * @note For percentage-based stats, provide the amounts as whole numbers (e.g., 25 for 25%).
	 */
	UFUNCTION()
	void AddStats(UStatsComponent Stats, TMap<EStat, float> StatAmounts)
	{
		for (auto& Pair : StatAmounts)
		{
			Stats.AddStat(Pair.Key, Pair.Value);
		}
	}

	/**
	 * Add to a stat for the given character for a duration.
	 * @param Amount The amount to add to the stat (can be negative to subtract).
	 * @param Duration The duration in seconds to apply the stat boost.
	 * @note For percentage-based stats, provide the amount as a whole number (e.g., 25 for 25%).
	 */
	UFUNCTION()
	void AddStatForDuration(UStatsComponent Stats, EStat Stat, float Amount, float Duration)
	{
		Stats.AddStatForDuration(Stat, Amount, Duration);
	}
}

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