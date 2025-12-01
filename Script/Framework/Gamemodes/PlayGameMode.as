class AFishPlayGameMode : AGameModeBase
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SpawnManagers_Server();
    }

    UFUNCTION(Server)
    void SpawnManagers_Server()
    {
        SpawnActor(AWeatherManager);
        SpawnActor(ATimeManager);
    }
};