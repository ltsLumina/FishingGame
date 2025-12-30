UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UFishCondition : UObject
{
    /**
     * Mutes this condition, making it always return false.
     * Useful for debugging purposes.
     */
    UPROPERTY(Category = "Debugging")
    bool Mute;

    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, UFishingComponent FishingComponent, UFishingHoleComponent FishingHole, ATimeManager TimeManager, AWeatherManager WeatherManager)
    {
        return true;
    }
};