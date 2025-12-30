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

	UPROPERTY(Category = "Traits", Meta=(EditCondition="IsCurated", EditConditionHides))
	TArray<TSubclassOf<UTrait>> CuratedTraits;

	/**
	 * Chance to get a certain number of traits on this rod.
	 * Key: Index of trait count (0 to 4)
	 * Value: Weight for random selection (0-100, percentage chance)
	 */
	UPROPERTY(Category = "Traits", Meta=(EditCondition="!IsCurated", EditConditionHides))
	TArray<float> TraitCountChances;

	/**
	 * The possible traits this rod can have when generated.
	 * Key: Trait class
	 * Value: Weight for random selection (0-100, percentage chance)
	 * @see UFishingRod
	 */
	UPROPERTY(Category = "Traits", Meta=(EditCondition="!IsCurated", EditConditionHides))
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
	UPROPERTY()
	URodData Data;

	/**
	 * The traits this rod has been generated with.
	 */
	UPROPERTY()
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
	 * Apply the effect of this trait to the given character and rod.
	 * @param Character The character using the rod.
	 * @param Rod The fishing rod this trait is applied to.
	 * @param PlayerStats The player's stats to potentially modify further, as they are already modified by the rod's base stats by this point.
	 */
	UFUNCTION(BlueprintEvent)
	void ApplyTrait(AFishCharacter Character, UFishingRod Rod)
	{
		// Implemented in blueprint subclass
	}

	UFUNCTION(BlueprintPure)
	UStatsComponent GetPlayerStats(AFishCharacter Character)
	{
		return Stats::GetStatsComponent(Character);
	}
	
	/**
	 * Auto converts from whole number to decimal for percentage-based stats.
	 * @param Amount The amount to adjust by, e.g. 5 for +5% Cast Speed.
	 */
	UFUNCTION()
	void AdjustStat(FStats& PlayerStats, FName StatName, float Amount)
	{
		if (StatName == "Gathering")
		{
			PlayerStats.Gathering += int(Amount);
		}
		else if (StatName == "Perception")
		{
			PlayerStats.Perception += int(Amount);
		}
		else if (StatName == "CastSpeed")
		{
			PlayerStats.CastSpeed *= (1 + Amount / 100);
		}
		else if (StatName == "ReelSpeed")
		{
			PlayerStats.ReelSpeed *= (1 + Amount / 100);
		}
		else if (StatName == "CatchMultiplier")
		{
			PlayerStats.CatchMultiplier += int(Amount);
		}
	}
}