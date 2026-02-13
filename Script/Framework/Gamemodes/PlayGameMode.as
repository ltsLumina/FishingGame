class AFishPlayGameMode : AGameModeBase
{
	int NetIndex = 0;
	
	UFUNCTION(BlueprintOverride)
	void OnPostLogin(APlayerController NewPlayer)
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("LobbyData", 0);
		if (SaveGame == nullptr) throw("No Saved Lobby Data found!");
		auto LobbySaveGame = Cast<ULobbySaveGame>(SaveGame);

		int indx = 0;
		indx = GetFishGameStateBase().PlayerArray.Num();

		// if we're the first client to join, we're assign as the backup host for host migration
		if (indx >= 2) // first client to join
		{
			// TODO: get average ping and assign the best one as backup host

			LobbySaveGame.LobbyData.IsBackupHost = true;
			Gameplay::SaveGameToSlot(SaveGame, "LobbyData", 0);
			PrintWarning(f"{NewPlayer.PlayerState.PlayerName} has been assigned as the backup host in the event of host migration.");
		}
	}
};

UFUNCTION(BlueprintPure, Category = "Gamemode")
AFishPlayGameMode GetFishPlayGameMode()
{
	return Cast<AFishPlayGameMode>(Gameplay::GetGameMode());
}