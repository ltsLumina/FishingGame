class UFishingStateComponent : UActorComponent
{
	UPROPERTY(Category = "Fishing | State", VisibleAnywhere)
	bool IsFishing;

	/**
	 * Current time elapsed on the hook timer.
	 */
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
	FText CurrentFishingHoleName;

	UPROPERTY(Category = "Fishing | Area", VisibleAnywhere)
	TArray<TSubclassOf<AFish>> CurrentCatchableFish;

    /* Effects */

    UPROPERTY()
    float BiteTimerModifier = 1.0f;

	/* End */

	FTimerHandle MissedTimerHandle;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsFishing)
			return;

		if (BiteTimer > 0)
		{
			//Print("Hook timer: " + BiteTimer, 0.1f, FLinearColor::Green);

			BiteTimer -= DeltaSeconds;
			if (BiteTimer <= 0)
			{
				//Print("Hook proc! You have " + ReelTime + " seconds to catch the fish!", 2.5f);
				BiteTimer = 0;

                // Only runs once when the hook proc happens.
				if (!System::IsTimerActiveHandle(MissedTimerHandle))
                    BP_FishOnHook();

				MissedTimerHandle = System::SetTimer(this, n"Missed", ReelTime, false);
			}
		}

		FishOnHook = System::IsTimerActiveHandle(MissedTimerHandle);
	}

	UFUNCTION()
	void StartFishing()
	{
		if (IsFishing)
		{
			PrintWarning("You are already fishing!");
            StopFishing();
			return;
		}

		IsFishing = true;

		// Determine the fish that will bite when fishing starts
		CurrentFish = CurrentCatchableFish[Math::RandRange(0, CurrentCatchableFish.Num() - 1)].GetDefaultObject();
		BiteTimer = CurrentFish.BiteTime; // Fishing actually begins here (Tick will count down to hook proc)
        
		if (BiteTimerModifier != 1.0f)
        	BiteTimer *= BiteTimerModifier;

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

		Print(f"You caught a {CurrentFish.GetName()}!");
		FVector SpawnLocation = GetOwner().GetActorLocation() + GetOwner().GetActorForwardVector() * 100;
		SpawnFish_Server(CurrentFish.GetClass(), SpawnLocation);

		StopFishing();

		BP_Hook(CurrentFish);
		CurrentFish = nullptr;
	}

	UFUNCTION(NotBlueprintCallable, Server)
	void SpawnFish_Server(TSubclassOf<AFish> FishClass, FVector SpawnLocation)
	{
		auto Fish = SpawnActor(FishClass, SpawnLocation);
		Fish.SetLifeSpan(3);
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