class UParameterBar : UFishComponentBase
{
	UPROPERTY(Category = "Parameter Bar", VisibleAnywhere, BlueprintReadOnly)
	float Mana = 500;

	UPROPERTY(Category = "Parameter Bar", VisibleAnywhere, BlueprintReadOnly)
	float MaxMana = 500;

	UPROPERTY(Category = "Parameter Bar", EditAnywhere)
	float RegenerationRate = 5.0f;

	UPROPERTY(Category = "Parameter Bar", VisibleAnywhere, Meta = (Units = "s"))
	FTimespan TimeTillFullMP;

	UPROPERTY(Category = "Parameter Bar", EditDefaultsOnly, DisplayName = "MP Per Level Curve")
	UCurveFloat MPPerLevelCurve;

	UFishingComponent FishingComponent;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, AFishController InController) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InController);
		
		Mana = MaxMana;
		
		FishingComponent = Character.FishingComponent;
		PlayerState.ExperienceComponent.OnLevelUp.AddUFunction(this, n"OnLevelUp");
	}

	/**
	 * The amount of stored MP regeneration accumulated while fishing.
	 * This regeneration is only applied to the actual MP pool when the player stops fishing.
	 */
	float StoredMP;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (FishingComponent == nullptr)
			return;

		TArray<EFishingState> PausedStates; // States during which MP regeneration is paused
		PausedStates.Add(EFishingState::Fishing);
		PausedStates.Add(EFishingState::FishOnHook);
		bool IsFishing = PausedStates.Contains(FishingComponent.CurrentState);

		// While fishing: accumulate regeneration into StoredMP (don't apply to MP yet).
		if (IsFishing)
		{
			float FreeSpace = Math::Max(0.0f, MaxMana - Mana - StoredMP);
			if (FreeSpace > 0.0f)
				StoredMP = Math::Min(StoredMP + DeltaSeconds * RegenerationRate, StoredMP + FreeSpace);
		}
		else
		{
			// If we were storing regen while fishing, grant it now.
			if (StoredMP > 0.0f)
			{
				Mana = Math::Min(Mana + StoredMP, MaxMana);
				StoredMP = 0.0f;
			}

			// Normal regeneration when not fishing.
			if (Mana < MaxMana)
				Mana = Math::Min(Mana + DeltaSeconds * RegenerationRate, MaxMana);
		}

		// Update time till full based on current effective MP (including stored regen).
		float EffectiveMP = Math::Min(Mana + StoredMP, MaxMana);
		float TimeToFullSeconds = (MaxMana - EffectiveMP) / RegenerationRate;
		TimeTillFullMP = FTimespan::FromSeconds(TimeToFullSeconds);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnLevelUp(int NewLevel)
	{
		Mana = MPPerLevelCurve.GetFloatValue(NewLevel);
		MaxMana = MPPerLevelCurve.GetFloatValue(NewLevel);
	}

	UFUNCTION(BlueprintPure)
	bool HasEnoughMana(float CostAmount)
	{
		return Mana >= CostAmount;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Has Enough Mana")
	bool HasEnoughManaByData(UAbilityData& AbilityData)
	{
		return HasEnoughMana(AbilityData.Details.Cost.Amount);
	}

	UFUNCTION(BlueprintPure)
	float GetManaPercentage()
	{
		return Mana / MaxMana;
	}

	UFUNCTION()
	bool ConsumeMana(float Amount)
	{
		if (HasEnoughMana(Amount))
		{
			Mana -= Amount;
			return true;
		}
		return false;
	}

	UFUNCTION()
	void RestoreMana(float Amount)
	{
		Mana = Math::Min(Mana + Amount, MaxMana);
	}
};