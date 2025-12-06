class AFishEntity : ACharacter
{
    default bReplicates = true;
    default bReplicateMovement = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        System::SetTimerForNextTick(this, "LatePlay");
    }

    UFUNCTION(NotBlueprintCallable)
    void LatePlay() { }
};