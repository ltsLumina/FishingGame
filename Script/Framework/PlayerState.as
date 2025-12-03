event void FOnLevelUp(int NewLevel);

class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Events")
	FOnLevelUp OnLevelUp;

	UPROPERTY(Category = "Stats")
	UCurveFloat ExperienceCurve;

	UPROPERTY(Category = "Stats")
	int Gil;

	UPROPERTY(Category = "Stats")
	FStats Stats;

	UPROPERTY(Category = "Quest")
	UQuest CurrentQuest;

	UFUNCTION(Server, DisplayName = "Level Up")
	void LevelUp_Server()
	{
		Stats.ExperienceLevel++;
		OnLevelUp.Broadcast(Stats.ExperienceLevel);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (GetPawn() == nullptr)
		{
			System::SetTimer(this, n"DelayedStart", 0.1f, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleLevelUp(int NewLevel)
	{
		UParameterBar ParameterBar = UParameterBar::Get(GetPawn());
		if (ParameterBar != nullptr)
		{
			float NewMaxMP = ExperienceCurve.GetFloatValue(NewLevel);
			ParameterBar.MaxMP = NewMaxMP;
			ParameterBar.MP = NewMaxMP;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DelayedStart() // To ensure Pawn is possessed and available
	{
		UParameterBar ParameterBar = UParameterBar::Get(GetPawn());
		ParameterBar.MP = ExperienceCurve.GetFloatValue(Stats.ExperienceLevel);
		ParameterBar.MaxMP = ExperienceCurve.GetFloatValue(Stats.ExperienceLevel);

		OnLevelUp.AddUFunction(this, n"HandleLevelUp");
		GetFishCharacterBase().InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleInventoryChanged()
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

	UPROPERTY(Category = "Stats", Replicated, DisplayName = "Gathering Points")
	int Gathering = 100;
}