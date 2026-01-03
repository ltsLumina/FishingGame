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
				if (RandomRoll < CumulativeChance)
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

			switch (Rod.Data.Tier)	  // does nothing yet
			{
				case ERodTier::Tier1: // ★
				case ERodTier::Tier2: // ★★
				case ERodTier::Tier3: // ★★★
				case ERodTier::Tier4: // ★★★★
				case ERodTier::Tier5: // ★★★★★
				default:
				{
					// nothing for now.
					break;
				}
			}

			SelectedTraits.Add(AvailableTraits[SelectedIndex]);
			AvailableTraits.RemoveAt(SelectedIndex);
		}

		return SelectedTraits;
	}
}

enum ERodTier
{
	UMETA(DisplayName = "★")
	Tier1,
	UMETA(DisplayName = "★★")
	Tier2,
	UMETA(DisplayName = "★★★")
	Tier3,
	UMETA(DisplayName = "★★★★")
	Tier4,
	UMETA(DisplayName = "★★★★★")
	Tier5
};

class URodData : UPrimaryDataAsset
{
	UPROPERTY(Category = "Rod")
	FRodDetails Details;

	UPROPERTY(Category = "Rod")
	ERodTier Tier;

	UPROPERTY(Category = "Rod")
	FStats BaseStats;

	UPROPERTY(Category = "Rod")
	FRodTraits Traits;

	default Traits.TraitCountChances.Add(20); // 0 traits
	default Traits.TraitCountChances.Add(25); // 1 trait
	default Traits.TraitCountChances.Add(30); // 2 traits
	default Traits.TraitCountChances.Add(20); // 3 traits
	default Traits.TraitCountChances.Add(5);  // 4 traits
};

struct FRodDetails
{
	UPROPERTY(DisplayName = "Name")
	FText RodName = FText::FromString("Fishing Rod");

	UPROPERTY(Meta = (MultiLine))
	FText Lore = FText::FromString("A basic fishing rod.");

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
	 * Index: Trait count (0 to 4)
	 * Value: Weight for random selection (0-100, percentage chance)
	 */
	UPROPERTY(Category = "Traits", Meta = (EditCondition = "!IsCurated", EditConditionHides, Units = "%", UIMin = 0, UIMax = 100), EditFixedSize)
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