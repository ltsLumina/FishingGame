UCLASS(Abstract)
class UAbilityCondition : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User)
    {
        return true;
    }
};