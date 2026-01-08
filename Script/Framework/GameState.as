class AFishGameState : AGameStateBase
{
    UPROPERTY()
    UDataTable FishingHoleDataTable;
    
    UPROPERTY(VisibleInstanceOnly)
    bool IsSinglePlayer = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        System::SetTimer(this, n"CheckSinglePlayerStatus", 1.5f, false);
    }

    UFUNCTION(NotBlueprintCallable)
    private void CheckSinglePlayerStatus()
    {
        IsSinglePlayer = PlayerArray.Num() <= 1;
    }
};

UFUNCTION(BlueprintPure)
AFishGameState GetFishGameStateBase()
{
    return Cast<AFishGameState>(Gameplay::GetGameState());
}