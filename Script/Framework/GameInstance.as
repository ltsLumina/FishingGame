enum EHostSessionResult
{
	Success,
	Failed,
};

enum EFindSessionResult
{
	Success,
	NotFound,
	Failed,
};

event void FOnHostSession(EHostSessionResult Result);
event void FOnFindSessionsStart();
event void FOnFindSessionsComplete(EFindSessionResult Result);

namespace AdvancedSessions
{
	namespace Properties
	{
		const FName SESSION_NAME = n"SESSION_NAME";
		const FName SESSION_TAGS = n"SESSION_TAGS";
		const FName HOST_STEAM_ID = n"HOST_STEAM_ID";
		const FName SESSION_ID = n"SESSION_ID";
	}
}

class UFishGameInstance : UAdvancedFriendsGameInstance
{
	UPROPERTY(BlueprintReadOnly)
	const FName SESSION_NAME = n"SESSION_NAME";

	UPROPERTY(BlueprintReadOnly)
	const FName SESSION_TAGS = n"SESSION_TAGS";

	UPROPERTY(BlueprintReadOnly)
	const FName HOST_STEAM_ID = n"HOST_STEAM_ID";

	UPROPERTY(BlueprintReadOnly)
	const FName SESSION_ID = n"SESSION_ID";

	UPROPERTY(Category = "Events | Sessions")
	FOnHostSession OnHostSession;

	UPROPERTY(Category = "Events | Sessions")
	FOnFindSessionsStart OnFindSessionsStart;

	UPROPERTY(Category = "Events | Sessions")
	FOnFindSessionsComplete OnFindSessionsComplete;

	FTimerHandle ReconnectHandle;
	FString ReconnectSessionID;

	UFUNCTION(BlueprintOverride)
	void HandleNetworkError(ENetworkFailure FailureType, bool bIsServer)
	{
		switch (FailureType)
		{
			case ENetworkFailure::ConnectionLost:
				HandleConnectionLost();
				break;

			case ENetworkFailure::ConnectionTimeout:
				break;

			case ENetworkFailure::FailureReceived:
				break;

			case ENetworkFailure::OutdatedClient:
				break;

			case ENetworkFailure::OutdatedServer:
				break;

			case ENetworkFailure::PendingConnectionFailure:
				break;

			default:
				break;
		}
	}

	void HandleConnectionLost()
	{
		FLobbyData LobbyData;

		if (LoadLobbyData(LobbyData) == ELoadResult::Success)
		{
			if (LobbyData.IsBackupHost)
			{
				MigrateHost(LobbyData);
				PrintWarning(f"Migrating host!");
			}
			else // attempt to join newly migrated host
			{
				ReconnectSessionID = LobbyData::GetSessionID(LobbyData);
				ReconnectHandle = System::SetTimer(this, n"Internal_AttemptReconnect", 1.0f, true);
				System::SetTimer(this, n"Internal_AttemptReconnectTimedOut", 10.0f, false);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Internal_AttemptReconnect()
	{
		AttemptReconnect(ReconnectSessionID);
		PrintWarning("Attempting to reconnect to migrated host!");
	}

	UFUNCTION(NotBlueprintCallable)
	void Internal_AttemptReconnectTimedOut()
	{
		System::ClearAndInvalidateTimerHandle(ReconnectHandle);
		PrintWarning(f"Attempt reconnect failed!");
	}

	UFUNCTION(BlueprintEvent)
	void AttemptReconnect(FString SessionID)
	{}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
		ResetLobbyData();
	}

	UFUNCTION(BlueprintEvent)
	void MigrateHost(FLobbyData LobbyData)
	{}

	UFUNCTION()
	void ResetLobbyData()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("LobbyData", 0);
		if (SaveGame == nullptr)
			return;

		auto LoadedSave = Cast<ULobbySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return;

		// wipe the lobby data when the game quits
		LoadedSave.LobbyData = FLobbyData();
	}

	UFUNCTION()
	ELoadResult LoadLobbyData(FLobbyData&out LobbyData)
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("LobbyData", 0);
		if (SaveGame == nullptr)
			return ELoadResult::SuccessNoData;

		auto LoadedSave = Cast<ULobbySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		LobbyData = LoadedSave.LobbyData;

		return ELoadResult::Success;
	}

	UFUNCTION(BlueprintPure)
	FString GetServerTags(TArray<FString> InTags)
	{
		FString TagsString;
		for (FString Tag : InTags)
		{
			if (Tag.IsEmpty() || Tag == "None " || Tag == "None")
			{
				continue;
			}

			if (!TagsString.IsEmpty())
			{
				TagsString += ", ";
			}
			TagsString += Tag;
		}

		return TagsString;
	}
};