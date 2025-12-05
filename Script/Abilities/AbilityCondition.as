UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UAbilityCondition : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, UFishingStateComponent FishingState)
    {
        return true;
    }
};