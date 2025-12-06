event void FOnLevelUp(int NewLevel);

class UExperienceComponent : UFishComponent
{
    UPROPERTY(Category = "Stats", Replicated, DisplayName = "Level", VisibleInstanceOnly)
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
			LevelUp_Server();
			RequiredXP = EXPGainCurve.GetFloatValue(ExperienceLevel + 1);
		}
	}

	UFUNCTION(Server, DisplayName = "Level Up")
	void LevelUp_Server()
	{
		ExperienceLevel++;
		OnLevelUp.Broadcast(ExperienceLevel);
	}

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