class AWeatherManager : AActor
{
    UPROPERTY(Category = "Weather")
    EWeather CurrentWeather = EWeather::ClearSkies;

    UPROPERTY(Category = "Weather")
    EWeather PreviousWeather = EWeather::ClearSkies;

    UPROPERTY(Category = "Weather", VisibleAnywhere)
    EWeather NextWeather;

    UFUNCTION()
    void TransitionTo(EWeather NewWeather)
    {
        PreviousWeather = CurrentWeather;
        CurrentWeather = NewWeather;
        
        // Logic for transitioning effects can be added here
    }
};

enum EWeather
{
    // Clear / pleasant
    ClearSkies,
    FairSkies,

    // Cloudiness / low visibility
    Cloudy,
    Fog,
    Gloom,

    // Precipitation (light to heavy)
    Showers,
    Rain,
    Snow,
    Thunder,
    Thunderstorms,

    // Wind-related
    Wind,
    Gales,

    // Extreme / particulate / regional
    DustStorms,
    HeatWaves,

    // Special / umbral / lunar
    MoonDust,
    UmbralStatic,
    UmbralWind,
}