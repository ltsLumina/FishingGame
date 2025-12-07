UCLASS(Abstract, EditInlineNew)
class UAbilityCondition : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, UFishingComponent FishingComponent)
    {
        return true;
    }
};