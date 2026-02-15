event void FOnGainedExperience(int GainedXP);
event void FOnLevelUp(int NewLevel);

class UExperienceComponent : UFishComponentBase
{
	UPROPERTY(Category = "Stats", DisplayName = "Level", VisibleInstanceOnly, SaveGame, Replicated)
	int Level = 1;

	UPROPERTY(Category = "Stats", DisplayName = "XP", VisibleInstanceOnly, SaveGame)
	float CurrentXP;

	UPROPERTY(Category = "Stats", EditDefaultsOnly)
	UCurveFloat EXPGainCurve;

	UPROPERTY(Category = "Events")
	FOnGainedExperience OnGainedXP;

	UPROPERTY(Category = "Events")
	FOnLevelUp OnLevelUp;

	default bReplicates = true;

//#region Helper Functions*
	/**
	 * @return the amount of XP to reach InLevel from the current amount of XP.
	 * For example, if you're currently at 500 XP, and need 750 to reach InLevel, this will return (750-200= 550) XP.
	 */
	UFUNCTION(BlueprintPure)
	float GetExperienceToLevel(int InLevel)
	{
		float RequiredXP = EXPGainCurve.GetFloatValue(InLevel);
		return RequiredXP - CurrentXP;
	}

	/**
	 * @return the amount of XP to reach the next level.
	 */
	UFUNCTION(BlueprintPure)
	float GetExperienceToNextLevel() property
	{
		return GetExperienceToLevel(Level + 1);
	}

	/**
	 * Returns a normalized [0..1] range of the progress to InLevel.
	 */
	UFUNCTION(BlueprintPure)
	float GetProgressToLevel(int InLevel)
	{
		float RequiredXP = EXPGainCurve.GetFloatValue(InLevel);
		float Progress = Math::NormalizeToRange(CurrentXP, 0, RequiredXP);
		return Progress;
	}

	/**
	 * @return a normalized [0..1] range of the progress to the next level.
	 */
	UFUNCTION(BlueprintPure)
	float GetProgressToNextLevel() property
	{
		return GetProgressToLevel(Level + 1);
	}

	/**
	 * @return the amount of XP required to reach a level from the previous level (the total amount from e.g., Level 1 to InLevel).
	 */
	UFUNCTION(BlueprintPure)
	float GetExperienceAtLevel(int InLevel)
	{
		return EXPGainCurve.GetFloatValue(InLevel);
	}

	UFUNCTION(BlueprintPure)
	float GetExperienceAtNextLevel() property
	{
		return GetExperienceAtLevel(Level + 1);
	}
//#endregion

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		InCharacter.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFishCaught(AFish Fish, UBait Bait, UFishingHoleComponent FishingHole)
	{
		GainExperience(Fish.Item.FishData.ExperienceValue);
	}

	UFUNCTION(Category = "Experience")
	void GainExperience(float Amount)
	{
		CurrentXP += Amount;

		TryLevelUp();
	}

	bool TryLevelUp()
	{
		int LevelUps = 0;
		
		float RequiredXP = EXPGainCurve.GetFloatValue(Level + 1);
		while (CurrentXP >= RequiredXP)
		{
			CurrentXP -= RequiredXP;
			LevelUp();
			LevelUps++;
			RequiredXP = EXPGainCurve.GetFloatValue(Level + 1);
		}

		return LevelUps > 0;
	}

	UFUNCTION()
	void LevelUp()
	{
		Server_LevelUp();
	}

	UFUNCTION(Server, NotBlueprintCallable)
	void Server_LevelUp()
	{
		Level++;

		Client_LevelUp(Level);
	}

	UFUNCTION(Client, NotBlueprintCallable)
	void Client_LevelUp(int NewLevel)
	{
		OnLevelUp.Broadcast(NewLevel);

		BP_OnLevelUp(Level);

		Notifications::AddNotification(f"You reached level {NewLevel}!");
	}

//#region Events
	UFUNCTION(BlueprintEvent, DisplayName = "Level Up")
	void BP_OnLevelUp(int NewLevel)
	{}
//#endregion

//#region Save/Load
	UFUNCTION(Category = "Save Game")
	bool SaveExperience()
	{
		auto SaveGame = Gameplay::CreateSaveGameObject(UExperienceSaveGame);
		SaveGame.Level = Level;
		SaveGame.CurrentXP = CurrentXP;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerExperience", 0);
	}

	UFUNCTION(Category = "Save Game")
	ELoadResult LoadExperience()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerExperience", 0);
		if (SaveGame == nullptr)
			return ELoadResult::NoData;

		auto LoadedSave = Cast<UExperienceSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		Level = LoadedSave.Level;
		CurrentXP = LoadedSave.CurrentXP;

		return ELoadResult::Success;
	}
//#endregion
};