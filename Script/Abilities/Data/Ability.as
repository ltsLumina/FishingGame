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
    
    UFUNCTION()
    void EndAbility()
    {
        if (HasCommited)
        {
            HasCommited = false;
        }
        else
        {
            PrintError("Ability ended without being committed!\nMake sure to call CommitAbility() in your ability implementation blueprint!", 30.0f);
        }
    }

    bool HasCommited;

	/**
	 * Attempts to commit the ability by checking and deducting costs.
     * This function must be called within the ability execution to successfully use the ability, failure to do so will result in an error.
	 * @param AbilityData The data of the ability being used.
	 * @param Instigator The character using the ability.
	 * @param RequiresFishing Whether the ability requires the player to be fishing.
	 * @return True if the ability was successfully committed; false otherwise.
	 */
	UFUNCTION()
	bool CommitAbility(UAbilityData AbilityData, AFishCharacter Instigator)
	{
		if (AbilityData.Details.RequiresFishing)
		{
			UFishingStateComponent FishingState = UFishingStateComponent::Get(Instigator);
			if (!FishingState.IsFishing)
			{
				PrintWarning("Ability " + AbilityData.Details.Name.ToString() + " requires fishing state.", 2.5f);
				return false;
			}
		}

		auto Params = UParameterBar::Get(Instigator);

		auto CostType = AbilityData.Details.Cost.Type;

		if (CostType == ECostType::None)
        {

        }

		if (CostType == ECostType::MP)
		{
			if (Params.MP < AbilityData.Details.Cost.Amount)
			{
				PrintWarning("Not enough MP to use ability: " + AbilityData.Details.Name.ToString());
				return false;
			}

			Params.MP -= AbilityData.Details.Cost.Amount;
		}

		if (CostType == ECostType::ThaliaksFavor)
		{
			// Placeholder for Thaliak's Favor cost check
			PrintWarning("Thaliak's Favor cost type not implemented yet.");
		}

        // If all checks passed, invoke the ability and its cooldown, and trigger global cooldown

        TArray<UUserWidget> Widgets;
		Widget::GetAllWidgetsOfClass(Widgets, UHotbar, false);
		if (Widgets.Num() == 0)
			return false;

		UHotbar Hotbar = Cast<UHotbar>(Widgets[0]);
		if (Hotbar == nullptr)
			return false;

		Hotbar.GlobalCooldown();

        HasCommited = true;
		return true;
	}
};