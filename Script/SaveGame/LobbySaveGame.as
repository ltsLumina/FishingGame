/**
 * Handles saving/loading lobby-specific data like the Session ID, who the backup host is (for host migration), etc.
 */
class ULobbySaveGame : USaveGame
{
	UPROPERTY(Category = "Data")
    FLobbyData LobbyData;
}

struct FLobbyData
{
	UPROPERTY(Category = "Data", BlueprintReadOnly, SaveGame)
	bool IsBackupHost;

	UPROPERTY(Category = "Data", SaveGame)
	FText SessionName;

	UPROPERTY(Category = "Data", SaveGame)
	TArray<FString> Tags;

	UPROPERTY(Category = "Data", SaveGame)
	FString HostSteamID;

	UPROPERTY(Category = "Data", SaveGame)
	FString SessionID;

    UPROPERTY(Category = "Data", SaveGame)
    int MaxPlayers;
    
    UPROPERTY(Category = "Data", SaveGame)
    bool UseLAN;

    /** 
	* FALSE Means the lobby is PRIVATE (friends only)
	* TRUE Means the lobby is PUBLIC to everyone.
	*/
    UPROPERTY(Category = "Data", SaveGame)
    bool ShouldAdvertise;

    // TODO
    UPROPERTY(Category = "Data", SaveGame)
    FGameTime GameTime;

    // TODO
    UPROPERTY(Category = "Data", SaveGame)
    EWeather Weather;
}

namespace LobbyData
{        
	/*
	UFUNCTION()
	FString GetSessionName(FLobbyData LobbyData)
	{
        TArray<FSessionPropertyKeyPair> ExtraSettings = LobbyData.ExtraSettings;
		ESessionSettingSearchResult Result;
		FString SettingValue;
		AdvancedSessions::GetSessionPropertyString(ExtraSettings, AdvancedSessions::Properties::SESSION_NAME, Result, SettingValue);
		return SettingValue;
	}

	UFUNCTION()
	FString GetSessionTags(FLobbyData LobbyData)
	{
        TArray<FSessionPropertyKeyPair> ExtraSettings = LobbyData.ExtraSettings;
		ESessionSettingSearchResult Result;
		FString SettingValue;
		AdvancedSessions::GetSessionPropertyString(ExtraSettings, AdvancedSessions::Properties::SESSION_TAGS, Result, SettingValue);
		return SettingValue;
	}

	UFUNCTION()
	FString GetHostSteamID(FLobbyData LobbyData)
	{
        TArray<FSessionPropertyKeyPair> ExtraSettings = LobbyData.ExtraSettings;
		ESessionSettingSearchResult Result;
		FString SettingValue;
		AdvancedSessions::GetSessionPropertyString(ExtraSettings, AdvancedSessions::Properties::HOST_STEAM_ID, Result, SettingValue);
		return SettingValue;
	}

	*/
    UFUNCTION()
    FString GetSessionID(TArray<FSessionPropertyKeyPair> ExtraSettings)
    {
        ESessionSettingSearchResult Result;
		FString SettingValue;
		AdvancedSessions::GetSessionPropertyString(ExtraSettings, AdvancedSessions::Properties::SESSION_ID, Result, SettingValue);
		return SettingValue;
    }
}