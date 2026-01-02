event void FOnLevelUp(int NewLevel);

class UExperienceComponent : UFishComponentBase
{
	UPROPERTY(Category = "Stats", SaveGame, Replicated)
	FExperienceData ExperienceData;

	UPROPERTY(Category = "Stats", BlueprintGetter = "GetXPToLevelUp", VisibleInstanceOnly)
	float XPToNextLevel;

	UFUNCTION(BlueprintPure)
	float GetXPToLevelUp()
	{
		float RequiredXP = EXPGainCurve.GetFloatValue(ExperienceData.Level + 1);
		return RequiredXP - ExperienceData.CurrentXP;
	}

	UPROPERTY(Category = "Stats", BlueprintGetter = "GetNextLevelXP", VisibleInstanceOnly)
	float NextLevelXP;

	UFUNCTION(BlueprintPure)
	float GetNextLevelXP()
	{
		return EXPGainCurve.GetFloatValue(ExperienceData.Level + 1);
	}

	UPROPERTY(Category = "Stats", EditDefaultsOnly)
	UCurveFloat EXPGainCurve;

	UPROPERTY(Category = "Events")
	FOnLevelUp OnLevelUp;

	default bReplicates = true;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);
		
		Character.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFishCaught(AFish Fish)
	{
		GainExperience(Fish.Item.FishData.ExperienceValue);
	}

	UFUNCTION()
	void GainExperience(float Amount)
	{
		ExperienceData.CurrentXP += Amount;

		float RequiredXP = EXPGainCurve.GetFloatValue(ExperienceData.Level + 1);
		while (ExperienceData.CurrentXP >= RequiredXP)
		{
			ExperienceData.CurrentXP -= RequiredXP;
			LevelUp();
			RequiredXP = EXPGainCurve.GetFloatValue(ExperienceData.Level + 1);
		}
	}

	UFUNCTION(Server)
	void LevelUp()
	{
		ExperienceData.Level++;
		OnLevelUp.Broadcast(ExperienceData.Level);
		
		Notifications::AddNotification(f"You reached level {ExperienceData.Level}!");
		
		BP_OnLevelUp(ExperienceData.Level);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Level Up")
	void BP_OnLevelUp(int NewLevel)
	{}

	UFUNCTION(Category = "Save Game")
	bool SaveExperience()
	{
		auto SaveGame = NewObject(this, UExperienceSaveGame);
		SaveGame.SavedExperienceData = ExperienceData;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerExperience", 0);
	}

	UFUNCTION(Category = "Save Game")
	ELoadResult LoadExperience()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerExperience", 0);
		if (SaveGame == nullptr)
			return ELoadResult::SuccessNoData;

		auto LoadedSave = Cast<UExperienceSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		ExperienceData = LoadedSave.SavedExperienceData;
		return ELoadResult::Success;
	}
};

struct FExperienceData
{
	UPROPERTY(Category = "Stats", DisplayName = "Level", VisibleInstanceOnly, SaveGame, Replicated)
	int Level = 1;

	UPROPERTY(Category = "Stats", DisplayName = "XP", VisibleInstanceOnly, SaveGame)
	float CurrentXP;
}

struct FAbilityUnlockInfo
{
	UPROPERTY(Category = "Ability", SaveGame)
	UAbilityData Ability;

	UPROPERTY(Category = "Ability", Meta = (UIMin = "1", UIMax = "100"), SaveGame)
	int UnlockLevel = 1;
}