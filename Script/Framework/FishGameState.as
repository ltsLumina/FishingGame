class AFishGameState : AGameStateBase
{
    UPROPERTY()
    EWeather CurrentWeather;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        
    }
};

enum EWeather
{
    Sunny,
    Rain,
    Clouds,
    Storm,
    Fog,
}