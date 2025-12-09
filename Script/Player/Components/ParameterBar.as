class UParameterBar : UFishComponentBase
{
	UPROPERTY(Category = "Parameter Bar", VisibleAnywhere)
	float MP = 500;

	UPROPERTY(Category = "Parameter Bar", VisibleAnywhere)
	float MaxMP = 500;

	UPROPERTY(Category = "Parameter Bar", EditAnywhere)
	float RegenerationRate = 5.0f;

	UPROPERTY(Category = "Parameter Bar", VisibleAnywhere, Meta = (Units = "s"))
	FTimespan TimeTillFullMP;

	UPROPERTY(Category = "Parameter Bar", EditDefaultsOnly, DisplayName = "MP Per Level Curve")
	UCurveFloat MPPerLevelCurve;

	UFishingComponent FishingComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MP = MaxMP;
	}

	void LatePlay() override
	{
		Super::LatePlay();

		FishingComponent = UFishingComponent::Get(Character);
		State.ExperienceComponent.OnLevelUp.AddUFunction(this, n"OnLevelUp");
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
			float FreeSpace = Math::Max(0.0f, MaxMP - MP - StoredMP);
			if (FreeSpace > 0.0f)
				StoredMP = Math::Min(StoredMP + DeltaSeconds * RegenerationRate, StoredMP + FreeSpace);
		}
		else
		{
			// If we were storing regen while fishing, grant it now.
			if (StoredMP > 0.0f)
			{
				MP = Math::Min(MP + StoredMP, MaxMP);
				StoredMP = 0.0f;
			}

			// Normal regeneration when not fishing.
			if (MP < MaxMP)
				MP = Math::Min(MP + DeltaSeconds * RegenerationRate, MaxMP);
		}

		// Update time till full based on current effective MP (including stored regen).
		float EffectiveMP = Math::Min(MP + StoredMP, MaxMP);
		float TimeToFullSeconds = (MaxMP - EffectiveMP) / RegenerationRate;
		TimeTillFullMP = FTimespan::FromSeconds(TimeToFullSeconds);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnLevelUp(int NewLevel)
	{
		MP = MPPerLevelCurve.GetFloatValue(NewLevel);
		MaxMP = MPPerLevelCurve.GetFloatValue(NewLevel);
	}
};