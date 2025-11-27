class UAbilityHandlerComponent : UActorComponent
{
	UFUNCTION(NotBlueprintCallable)
	void InvokeAbility(UAbilityData Ability)
	{
		//Print("Ability invoked: " + Ability.GetName());

		BP_InvokeAbility(Ability);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Invoke Ability")
	void BP_InvokeAbility(UAbilityData AbilityData)
	{}
};