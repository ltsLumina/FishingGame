UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UAbilityCondition : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, UFishingComponent FishingComponent)
    {
        return true;
    }
};