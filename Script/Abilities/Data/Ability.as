UCLASS(Abstract)
class UAbility : UObject
{
	UPROPERTY()
	int UnlockLevel = 1;

	UFUNCTION(BlueprintEvent)
	void Execute(UAbilityData AbilityData, AFishCharacter Instigator, UFishingStateComponent FishingState)
	{
		Print("Executing ability: " + AbilityData.Details.Name.ToString() + " by " + Instigator.GetName());
	}

    /**
     * Attempts to commit the ability by checking and deducting costs.
     * @param AbilityData The data of the ability being used.
     * @param Instigator The character using the ability.
     * @param RequiresFishing Whether the ability requires the player to be fishing.
     * @return True if the ability was successfully committed; false otherwise.
     */
	UFUNCTION()
	bool CommitAbility(UAbilityData AbilityData, AFishCharacter Instigator, bool RequiresFishing = true)
	{
        if (RequiresFishing)
        {
            UFishingStateComponent FishingState = UFishingStateComponent::Get(Instigator);
            if (!FishingState.IsFishing)
            {
                PrintWarning("Ability " + AbilityData.Details.Name.ToString() + " requires fishing state.");
                return false;
            }
        }

		auto Params = UParameterBar::Get(Instigator);

		auto CostType = AbilityData.Details.Cost.Type;

		if (CostType == ECostType::None)
			return true;

		if (CostType == ECostType::MP)
		{
			if (Params.MP < AbilityData.Details.Cost.Amount)
			{
				PrintWarning("Not enough MP to use ability: " + AbilityData.Details.Name.ToString());
				return false;
			}

            Params.MP -= AbilityData.Details.Cost.Amount;
            return true;
		}

        if (CostType == ECostType::ThaliaksFavor)
        {
            // Placeholder for Thaliak's Favor cost check
            PrintWarning("Thaliak's Favor cost type not implemented yet.");
            return true;
        }

		return false;
	}
};