class UParameterBar : UActorComponent
{
    UPROPERTY(Category = "Parameter Bar", VisibleAnywhere)
    float MP = 500;

    UPROPERTY(Category = "Parameter Bar", VisibleAnywhere)
    float MaxMP = 500;

    UPROPERTY(Category = "Parameter Bar", EditAnywhere)
    float RegenerationRate = 5.0f;

    UPROPERTY(Category = "Parameter Bar", VisibleAnywhere, Meta=(Units="s"))
    FTimespan TimeTillFullMP;

    UFishingStateComponent FishingState;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        MP = MaxMP;

        FishingState = UFishingStateComponent::Get(GetOwner());
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (MP >= MaxMP)
            return;

        MP = Math::Min(MP + DeltaSeconds * RegenerationRate, MaxMP);

        float TimeToFullSeconds = (MaxMP - MP) / RegenerationRate;
        TimeTillFullMP = FTimespan::FromSeconds(TimeToFullSeconds);
    }
};