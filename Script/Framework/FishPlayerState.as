class AFishPlayerState : APlayerState
{
    UPROPERTY(Category = "Stats", Replicated, DisplayName = "Level")
    int ExperienceLevel = 1;

	UFUNCTION(Server, DisplayName = "Level Up")
	void LevelUp_Server()
	{
		ExperienceLevel++;
	}
};