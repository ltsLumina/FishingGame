UCLASS(Abstract)
class UTrait : UObject
{
	UPROPERTY(DisplayName = "Name")
	FText TraitName;

	UPROPERTY(Meta = (MultiLine))
	FText Description;

	UPROPERTY(Meta = (MultiLine))
	FText Effect;

	UPROPERTY()
	EFishRarity Rarity;

	UPROPERTY(VisibleAnywhere)
	bool IsEnhanced;

	/**
	 * Apply the effect of this trait to the given character.
	 */
	UFUNCTION(BlueprintEvent)
	void ApplyTrait(AFishCharacter Character, AFishPlayerState PlayerState, UStatsComponent Stats, UFishingComponent FishingComponent, UTokenComponent TokenComponent)
	{}

	UFUNCTION(BlueprintEvent)
	void ApplyTraitEnhanced(AFishCharacter Character, AFishPlayerState PlayerState, UStatsComponent Stats, UFishingComponent FishingComponent, UTokenComponent TokenComponent)
	{}
}