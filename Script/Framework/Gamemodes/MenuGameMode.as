class AFishMainGameMode : AGameModeBase
{
	UFUNCTION(BlueprintOverride)
	void OnPostLogin(APlayerController NewPlayer)
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("LobbyData", 0);
		if (SaveGame == nullptr)
			return;
        
		// if there's lobby data remaining because we crashed (didnt call GameInstance.Shutdown()), we attempt to reconnect with the old session ID (if its valid)
		auto LobbySaveGame = Cast<ULobbySaveGame>(SaveGame);
		PrintWarning("Lobby Data found!");

		auto Instance = Cast<UFishGameInstance>(GameInstance);
		Instance.AttemptReconnect(LobbySaveGame.LobbyData.SessionID);
	}
};