class AFishGameState : AGameStateBase
{
    UPROPERTY(BlueprintGetter = "GetIsSinglePlayer")
    bool IsSinglePlayer = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        System::SetTimer(this, n"CheckSinglePlayerStatus", 0.5f, false);
    }

    UFUNCTION(NotBlueprintCallable)
    private void CheckSinglePlayerStatus()
    {
        IsSinglePlayer = PlayerArray.Num() <= 1;
    }

    UFUNCTION(BlueprintPure, DisplayName = "Is SinglePlayer")
    bool GetIsSinglePlayer()
    {
        return IsSinglePlayer;
    }
};