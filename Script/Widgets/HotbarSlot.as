class UHotbarSlot : UUserWidget
{
	UPROPERTY(BindWidget)
	UButton CastButton;

	UPROPERTY(BindWidget)
	UProgressBar CooldownBar;

	UPROPERTY()
	UAbilityData AbilityData;

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

			if (CooldownPercent <= 0.01f || Math::IsNearlyZero(CooldownPercent))
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

		bool CanUse = AbilityData.CanUse(Character);

		auto StatusComp = UParameterBar::Get(Character);
		bool HasMP = StatusComp.MP >= AbilityData.Details.Cost.Amount;

		bool LevelRequirementMet = false;
		auto PlayerState = Cast<AFishPlayerState>(Character.PlayerState);
		if (PlayerState != nullptr)
		{
			LevelRequirementMet = PlayerState.ExperienceLevel >= AbilityData.Details.UnlockLevel;
		}

		return CanUse && HasMP && LevelRequirementMet;
	}

	void ValidateConditions()
	{
		if (AbilityData != nullptr)
		{
			TArray<TSubclassOf<UAbilityCondition>> IllegalConditions = TArray<TSubclassOf<UAbilityCondition>>();

			for (TSubclassOf<UAbilityCondition> Condition : AbilityData.Conditions)
			{
				if (Condition == nullptr)
				{
					IllegalConditions.Add(Condition);
					continue;
				}
			}

			for (TSubclassOf<UAbilityCondition> Condition : IllegalConditions)
			{
				AbilityData.Conditions.Remove(Condition);
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