UCLASS(Abstract)
class AFishingHole : AActor
{
    UPROPERTY(Category = "Fishing | Area", DisplayName = "Name")
    FText HoleName;
    default HoleName = FText::FromName(GetName());

    UPROPERTY(Category = "Fishing | Area")
    TArray<TSubclassOf<AFish>> CatchableFish;

    APawn PlayerPawn;
    UFishingStateComponent FishingState;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (CatchableFish.Num() == 0)
        {
            PrintError(f"Fishing Hole {HoleName} has no catchable fish set!");
            return;
        }
    }
    
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        PlayerPawn = Cast<APawn>(OtherActor);
        if (PlayerPawn == nullptr)
            return;

        FishingState = UFishingStateComponent::Get(PlayerPawn);
        if (FishingState == nullptr)
            return;

        FishingState.OnSelectBait.AddUFunction(this, n"UpdateCatchableFish");

        FishingState.CurrentFishingHole = this;
        FishingState.UpdateCatchableFish();
    }

    UFUNCTION(NotBlueprintCallable)
    void UpdateCatchableFish(UBait Bait)
    {
        FishingState.UpdateCatchableFish();
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        PlayerPawn = Cast<APawn>(OtherActor);
        if (PlayerPawn == nullptr)
            return;

        FishingState = UFishingStateComponent::Get(PlayerPawn);
        if (FishingState == nullptr)
            return;

        FishingState.OnSelectBait.UnbindObject(this);

        FishingState.CurrentFishingHole = nullptr;
        FishingState.UpdateCatchableFish();
    }
}