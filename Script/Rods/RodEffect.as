UCLASS(Abstract, EditInlineNew)
class URodEffect : UObject
{
    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter User, UFishingComponent FishingComponent, UFishingRod Rod)
    {
        return true;
    }
};