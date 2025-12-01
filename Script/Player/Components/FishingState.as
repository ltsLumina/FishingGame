event void FOnSelectBait(UBait Bait);

class UFishingStateComponent : UActorComponent
{
	UPROPERTY(Category = "Fishing | State", VisibleAnywhere)
	EFishingState CurrentState = EFishingState::NotFishing;

	UPROPERTY(Category = "Fishing | State", VisibleAnywhere, BlueprintGetter = "GetIsFishing")
	bool IsFishing;

	UFUNCTION(BlueprintPure)
	bool GetIsFishing()
	{
		return CurrentState == EFishingState::Fishing;
	}

	UPROPERTY(VisibleAnywhere)
	UBait CurrentBait;

	/**
	 * Current time elapsed on the hook timer.
	 */
	// replicated so clients can read other players' timers
	UPROPERTY(Category = "Fishing | State", Meta = (Units = "s"), VisibleAnywhere)
	float BiteTimer = 0;

	/**
	 * This modifier affects the time it takes for a fish to bite when fishing starts.
	 * Expects a float multiplier in decimal form (e.g., 0.9 for a 10% reduction, or 1.2 for a 20% increase).
	 * Now keyed by name so you can identify each modifier (e.g. "QuickCast" = 0.9).
	 */
	UPROPERTY(Category = "Fishing | State", VisibleAnywhere)
	TMap<FName, float> BiteTimeModifiers;

	/**
	 * The amount of time the player has to hook a fish once it bites (in seconds).
	 */
	UPROPERTY(Category = "Fishing | State", Meta = (Units = "s"))
	float TimeToReelIn = 2.5f;

	/**
	 * The fish that is currently hooked.
	 * Determined when fishing starts.
	 */
	UPROPERTY(VisibleAnywhere)
	AFish CurrentFish;

	/**
	 * Whether the player currently has an opportunity to catch a fish. (MissedTimerHandle is active)
	 */
	UPROPERTY(VisibleAnywhere)
	bool FishOnHook;

	/* Area */

	UPROPERTY(Category = "Fishing | Area", VisibleAnywhere)
	UFishingHoleComponent CurrentFishingHole;

	/**
	 * Considers the fishing hole the player is currently in, and the bait they are using, to determine which fish can be caught.
	 */
	UPROPERTY(Category = "Fishing | Area", VisibleAnywhere)
	TArray<TSubclassOf<AFish>> CurrentCatchableFish;

	void UpdateCatchableFish()
	{
		CurrentCatchableFish.Empty();

		if (CurrentFishingHole == nullptr)
			return;

		for (TSubclassOf<AFish> FishClass : CurrentFishingHole.CatchableFish)
		{
			auto FishDefault = FishClass.GetDefaultObject();
			if (CurrentBait != nullptr && !FishDefault.RequiredBaits.Contains(CurrentBait))
				continue;

			for (UFishCondition Condition : FishDefault.Conditions) 
			{
				if (Condition == nullptr) 
				{
					throw(f"Fish {FishClass.DefaultObject.GetName()} has a null FishCondition!");
					continue;
				}
				if (!Condition.IsSatisfied(Cast<AFishCharacter>(GetOwner()), Gameplay::GetActorOfClass(ATimeManager), Gameplay::GetActorOfClass(AWeatherManager)))
				{
					PrintWarning(f"{Condition.Name} not satisfied for fish: " + FishClass.DefaultObject.ActorNameOrLabel, 0.01f);
					return;
				}
				
			}

			CurrentCatchableFish.Add(FishClass);
		}
	}

	/* Events */

	UPROPERTY()
	FOnSelectBait OnSelectBait;

	/* End */

	FTimerHandle MissedTimerHandle;

	UPROPERTY(NotVisible)
	UFishingHoleComponent DefaultFishingHole;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Initialize CurrentFishingHole to avoid null checks later
		DefaultFishingHole = UFishingHoleComponent::Create(GetOwner());
		DefaultFishingHole.HoleName = FText::FromString("None");
		DefaultFishingHole.CatchableFish.Add(AJunk);

		CurrentFishingHole = DefaultFishingHole;

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BP_Tick(DeltaSeconds);

		if (!GetIsFishing())
			return;

		if (BiteTimer > 0)
		{
			BiteTimer -= DeltaSeconds;
			if (BiteTimer <= 0)
			{
				CurrentState = EFishingState::FishOnHook;
				BiteTimer = 0;

				// Only runs once when the hook proc happens.
				if (!System::IsTimerActiveHandle(MissedTimerHandle) && CurrentFish != nullptr)
					BP_FishOnHook(); // Shows the Hook Notification in Blueprints.

				MissedTimerHandle = System::SetTimer(this, n"Missed", TimeToReelIn, false);
			}
		}

		FishOnHook = System::IsTimerActiveHandle(MissedTimerHandle);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick(float DeltaSeconds)
	{}

