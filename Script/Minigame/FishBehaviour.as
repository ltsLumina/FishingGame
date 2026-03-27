UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UMinigameFishBehaviour : UObject
{
    UPROPERTY(BlueprintReadOnly)
    float Speed;

    UFUNCTION(BlueprintEvent)
    void Execute()
    {

    }
}