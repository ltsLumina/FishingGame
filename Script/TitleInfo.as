class UTitles : UPrimaryDataAsset
{
    UPROPERTY(EditInline)
    TMap<FString, UTitleCondition> Titles;
}

UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UTitleCondition : UObject
{
    /**
     * Auto unlocks this condition, making it always return true.
     * Useful for debugging purposes.
     */
    UPROPERTY(Category = "Debugging")
    bool AutoUnlock;

    UFUNCTION(BlueprintEvent)
    bool IsSatisfied(AFishCharacter Character, AFishPlayerState PlayerState, AFish Fish)
    {
        return true;
    }
};