event void FOnLevelUp(int NewLevel);

class UExperienceComponent : UFishComponent
{
    UPROPERTY(Category = "Stats", DisplayName = "Level", VisibleInstanceOnly)
	int ExperienceLevel = 1;

	UPROPERTY(Category = "Stats", DisplayName = "XP", VisibleInstanceOnly)
	float CurrentXP;

	UPROPERTY(Category = "Stats", BlueprintGetter = "GetXPToLevelUp", VisibleInstanceOnly)
	float XPToLevelUp;

	UFUNCTION(BlueprintPure)
	float GetXPToLevelUp() { return EXPGainCurve.GetFloatValue(ExperienceLevel + 1); }

    UPROPERTY(Category = "Stats", EditDefaultsOnly)
	UCurveFloat EXPGainCurve;

    UPROPERTY(Category = "Events")
	FOnLevelUp OnLevelUp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay() { }

    void LatePlay() override
    {
        Super::LatePlay();

        OnLevelUp.AddUFunction(this, n"HandleLevelUp");
		Character.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
    }

	UFUNCTION(NotBlueprintCallable)
	void OnFishCaught(AFish Fish)
	{
		GainExperience(Fish.ExperienceValue);
	}

    UFUNCTION()
	void GainExperience(float Amount)
	{
		CurrentXP += Amount;
		float RequiredXP = EXPGainCurve.GetFloatValue(ExperienceLevel + 1);
		while (CurrentXP >= RequiredXP)
		{
			CurrentXP -= RequiredXP;
			LevelUp();
			RequiredXP = EXPGainCurve.GetFloatValue(ExperienceLevel + 1);
		}
	}

	UFUNCTION()
	void LevelUp()
	{
		ExperienceLevel++;
		OnLevelUp.Broadcast(ExperienceLevel);
		BP_OnLevelUp(ExperienceLevel);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Level Up")
	void BP_OnLevelUp(int NewLevel) { }

	UFUNCTION(NotBlueprintCallable)
	void HandleLevelUp(int NewLevel)
	{
		// Check for ability unlocks
		UAbilityHandlerComponent AbilityHandler = UAbilityHandlerComponent::Get(Character);
		if (AbilityHandler != nullptr)
		{
			UDataTable AbilityUnlockTable = AbilityHandler.AbilityUnlockTable;
			if (AbilityUnlockTable != nullptr)
			{
				TArray<FAbilityUnlockInfo> UnlockInfos;
				AbilityUnlockTable.GetAllRows(UnlockInfos);
				for (FAbilityUnlockInfo UnlockInfo : UnlockInfos)
				{
					if (UnlockInfo.UnlockLevel == NewLevel)
					{
						AbilityHandler.GrantAbility(UnlockInfo.Ability);
					}
				}
			}
		}
	}
};

struct FAbilityUnlockInfo
{
	UPROPERTY(Category = "Ability")
	UAbilityData Ability;

	UPROPERTY(Category = "Ability", Meta = (UIMin="1", UIMax="100"))
	int UnlockLevel = 1;
}