namespace FishingRod
{
	const float TIER1_ENHANCE_CHANCE = 0.0f;
	const float TIER2_ENHANCE_CHANCE = 5.0f;
	const float TIER3_ENHANCE_CHANCE = 7.5f;
	const float TIER4_ENHANCE_CHANCE = 10.0f;
	const float TIER5_ENHANCE_CHANCE = 20.0f;

	float GetEnhanceChance(ERodTier Tier)
	{
		switch (Tier)
		{
			case ERodTier::Tier1:
				return TIER1_ENHANCE_CHANCE;
			case ERodTier::Tier2:
				return TIER2_ENHANCE_CHANCE;
			case ERodTier::Tier3:
				return TIER3_ENHANCE_CHANCE;
			case ERodTier::Tier4:
				return TIER4_ENHANCE_CHANCE;
			case ERodTier::Tier5:
				return TIER5_ENHANCE_CHANCE;
			default:
				return 0.0f;
		}
	}

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

			SelectedTraits.Add(AvailableTraits[SelectedIndex]);
			AvailableTraits.RemoveAt(SelectedIndex);
		}

		return SelectedTraits;
	}

	UFUNCTION(BlueprintPure)
	FString GetStatsString(URodData RodData)
	{
		TArray<FGameplayTag> StatNames;
		TArray<float> StatValues;
		RodData.BaseStats.GetKeys(StatNames);
		for (int i = 0; i < RodData.BaseStats.Num(); i++)
		{
			auto Value = RodData.BaseStats[StatNames[i]];
			StatValues.Add(Value);
		}

		FString String;
		for (int i = 0; i < RodData.BaseStats.Num(); i++)
		{
			FString FirstHalf;
			FString LastTagName;
			StatNames[i].TagName.ToString().Split(".", FirstHalf, LastTagName, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
			FString SignString = Math::Sign(StatValues[i]) < 0.0f ? "-" : "+";
			String = String::Concat_StrStr(String, f"{SignString}{Math::Abs(StatValues[i])} {LastTagName.ToDisplayName()}" + "\n");
		}

		String.RemoveFromEnd("\n");

		return String;
	}

	UFUNCTION(BlueprintPure)
	mixin FText GetName(URodData RodData)
	{
		return RodData.Details.RodName;
	}

	UFUNCTION(BlueprintPure)
	mixin FText GetLore(URodData RodData)
	{
		return RodData.Details.Lore;
	}
	
	UFUNCTION(BlueprintPure)
	mixin UTexture2D GetIcon(URodData RodData)
	{
		return RodData.Details.Icon;
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

	/**
	 * The base stats this rod provides when equipped.
	 * Stats are applied when the rod is equipped.
	 * These stats are always applied as a flat, additive stat.
	 */
	UPROPERTY(Category = "Rod", Meta = (Categories = "Stat", ForceInlineRow, EditFixedSize))
	TMap<FGameplayTag, float> BaseStats;
	default BaseStats.Add(GameplayTags::Stat_Fishing_Gathering, 0.0f);
	default BaseStats.Add(GameplayTags::Stat_Fishing_Perception, 0.0f);
	default BaseStats.Add(GameplayTags::Stat_Fishing_ReelSpeed, 0.0f);

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

	UFUNCTION(BlueprintPure)
	FString GetTraitsString()
	{
		FString String;
		for (int i = 0; i < Traits.Num(); i++)
		{
			auto TraitClass = Traits[i];
			auto TraitCDO = TraitClass.GetDefaultObject();
			String = String::Concat_StrStr(String, TraitCDO.TraitName.ToString() + "\n");
		}
		return String;
	}
}