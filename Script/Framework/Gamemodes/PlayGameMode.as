class AFishPlayGameMode : AGameModeBase
{
	int NetIndex = 0;
	
	UFUNCTION(BlueprintOverride)
	void OnPostLogin(APlayerController NewPlayer)
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("LobbyData", 0);
		if (SaveGame == nullptr) throw("No Saved Lobby Data found!");
		auto LobbySaveGame = Cast<ULobbySaveGame>(SaveGame);

		// if we're the first client to join, we're assign as the backup host for host migration
		if (NetIndex == 1) // first client to join
		{
			LobbySaveGame.LobbyData.IsBackupHost = true;
			Gameplay::SaveGameToSlot(SaveGame, "LobbyData", 0);
			PrintWarning(f"{NewPlayer.PlayerState.PlayerName} has been assigned as the backup host in the event of host migration.");
		}
		else NetIndex++;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogout(AController ExitingController)
	{
		auto Instance = Cast<UFishGameInstance>(GameInstance);
		Instance.HandleConnectionLost();
	}
};

UFUNCTION(BlueprintPure, Category = "Gamemode")
AFishPlayGameMode GetFishPlayGameMode()
{
	return Cast<AFishPlayGameMode>(Gameplay::GetGameMode());
}