event void FOnLevelUp(int NewLevel);

class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Events")
	FOnLevelUp OnLevelUp;

	UPROPERTY(Category = "Stats")
	UCurveFloat EXPGainCurve;

	UPROPERTY(Category = "Stats", BlueprintGetter = "GetXPToLevelUp")
	float XPToLevelUp;
	
	UFUNCTION(BlueprintPure)
	float GetXPToLevelUp() { return EXPGainCurve.GetFloatValue(Stats.ExperienceLevel + 1); }

	UPROPERTY(Category = "Stats")
	UCurveFloat MPGainCurve;

	UPROPERTY(Category = "Stats")
	int Gil;

	UPROPERTY(Category = "Stats")
	FStats Stats;

	UPROPERTY(Category = "Quest")
	UQuest CurrentQuest;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (GetPawn() == nullptr)
		{
			System::SetTimer(this, n"DelayedStart", 0.1f, false);
		}
	}

	UFUNCTION()
	void GainExperience(float Amount)
	{
		Stats.ExperiencePoints += Amount;
		float RequiredXP = EXPGainCurve.GetFloatValue(Stats.ExperienceLevel + 1);
		while (Stats.ExperiencePoints >= RequiredXP)
		{
			Stats.ExperiencePoints -= RequiredXP;
			LevelUp_Server();
			RequiredXP = EXPGainCurve.GetFloatValue(Stats.ExperienceLevel + 1);
		}
	}

	UFUNCTION(Server, DisplayName = "Level Up")
	void LevelUp_Server()
	{
		Stats.ExperienceLevel++;
		OnLevelUp.Broadcast(Stats.ExperienceLevel);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleLevelUp(int NewLevel)
	{
		UParameterBar ParameterBar = UParameterBar::Get(GetPawn());
		if (ParameterBar != nullptr)
		{
			float NewMaxMP = MPGainCurve.GetFloatValue(NewLevel);
			ParameterBar.MaxMP = NewMaxMP;
			ParameterBar.MP = NewMaxMP;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DelayedStart() // To ensure Pawn is possessed and available
	{
		UParameterBar ParameterBar = UParameterBar::Get(GetPawn());
		ParameterBar.MP = MPGainCurve.GetFloatValue(Stats.ExperienceLevel);
		ParameterBar.MaxMP = MPGainCurve.GetFloatValue(Stats.ExperienceLevel);

		OnLevelUp.AddUFunction(this, n"HandleLevelUp");
		GetFishCharacterBase().InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleInventoryChanged(FName ID, UItem Item, EInventoryChangeType Change)
	{
		if (CurrentQuest == nullptr)
			return;

		for (auto& Objective : CurrentQuest.Objectives)
		{
			if (Objective.IsSatisfied(GetFishCharacterBase()))
			{
				Print("Objective satisfied: " + Objective.GetName(), 3.0f, FLinearColor::Green);
			}
		}
	}

	UFUNCTION(Category = "Gil")
	void GainGil(int Amount)
	{
		Gil += Amount;
	}
};

AFishPlayerState GetFishPlayerStateBase(AController Controller)
{
	return Cast<AFishPlayerState>(Controller.PlayerState);
}

AFishPlayerState GetFishPlayerStateBase(AFishCharacter Character)
{
	return GetFishPlayerStateBase(Character.GetController());
}

AFishPlayerState GetFishPlayerStateBase()
{
	return GetFishPlayerStateBase(GetFishCharacterBase());
}

struct FStats
{
	UPROPERTY(Category = "Stats", Replicated, DisplayName = "Level")
	int ExperienceLevel = 1;

	UPROPERTY(Category = "Stats", Replicated, DisplayName = "XP")
	float ExperiencePoints;

	UPROPERTY(Category = "Stats", Replicated, DisplayName = "Gathering Points")
	int Gathering = 100;
}