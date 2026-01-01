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
	UFUNCTION(BlueprintEvent)
	void ApplyTrait(AFishCharacter Character, UStatsComponent Stats, FStats ModifiedStats, UFishingComponent FishingComponent, UFishingHoleComponent FishingHole, UFishingRod Rod)
	{}

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