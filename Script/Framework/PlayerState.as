event void FOnLevelUp(int NewLevel);

class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Events")
	FOnLevelUp OnLevelUp;

	UPROPERTY(Category = "Stats", Replicated)
	FStats Stats;

	UPROPERTY(Category = "Quest", Replicated)
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
		OnLevelUp.AddUFunction(this, n"HandleLevelUp");
	}

	UFUNCTION()
	void HandleLevelUp(int NewLevel)
	{
		UParameterBar ParameterBar = UParameterBar::Get(GetPawn());
		if (ParameterBar != nullptr)
		{
			// TODO: sorta temporary
			ParameterBar.MaxMP += 50;
			ParameterBar.MP = ParameterBar.MaxMP;
		}
	}
};

struct FStats
{
	UPROPERTY(Category = "Stats", Replicated, DisplayName = "Level")
	int ExperienceLevel = 1;

	UPROPERTY(Category = "Stats", Replicated, DisplayName = "Gathering Points")
	int Gathering = 100;
}