UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UAbilityCondition : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User)
    {
        return true;
    }
};