event void FOnLevelUp(int NewLevel);

class UExperienceComponent : UFishComponentBase
{
	UPROPERTY(Category = "Stats", SaveGame)
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

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	void LatePlay() override
	{
		Super::LatePlay();
		BP_LatePlay();

		Character.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay()
	{}

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

	UFUNCTION()
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
	bool LoadExperience()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerExperience", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UExperienceSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		ExperienceData = LoadedSave.SavedExperienceData;
		return true;
	}
};

struct FExperienceData
{
	UPROPERTY(Category = "Stats", DisplayName = "Level", VisibleInstanceOnly, SaveGame)
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