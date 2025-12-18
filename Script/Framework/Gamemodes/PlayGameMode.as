class AFishPlayGameMode : AGameModeBase
{
	
};

UFUNCTION(BlueprintPure, Category = "Gamemode")
AFishPlayGameMode GetFishPlayGameMode()
{
	return Cast<AFishPlayGameMode>(Gameplay::GetGameMode());
}