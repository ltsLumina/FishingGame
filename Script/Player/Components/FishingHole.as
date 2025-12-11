UCLASS(ClassGroup="Fishing")
class UFishingHoleComponent : UActorComponent
{
	UPROPERTY(Category = "Fishing | Area", DisplayName = "Name")
	FText HoleName;
	default HoleName = FText::FromName(GetName());

	UPROPERTY(Category = "Fishing | Area")
	TArray<TSubclassOf<AFish>> CatchableFish;

	APawn Character;
	UFishingComponent FishingComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimerForNextTick(this, "ValidateCatchableFish");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION(NotBlueprintCallable)
	void ValidateCatchableFish()
	{
		if (CatchableFish.Num() == 0)
		{
			PrintError(f"Fishing Hole {HoleName} has no catchable fish set!");
			return;
		}

		for (int i = 0; i < CatchableFish.Num(); i++)
		{
			if (CatchableFish[i] == nullptr)
			{
#if EDITOR
				PrintError(f"Fishing Hole {HoleName} ({GetOwner().GetActorLabel()}) has null entries in its catchable fish list!");
#endif
				CatchableFish.RemoveAt(i);
				return;
			}
		}
	}

	UFUNCTION()
	void Enter(AActor OtherActor)
	{
		Character = Cast<AFishCharacter>(OtherActor);
		if (Character == nullptr)
			return;

		FishingComponent = UFishingComponent::Get(Character);
		if (FishingComponent == nullptr)
			return;

		FishingComponent.OnSelectBait.AddUFunction(this, n"UpdateCatchableFish");

		FishingComponent.CurrentFishingHole = this;
		FishingComponent.UpdateCatchableFish();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCatchableFish(UBait Bait)
	{
		FishingComponent.UpdateCatchableFish();
	}

	UFUNCTION()
	void Exit(AActor OtherActor)
	{
		Character = Cast<AFishCharacter>(OtherActor);
		if (Character == nullptr)
			return;

		FishingComponent = UFishingComponent::Get(Character);
		if (FishingComponent == nullptr)
			return;

		FishingComponent.OnSelectBait.UnbindObject(this);

		FishingComponent.CurrentFishingHole = nullptr; 
		FishingComponent.UpdateCatchableFish();
	}
}