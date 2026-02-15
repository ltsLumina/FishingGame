class AFishMainGameMode : AGameModeBase
{
	UFUNCTION(BlueprintOverride)
	void OnPostLogin(APlayerController NewPlayer)
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("LobbyData", 0);
		if (SaveGame == nullptr)
			return;
        
		auto LobbySaveGame = Cast<ULobbySaveGame>(SaveGame);
		PrintWarning("Lobby Data found!");

		auto Instance = Cast<UFishGameInstance>(GameInstance);
		Instance.AttemptReconnect(LobbySaveGame.LobbyData.SessionID);
	} 
};