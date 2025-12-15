class UHotbarSlot : UUserWidget
{
	UPROPERTY(BindWidget)
	UButton CastButton;

	UPROPERTY(BindWidget)
	UProgressBar CooldownBar;

	UPROPERTY()
	UAbilityData AbilityData;

	UPROPERTY()
	float CooldownTime;

	bool OnCooldown;
	float CooldownPercent;

	UFUNCTION(NotBlueprintCallable)
	void Invoke()
	{
		if (OnCooldown || !CanUse())
			return;

		auto AbilityHandler = UAbilityHandlerComponent::Get(GetOwningPlayerPawn());
		AbilityHandler.InvokeAbility(AbilityData);

		BP_Invoke();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Invoke")
	void BP_Invoke()
	{}

	/**
	 * Unreal calls construct too slowly so we're doing it this way :P
	 */
	UFUNCTION(BlueprintEvent)
    void LateConstruct() { }

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ValidateConditions();

		OnCooldown = false;
		CooldownPercent = 1.0f;

		CastButton.OnClicked.AddUFunction(this, n"Invoke");

		BP_Construct();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Construct")
	void BP_Construct()
	{}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		BP_Tick(MyGeometry, InDeltaTime);

		CastButton.SetIsEnabled(CanUse());

		if (OnCooldown)
		{
			float Duration = AbilityData.Details.Cooldown.Duration;

			if (Duration > 0.0f)
			{
				float Speed = 1.0f / Duration;
				CooldownPercent = Math::FInterpConstantTo(CooldownPercent, 0.0f, InDeltaTime, Speed);
			}
			else
			{
				CooldownPercent = 0.0f;
			}

			CooldownBar.SetPercent(CooldownPercent);
			CooldownTime = Duration * CooldownPercent;

			if (Math::IsNearlyZero(CooldownPercent))
			{
				OnCooldown = false;
			}
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(FGeometry MyGeometry, float InDeltaTime)
	{}

	/**
	 * Checks if the ability can be used.
	 * Does not account for the cooldown state.
	 */
	UFUNCTION(BlueprintPure)
	bool CanUse()
	{
		if (AbilityData == nullptr)
			return false;

		AFishCharacter Character = GetFishCharacterBase();
		auto Param = UParameterBar::Get(Character);
		UAbilityHandlerComponent AbilityHandler = Character.AbilityHandler;

		bool CanUse = AbilityData.CanUse(Character);
		bool HasMP = Param.HasEnoughMana(AbilityData.Details.Cost.Amount);
		bool HasAbility = AbilityHandler.HasAbility(AbilityData);

		return CanUse && HasMP && HasAbility;
	}

	UFUNCTION(BlueprintPure)
	bool GetOnCooldown()
	{
		return OnCooldown;
	}

	void ValidateConditions()
	{
		if (AbilityData != nullptr)
		{
			TArray<UAbilityCondition> IllegalConditions;

			for (int i = AbilityData.Conditions.Num() - 1; i >= 0; i--)
			{
				UAbilityCondition Condition = AbilityData.Conditions[i];
				if (Condition == nullptr)
				{
					IllegalConditions.Add(AbilityData.Conditions[i]);
					AbilityData.Conditions.RemoveAt(i);

					FString msgPart1 = f"Removed null ability condition from ability: {AbilityData.Details.Name.ToString()}";
					FString msgPart2 = "Make sure not to leave empty condition slots in the ability data asset.";
					PrintWarning(f"{msgPart1}\n{msgPart2}", 10.0f, FLinearColor(1.00, 0.5, 0.00));
				}
			}
		}
	}

	UFUNCTION()
	void StartCooldown()
	{
		OnCooldown = true;
		CooldownPercent = 1.0f;
	}
}