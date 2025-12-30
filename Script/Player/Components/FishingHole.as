event void FOnSpectralShift();

UCLASS(ClassGroup="Fishing")
class UFishingHoleComponent : UActorComponent
{
	UPROPERTY(Category = "Fishing | Area", DisplayName = "Name")
	FText HoleName;
	default HoleName = FText::FromName(GetName());

	UPROPERTY(Category = "Fishing | Area")
	TArray<UFishItem> CatchableFish;

	UPROPERTY(Category = "Fishing | Area", VisibleInstanceOnly)
	bool IsSpectral;

	UPROPERTY(Category = "Events")
	FOnSpectralShift OnSpectralShift;

	APawn Character;
	UFishingComponent FishingComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimerForNextTick(this, "ValidateCatchableFish");
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
	void UpdateCatchableFish(UBait _)
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

	UFUNCTION(Meta=(AdvancedDisplay="bOverride", ReturnDisplayName="Success"))
	bool TrySpectralShift(UBait Bait, bool bOverride = false)
	{
		if (!bOverride && !Bait.IsSpectral)
			return false;

		if (bOverride)
		{
			IsSpectral = true;
			FishingComponent.UpdateCatchableFish();
			return true;
		}

		IsSpectral = RollPercentChance(Bait::GetSpectralChance(Bait));
		if (!IsSpectral) return false;

		FishingComponent.UpdateCatchableFish();
		Print("The fishing hole has spectral shifted!", 5.0f, FLinearColor::Purple);

		OnSpectralShift.Broadcast();
		BP_SpectralShift();

		return IsSpectral;
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpectralShift() { }
}