event void FOnSelectBait(UBait Bait);

class UFishingStateComponent : UActorComponent
{
	UPROPERTY(Category = "Fishing | State", VisibleAnywhere)
	bool IsFishing;

	UPROPERTY(VisibleAnywhere)
	UBait CurrentBait;

	/**
	 * Current time elapsed on the hook timer.
	 */
	// replicated so clients can read other players' timers
	UPROPERTY(Category = "Fishing | State", Meta = (Units = "s"), VisibleAnywhere)
	float BiteTimer = 0;

	/**
	 * The amount of time the player has to hook a fish once it bites (in seconds).
	 */
	UPROPERTY(Category = "Fishing | State", Meta = (Units = "s"))
	float ReelTime = 2.5f;

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
	AFishingHole CurrentFishingHole;

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

			CurrentCatchableFish.Add(FishClass);
		}
	}

	/* Effects */

	UPROPERTY()
	float BiteTimerModifier = 1.0f;

	/* Events */

	UPROPERTY()
	FOnSelectBait OnSelectBait;

	/* End */

	FTimerHandle MissedTimerHandle;

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!IsFishing)
            return;

        if (BiteTimer > 0)
        {
            BiteTimer -= DeltaSeconds;
            if (BiteTimer <= 0)
            {
                BiteTimer = 0;

                // Only runs once when the hook proc happens.
                if (!System::IsTimerActiveHandle(MissedTimerHandle))
                    BP_FishOnHook();

                MissedTimerHandle = System::SetTimer(this, n"Missed", ReelTime, false);
            }
        }

        FishOnHook = System::IsTimerActiveHandle(MissedTimerHandle);
    }

	/**
	 * AKA "Cast"
	 */
	UFUNCTION()
	void StartFishing()
	{
		if (CurrentFishingHole == nullptr)
		{
			PrintWarning("You are not in a fishing area!", 1.5f);
			return;
		}

		if (IsFishing)
		{
			PrintWarning("You are already fishing!", 1.5f);
			StopFishing();
			return;
		}

		IsFishing = true;

		// TODO: Default to 3 seconds. If no fish are available, it automatically fails after this time.
		float NewBiteTimer = MAX_uint16;

		if (CurrentBait == nullptr)
		{
			PrintWarning("You must equip bait to fish!", 1.5f);
		}
		else if (CurrentCatchableFish.Num() == 0)
		{
			PrintWarning("There are no fish to catch here with your current bait!", 1.5f);

			// TODO: make it like xiv
			// System::SetTimer(this, n"NoFishAvailable", NewBiteTimer, false);
		}
		else
		{
			// Determine the fish that will bite when fishing starts
			CurrentFish = CurrentCatchableFish[Math::RandRange(0, CurrentCatchableFish.Num() - 1)].GetDefaultObject();
			NewBiteTimer = CurrentFish.BiteTime;

			if (BiteTimerModifier != 1.0f)
				NewBiteTimer *= BiteTimerModifier;
		}

		BiteTimer = NewBiteTimer;
		BP_StartFishing();
	}

	UFUNCTION()
	void StopFishing()
	{
		if (!IsFishing)
			return;

		IsFishing = false;

		CurrentFish = nullptr;
		BiteTimer = 0;
		BiteTimerModifier = 1.0f;

		System::ClearAndInvalidateTimerHandle(MissedTimerHandle);

		BP_StopFishing();
	}

	UFUNCTION()
	void Hook()
	{
		if (!IsFishing)
		{
			PrintWarning("You are not fishing!");
			return;
		}

		if (!FishOnHook)
		{
			Print("Hooked too soon! You missed the fish.");
			StopFishing();
			return;
		}

		FVector SpawnLocation = GetOwner().GetActorLocation() + GetOwner().GetActorForwardVector() * 100;
		SpawnFish_Server(CurrentFish.GetClass(), SpawnLocation);

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
		Print("You failed to catch the fish...");
		IsFishing = false;

		BiteTimer = 0;

		BP_Missed(CurrentFish);
		CurrentFish = nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	void NoFishAvailable()
	{
		Print("There are no fish to catch here with your current bait!");
		IsFishing = false;

		BiteTimer = 0;
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