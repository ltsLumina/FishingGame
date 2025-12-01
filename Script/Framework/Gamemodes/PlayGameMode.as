class AFishPlayGameMode : AGameModeBase
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SpawnActor(AWeatherManager);
    }
};