	/**
	 * AKA "Cast"
	 */
	UFUNCTION(Category = "Fishing", CallInEditor)
	void StartFishing()
	{
		if (CurrentFishingHole == nullptr)
		{
			PrintWarning("You are not in a fishing area!", 1.5f);
			return;
		}

		if (GetIsFishing())
		{
			PrintWarning("You are already fishing!", 1.5f);
			StopFishing();
			return;
		}

		CurrentState = EFishingState::Fishing;

		// If no fish are available, it automatically fails after this time.
		float NewBiteTimer = 3;

		if (CurrentBait == nullptr)
		{
			PrintWarning("Fishing without any bait!", 1.5f);
			System::SetTimer(this, n"StopFishing", 3, false);
		}
		else if (CurrentCatchableFish.Num() == 0)
		{
			PrintWarning("There are no fish to catch here! (Bait and/or Conditions Failed!)", 2.5f);
			System::SetTimer(this, n"StopFishing", 3, false);
		}
		else
		{
			// Determine the fish that will bite when fishing starts
			CurrentFish = CurrentCatchableFish[Math::RandRange(0, CurrentCatchableFish.Num() - 1)].GetDefaultObject();
			NewBiteTimer = CurrentFish.BiteTime;

			for (auto Pair : BiteTimeModifiers)
			{
				float Modifier = Pair.Value;
				FName ModifierKey = Pair.Key;

				if (Modifier <= 0)
				{
					PrintError(f"Bite time modifier ({ModifierKey.PlainNameString}) values must be greater than 0");
					continue;
				}

				if (Modifier > 2.0f) // arbitrary upper limit to prevent extreme values
				{
					PrintError(f"Bite time modifier ({ModifierKey.PlainNameString}) values must be 2.0 or less");
					continue;
				}

				NewBiteTimer *= Modifier;
				Print(f"Bite time modified by {Modifier}x (\"{ModifierKey}\")");
			}
		}

		BiteTimer = NewBiteTimer;
		BP_StartFishing();
	}

	UFUNCTION(Category = "Fishing", CallInEditor)
	void StopFishing()
	{
		CurrentState = EFishingState::NotFishing;

		CurrentFish = nullptr;
		BiteTimer = 0;
		BiteTimeModifiers.Empty();

		System::ClearAndInvalidateTimerHandle(MissedTimerHandle);

		BP_StopFishing();
	}

	UFUNCTION(Category = "Fishing", CallInEditor)
	void Hook()
	{
		if (CurrentState == EFishingState::Fishing)
		{
			Print("Hooked too soon!", 2.5f, FLinearColor::Yellow);
			Missed();
			return;
		}

		// Chance to escape
		float EscapeRoll = Math::RandRange(0.0f, 100.0f);
		if (EscapeRoll < CurrentFish.EscapeChance)
		{
			Print("The fish escaped your hook!", 2.5f, FLinearColor::Yellow);
			Missed();
			return;
		}

		CurrentState = EFishingState::ReelingIn;  // only true while the animation plays
		CurrentState = EFishingState::CaughtFish; // will be set by animation notify in the future

		if (CurrentFish != nullptr)
		{
			FVector SpawnLocation = GetOwner().GetActorLocation() + GetOwner().GetActorForwardVector() * 100;
			SpawnFish_Server(CurrentFish.GetClass(), SpawnLocation);
		}

		StopFishing();

		BP_Hook(CurrentFish);
	}

	UFUNCTION(NotBlueprintCallable, Server)
	AFish SpawnFish_Server(TSubclassOf<AFish> FishClass, FVector SpawnLocation)
	{
		auto Fish = SpawnActor(FishClass, SpawnLocation);
		Fish.SetLifeSpan(3);

		Fish.OnCaught(Cast<AFishCharacter>(GetOwner()));

		return Fish;
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Hook Fish")
	void BP_Hook(AFish CaughtFish)
	{}

	UFUNCTION(NotBlueprintCallable)
	void Missed()
	{
		Print("The fish got away!", 2.5f, FLinearColor::Yellow);
		BP_Missed(CurrentFish);
		StopFishing();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Missed Fish")
	void BP_Missed(AFish MissedFish)
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Start Fishing")
	void BP_StartFishing()
	{
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Stop Fishing")
	void BP_StopFishing()
	{
	}

	/**
	 * Called when a fish bites the hook.
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Fish On Hook")
	void BP_FishOnHook()
	{}
};

enum EFishingState
{
	/**
	 * The player is not fishing.
	 */
	NotFishing,
	/**
	 * The player is waiting for a fish to bite.
	 */
	Fishing,
	/**
	 * A fish has bitten the hook, and the player must reel it in within a time limit.
	 */
	FishOnHook,
	/**
	 * The player is reeling in a caught fish (animation-driven)
	 */
	ReelingIn,
	/**
	 * The player has successfully caught a fish (also animation-driven)
	 */
	CaughtFish
}