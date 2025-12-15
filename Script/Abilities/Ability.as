UCLASS(Abstract)
class UAbility : UObject
{
	UFUNCTION(BlueprintEvent)
	void Execute(UAbilityData AbilityData, AFishCharacter Instigator, UFishingComponent FishingComponent)
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

	UFUNCTION(BlueprintProtected)
	void GetWidget(TSubclassOf<UUserWidget> WidgetClass, bool TopLevelOnly, TArray<UUserWidget>&out FoundWidgets)
	{
		TArray<UUserWidget> Widgets;
		Widget::GetAllWidgetsOfClass(Widgets, WidgetClass, TopLevelOnly);
		FoundWidgets = Widgets;
	}

    bool HasCommited;

	/**
	 * Attempts to commit the ability by checking and deducting costs.
     * This function must be called within the ability execution to successfully use the ability, failure to do so will result in an error.
	 * @param AbilityData The data of the ability being used.
	 * @param Instigator The character using the ability.
	 * @return True if the ability was successfully committed; false otherwise.
	 */
	UFUNCTION()
	bool CommitAbility(UAbilityData AbilityData, AFishCharacter Instigator)
	{
		if (!AbilityData.CanUse(Instigator))
		{
			PrintWarning("Ability conditions not met for: " + AbilityData.Details.Name.ToString());
			return false;
		}

		auto Params = UParameterBar::Get(Instigator);

		auto CostType = AbilityData.Details.Cost.Type;

		if (CostType == ECostType::None)
        {

        }

		if (CostType == ECostType::MP)
		{
			if (Params.Mana < AbilityData.Details.Cost.Amount)
			{
				PrintWarning("Not enough MP to use ability: " + AbilityData.Details.Name.ToString());
				return false;
			}

			Params.Mana -= AbilityData.Details.Cost.Amount;
		}

		if (CostType == ECostType::Other)
		{
			PrintWarning("Ability uses 'Other' cost type, which is not implemented yet: " + AbilityData.Details.Name.ToString());
		}

        // If all checks passed, invoke the ability and its cooldown, and trigger global cooldown

        TArray<UUserWidget> Widgets;
		Widget::GetAllWidgetsOfClass(Widgets, UHotbar, false);
		if (Widgets.Num() == 0)
			return false;

		UHotbar Hotbar = Cast<UHotbar>(Widgets[0]);
		if (Hotbar == nullptr)
			return false;

		if (AbilityData.Details.Cooldown.Type == ECooldownType::GCD)
		{
			Hotbar.GlobalCooldown();
		}
		else if (AbilityData.Details.Cooldown.Type == ECooldownType::oGCD)
		{
			Hotbar.OffGlobalCooldown(AbilityData);
		}

        HasCommited = true;
		return true;
	}
};