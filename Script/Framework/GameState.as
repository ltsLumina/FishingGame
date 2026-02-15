class AFishGameState : AGameStateBase
{
    UPROPERTY()
    UDataTable FishingHoleDataTable;
};

UFUNCTION(BlueprintPure)
AFishGameState GetFishGameStateBase()
{
    return Cast<AFishGameState>(Gameplay::GetGameState());
}