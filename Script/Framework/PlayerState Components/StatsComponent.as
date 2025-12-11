class UStatsComponent : UFishComponentBase
{
    UPROPERTY(Category = "Stats", SaveGame)
    FStats Stats;

    UPROPERTY(Category = "Stats", SaveGame)
	int Gil;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    void LatePlay() override
    {
        Super::LatePlay();
        BP_LatePlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
    void BP_LatePlay() { }

    UFUNCTION(Category = "Gil")
	void GainGil(int Amount)
	{
		Gil += Math::Max(0, Amount);
	}

    UFUNCTION(Category = "Gil")
    bool SpendGil(int Amount)
    {
        if (Gil >= Amount)
        {
            Gil -= Amount;
            return true;
        }
        return false;
    }

    UFUNCTION(Category = "Data")
    bool SaveStats()
    {
        auto SaveGame = NewObject(this, UStatsSaveGame);
        SaveGame.SavedStats = Stats;
        SaveGame.SavedGil = Gil;
        return Gameplay::SaveGameToSlot(SaveGame, "PlayerStats", 0);
    }

	UFUNCTION(Category = "Data")
    bool LoadStats()
    {
        auto SaveGame = Gameplay::LoadGameFromSlot("PlayerStats", 0);
        if (SaveGame == nullptr)
            return false;

        auto LoadedSave = Cast<UStatsSaveGame>(SaveGame);
        if (LoadedSave == nullptr)
            return false;

        Stats = LoadedSave.SavedStats;
        Gil = LoadedSave.SavedGil;

        return true;
    }
};

struct FStats
{
	UPROPERTY(Category = "Stats", DisplayName = "Gathering Points", SaveGame)
	int Gathering = 100;
}