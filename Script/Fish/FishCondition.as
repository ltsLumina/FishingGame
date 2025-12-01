UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UFishCondition : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, ATimeManager TimeManager, AWeatherManager WeatherManager)
    {
        return true;
    }
};