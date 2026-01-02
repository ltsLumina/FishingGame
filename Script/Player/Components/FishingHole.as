event void FOnSpectralShift();

UCLASS(ClassGroup = "Fishing")
class UFishingHoleComponent : UActorComponent
{
	UPROPERTY(Category = "Fishing | Area", DisplayName = "Name")
	FText HoleName;
	default HoleName = FText::FromName(GetName());

	UPROPERTY(Category = "Fishing | Area")
	TArray<UFishItem> CatchableFish;

	UPROPERTY(Category = "Fishing | Area")
	TArray<AFishCharacter> NearbyPlayers;

	UPROPERTY(Category = "Fishing | Area", VisibleInstanceOnly)
	bool IsSpectral;

	UPROPERTY(Category = "Fishing | Area", EditAnywhere)
	TArray<TSubclassOf<UTrait>> SpectralTraits;

	UPROPERTY(Category = "Events")
	FOnSpectralShift OnSpectralShift;

	AFishCharacter Character;
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

		NearbyPlayers.AddUnique(Character);

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

		if (IsSpectral)
		{
			Character.FishState.StatsComponent.ClearStatModification(n"SpectralCastSpeed");
			Character.FishState.StatsComponent.ClearStatModification(n"SpectralReelSpeed");
		}

		NearbyPlayers.RemoveSingleSwap(Character);

		FishingComponent.OnSelectBait.UnbindObject(this);

		FishingComponent.CurrentFishingHole = nullptr;
		FishingComponent.UpdateCatchableFish();
	}

	UFUNCTION(Meta = (AdvancedDisplay = "bOverride", ReturnDisplayName = "Success"))
	bool TrySpectralShift(UBait Bait, bool bOverride = false)
	{
		if (IsSpectral) // acts as a cooldown
			return false;

		if (!bOverride && !Bait.IsSpectral)
			return false;

		if (bOverride)
		{
			IsSpectral = true;
			FishingComponent.UpdateCatchableFish();
			
			Print("The fishing hole has spectral shifted!", 5.0f, FLinearColor::Purple);

			OnSpectralShift.Broadcast();
			BP_SpectralShift();
			return true;
		}

		IsSpectral = RollPercentChance(Bait::GetSpectralChance(Bait));
		if (!IsSpectral)
			return false;

		FishingComponent.UpdateCatchableFish();
		Print("The fishing hole has spectral shifted!", 5.0f, FLinearColor::Purple);

		OnSpectralShift.Broadcast();
		BP_SpectralShift();

		return IsSpectral;
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpectralShift()
	{}
}