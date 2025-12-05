UCLASS(Abstract, EditInlineNew, DefaultToInstanced, Meta=(BlueprintSpawnableComponent, DuplicateTransient))
class UFishCondition : UObject
{
    /**
     * Mutes this condition, making it always return false.
     * Useful for debugging purposes.
     */
    UPROPERTY(Category = "Debugging")
    bool Mute;

    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, UFishingStateComponent FishingState, ATimeManager TimeManager, AWeatherManager WeatherManager)
    {
        return true;
    }
};