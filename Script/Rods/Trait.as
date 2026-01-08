UCLASS(Abstract)
class UTrait : UObject
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, DisplayName = "Name")
	FText TraitName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Meta = (MultiLine))
	FText Description;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Meta = (MultiLine))
	FText BasicEffect;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Meta = (MultiLine, EditCondition = "CanBeEnhanced", EditConditionHides))
	FText EnhancedEffect;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	EFishRarity Rarity;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	bool CanBeEnhanced;

	UPROPERTY(BlueprintReadOnly)
	UFishingComponent FishingComponent;

	UPROPERTY(BlueprintReadOnly)
	UStatsComponent StatsComponent;

	UPROPERTY(BlueprintReadOnly)
	UTokenComponent TokenComponent;

	/**
	 * Apply the effect of this trait to the given character.
	 */
	UFUNCTION(BlueprintEvent)
	void ApplyTrait(AFishCharacter Character, AFishPlayerState PlayerState)
	{ }

	/**
	 * Apply the enhanced effect of this trait to the given character.
	 * Enhanced traits have stronger or additional effects compared to their base versions.
	 * Randomly rolled when the trait is created. @see UFishingComponent::RollTrait
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Apply Trait (Enhanced)")
	void ApplyTraitEnhanced(AFishCharacter Character, AFishPlayerState PlayerState)
	{ }

	bool bInitialized = false;

	void Init(UFishingComponent InFishingComponent, UStatsComponent InStatsComponent, UTokenComponent InTokenComponent)
	{
		FishingComponent = InFishingComponent;
		StatsComponent = InStatsComponent;
		TokenComponent = InTokenComponent;
	}
}