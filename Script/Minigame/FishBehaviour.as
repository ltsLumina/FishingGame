UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UMinigameFishBehaviour : UObject
{
    UFUNCTION(BlueprintEvent)
    void Execute()
    {

    }

    UPROPERTY()
    float InterpSpeed;
}