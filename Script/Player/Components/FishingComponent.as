event void FOnStateChange(EFishingState NewState);
event void FOnSelectBait(UBait Bait);
event void FOnFishHooked(UFishItem FishItem, UBait Bait, UFishingHoleComponent FishingHole);
event void FOnFishCaught(AFish Fish, UBait Bait, UFishingHoleComponent FishingHole);

class UFishingComponent : UFishComponentBase
{
	UPROPERTY(Category = "Fishing | State", VisibleAnywhere, BlueprintReadOnly)
	EFishingState CurrentState = EFishingState::NotFishing;

	UPROPERTY(Category = "Fishing | State", VisibleAnywhere, BlueprintGetter = "GetIsFishing")
	bool IsFishing;

	UFUNCTION(BlueprintPure)
	bool GetIsFishing()
	{
		return CurrentState == EFishingState::Fishing;
	}

	UPROPERTY(Category = "Fishing | State", EditDefaultsOnly, VisibleInstanceOnly)
	UBait CurrentBait;

	/**
	 * Current time elapsed on the hook timer.
	 */
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

	UPROPERTY(Category = "Fishing | State", VisibleInstanceOnly)
	TArray<TSubclassOf<UFishCondition>> CurrentIgnoredConditions;

	UPROPERTY(Category = "Fishing | State", VisibleAnywhere)
	TArray<UFishItem> MoochedFish;

	UPROPERTY(Category = "Fishing | State", VisibleAnywhere, BlueprintGetter = "GetHasMoochOpportunity")
	bool HasMoochOpportunity;

	UFUNCTION(BlueprintPure)
	bool GetHasMoochOpportunity()
	{
		return CurrentMoochableFish != nullptr;
	}

	/**
	 * The fish that is currently hooked.
	 * Determined when fishing starts.
	 */
	UPROPERTY(VisibleInstanceOnly)
	UFishItem CurrentFish;

	/**
	 * Whether the player currently has an opportunity to catch a fish. (MissedTimerHandle is active)
	 */
	UPROPERTY(VisibleInstanceOnly)
	bool FishOnHook;

	/* Area */

	UPROPERTY(Category = "Fishing | Area", NotVisible, ToolTip = "The fishing hole the player is currently in.")
	UFishingHoleComponent CurrentFishingHole;

	/**
	 * Considers a wide range of factors (bait, conditions, etc.) to determine which fish can currently be caught.
	 */
	UPROPERTY(Category = "Fishing | Area", VisibleAnywhere)
	TArray<UFishItem> CurrentCatchableFish;

	UPROPERTY(VisibleInstanceOnly)
	UFishItem CurrentMoochableFish;

	UPROPERTY(VisibleInstanceOnly)
	UFishItem PreviouslyCaughtFish;

	UPROPERTY()
	FCatchContext CatchContext;

	/* Events */

	UPROPERTY(Category = "Events")
	FOnStateChange OnStateChange;

	UPROPERTY(Category = "Events")
	FOnSelectBait OnSelectBait;

	/**
	 * Called after the fish has been hooked, but before the reeling-in process begins.
	 */
	UPROPERTY(Category = "Events")
	FOnFishHooked OnFishHooked;

	/**
	 * Called after the fish has been spawned on the client, but before it is added to the player's inventory.
	 */
	UPROPERTY(Category = "Events")
	FOnFishCaught OnFishCaught;

	/* End */

	FTimerHandle MissedTimerHandle;

	ATimeManager TimeManager;
	AWeatherManager WeatherManager;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime) override
	{
		TimeManager = Gameplay::GetActorOfClass(ATimeManager);
		WeatherManager = Gameplay::GetActorOfClass(AWeatherManager);

		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);
	}

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
				SetState(EFishingState::FishOnHook);
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

	UFUNCTION(Category = "Fishing")
	void SetState(EFishingState NewState)
	{
		CurrentState = NewState;
		OnStateChange.Broadcast(NewState);
	}

	void UpdateCatchableFish(UFishingHoleComponent Hole)
	{
		if (Character == nullptr || TimeManager == nullptr || WeatherManager == nullptr)
			return;

		CurrentCatchableFish.Empty();

		CurrentFishingHole = Hole;
		if (CurrentFishingHole == nullptr) return;

		for (auto& FishItem : CurrentFishingHole.CatchableFish)
		{
			auto LoadedFishItem = System::LoadAsset_Blocking(FishItem);
			auto Data = LoadedFishItem.FishData;

			if (CurrentBait == nullptr)
				continue;

			if (!Data.PreferredBaits.Contains(CurrentBait))
				continue;

			// if (Data.MinimumGathering > Stats::GetStats(Character).Gathering || Data.MinimumPerception > Stats::GetStats(Character).Perception)
			// continue;

			for (UFishCondition Condition : Data.Conditions)
			{
				if (Condition.Mute)
					continue;

				if (Condition == nullptr)
				{
					throw(f"Fish {LoadedFishItem.GetItemName()} has a null FishCondition!");
					continue;
				}
				if (CurrentIgnoredConditions.Contains(Condition.GetClass()))
				{
					Print(f"An ability is ignoring condition: {Condition.Name} for fish: {LoadedFishItem.BaseData.ItemName}", 0.0f, FLinearColor::Yellow);
					continue;
				}
				if (!Condition.IsSatisfied(Character, this, CurrentFishingHole, TimeManager, WeatherManager))
				{
					PrintWarning(f"{Condition.Name} not satisfied for fish: {LoadedFishItem.BaseData.ItemName}", 0.0f);
					return;
				}
			}

			CurrentCatchableFish.Add(LoadedFishItem);
			for (auto Item : CurrentCatchableFish)
			{
				if (Item.FishData.Rarity > EFishRarity::Prismatic)
				{
					Print(f"A rare \"{Item.BaseData.ItemName}\" is available!", 0.0f, FLinearColor::Green);
				}
			}
		}
	}

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

		SetState(EFishingState::Fishing);

		// If no fish are available, it automatically fails after this time.
		float NewBiteTimer = 3;

		if (CurrentBait == nullptr)
		{
			PrintWarning("Fishing without any bait!", 1.5f);
			MissedTimerHandle = System::SetTimer(this, n"StopFishing", 5, false);
		}
		else if (CurrentCatchableFish.Num() == 0)
		{
			PrintWarning("There are no fish to catch here! (Bait and/or Conditions Failed!)", 2.5f);
			MissedTimerHandle = System::SetTimer(this, n"StopFishing", 5, false);
		}
		else
		{
			CurrentFish = SelectFishWeighted(CurrentCatchableFish);
			NewBiteTimer = CurrentFish.FishData.BiteTime;

			// TODO: should be reworked in tandem with Token System
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
		Server_PlayCastMontage();
	}

	UFUNCTION(Category = "Fishing", CallInEditor)
	void StopFishing()
	{
		SetState(EFishingState::NotFishing);

		CurrentFish = nullptr;

		BiteTimer = 0;
		BiteTimeModifiers.Empty();

		System::ClearAndInvalidateTimerHandle(MissedTimerHandle);

		BP_StopFishing();
		Server_StopCastMontage();
	}

	UFUNCTION(Category = "Fishing", CallInEditor)
	void Hook()
	{
		if (CurrentBait == nullptr)
		{
			PrintWarning("You have no bait equipped!", 2.5f, FLinearColor::Yellow);
			Missed();
			return;
		}

		if (CurrentState == EFishingState::Fishing)
		{
			Print("Hooked too soon!", 2.5f, FLinearColor::Yellow);
			Missed();
			return;
		}

		FFishItemData Data = CurrentFish.FishData;

		float GatheringStat;
		Stats::GetStat(Character, GameplayTags::Stat_Fishing_Gathering, false, GatheringStat);
		float GatheringDiff = Math::Max(0.0f, GatheringStat - Data.MinimumGathering);
		float CurrentCatchRate = Math::Clamp(Data.CatchRate + GatheringDiff * 0.5f, 0.0f, 100.0f);

		// Chance to escape - uses Catch Rate 0-100
		float CatchRoll = Math::RandRange(0.0f, 100.0f);
		if (CatchRoll > CurrentCatchRate)
		{
			Print("The fish escaped your hook!", 2.5f, FLinearColor::Yellow);
			Missed();
			return;
		}

		// by this point, the fish is successfully hooked

		if (CurrentFish != nullptr)
		{
			if (Data.Rarity > EFishRarity::Aetherial && UAbilityHandlerComponent::Get(Character).HasAbilityByName("Thaliak's Favor"))
			{
				Print(f"You've hooked a rare \"{CurrentFish.BaseData.ItemName}\"!\nA stack of Angler's Art has been granted.", 3, FLinearColor::Green);
				PlayerState.TokenComponent.AddToken(GameplayTags::Token_Ability_AnglersArt);
			}
		}

		if (Data.IsMoochable)
		{
			CurrentMoochableFish = CurrentFish;
		}
		else
		{
			CurrentMoochableFish = nullptr;
			MoochedFish.Empty();
		}

		// Store locally before StopFishing clears 'CurrentFish'
		UFishItem CaughtFish = CurrentFish;
		PreviouslyCaughtFish = CurrentFish;
		StopFishing();

		OnFishHooked.Broadcast(CaughtFish, CurrentBait, CurrentFishingHole);
		BP_Hook(CaughtFish);
		Server_PlayHookMontage(CaughtFish);
	}

	UFUNCTION()
	void Missed()
	{
		if (CurrentState == EFishingState::NotFishing)
			return;

		MoochedFish.Empty();

		Print("The fish got away!", 2.5f, FLinearColor::Yellow);
		BP_Missed(CurrentFish);
		StopFishing();
	}

	/**
	 * Selects a fish to be caught using weighted random selection based on fish rarity.
	 */
	UFishItem SelectFishWeighted(TArray<UFishItem>& Fishes)
	{
		UFishItem ResultFish = nullptr;

		// Determine the fish that will bite when fishing starts
		// Weighted random selection using AFish::GetCatchRate(Rarity) -> 0..100
		float TotalWeight = 0.0f;
		for (auto& FishItem : Fishes)
		{
			float Weight = Fish::GetRarityWeight(FishItem);
			if (Weight < 0.0f)
				Weight = 0.0f;
			TotalWeight += Weight;
		}

		// Fallback to uniform random if something went wrong or all weights are zero
		if (TotalWeight <= 0.0f)
		{
			Print("All fish have zero catch rate weights; selecting uniformly at random.", 2.5f, FLinearColor::Yellow);
			ResultFish = Fishes[Math::RandRange(0, Fishes.Num() - 1)];
			return ResultFish;
		}
		else
		{
			float Roll = Math::RandRange(0.0f, TotalWeight);
			float Accum = 0.0f;
			for (auto& FishItem : Fishes)
			{
				float Weight = Fish::GetRarityWeight(FishItem);
				if (Weight < 0.0f)
					Weight = 0.0f;
				Accum += Weight;
				if (Roll <= Accum)
				{
					ResultFish = FishItem;
					return ResultFish;
				}
			}
		}

		return ResultFish;
	}

	UFUNCTION(Server)
	void SpawnFish_Server(TSubclassOf<AFish> FishClass, UFishItem FishItem)
	{
		FVector SpawnLocation = GetOwner().GetActorLocation() + GetOwner().GetActorForwardVector() * 100;
		auto Fish = SpawnActor(FishClass, SpawnLocation);
		Fish.SetLifeSpan(3);
		Fish.SetOwner(GetOwner());

		Fish.OnSpawn(FishItem);
		Fish.OnCaught(Cast<AFishCharacter>(GetOwner()));

		SpawnFish_Client(FishClass, FishItem);
	}

	UFUNCTION(Client)
	void SpawnFish_Client(TSubclassOf<AFish> FishClass, UFishItem FishItem)
	{
		FVector SpawnLocation = GetOwner().GetActorLocation() + GetOwner().GetActorForwardVector() * 100;
		AFish Fish = SpawnActor(FishClass, SpawnLocation);
		Fish.SetActorHiddenInGame(true); // The locally spawned fish is just for data purposes; the server-spawned one is used for visuals.
		Fish.SetLifeSpan(3);
		Fish.SetOwner(GetOwner());

		Fish.OnSpawn(FishItem);
		OnFishCaught.Broadcast(Fish, CurrentBait, CurrentFishingHole);

		for (int i = 0; i < CatchContext.Quantity; i++)
		{
			FInventoryInstanceData InventoryInstance;
			InventoryInstance.FishInstanceData = Fish::InstanceData::MakeFishInstanceData(FishItem.FishData); // create new instance data for each fish, so they aren't identical. The Clone trait adds a fish to the inventory with identical instance data instead.

			PlayerState.InventoryComponent.AddItem(Fish.Item, InventoryInstance, 1);
		}

		CatchContext = FCatchContext();
	}

	// #region RPCs

	// cast

	UFUNCTION(Server)
	void Server_PlayCastMontage()
	{
		Multicast_PlayCastMontage();
	}

	UFUNCTION(BlueprintEvent, NetMulticast, NotBlueprintCallable)
	void Multicast_PlayCastMontage()
	{}

	UFUNCTION(Server)
	void Server_StopCastMontage()
	{
		Multicast_StopCastMontage();
	}

	UFUNCTION(BlueprintEvent, NetMulticast, NotBlueprintCallable)
	void Multicast_StopCastMontage()
	{}

	// hook

	UFUNCTION(Server)
	void Server_PlayHookMontage(UFishItem FishItem)
	{
		Multicast_PlayHookMontage(FishItem);
	}

	UFUNCTION(BlueprintEvent, NetMulticast, NotBlueprintCallable)
	void Multicast_PlayHookMontage(UFishItem FishItem)
	{}

	UFUNCTION(Server)
	void Server_StopHookMontage()
	{
		Multicast_StopHookMontage();
	}

	UFUNCTION(BlueprintEvent, NetMulticast, NotBlueprintCallable)
	void Multicast_StopHookMontage()
	{}
	// #endregion

	// #region BP Events
	UFUNCTION(BlueprintEvent, DisplayName = "Start Fishing")
	void BP_StartFishing()
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Stop Fishing")
	void BP_StopFishing()
	{}

	/**
	 * Called when a fish is successfully hooked and the player begins reeling it in.
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Hook")
	void BP_Hook(UFishItem CaughtFish)
	{}

	UFUNCTION(BlueprintEvent, DisplayName = "Missed Fish")
	void BP_Missed(UFishItem MissedFish)
	{}

	/**
	 * Called when a fish bites the hook.
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Fish On Hook")
	void BP_FishOnHook()
	{}
	// #endregion

	// #region Helpers
	UFUNCTION(BlueprintPure, Category = "Fishing", DisplayName = "Is State")
	bool IsState(EFishingState StateToCheck)
	{
		return CurrentState == StateToCheck;
	}

	UFUNCTION(BlueprintPure, Category = "Fishing", DisplayName = "Is State")
	bool IsAnyState(TArray<EFishingState> StatesToCheck)
	{
		return StatesToCheck.Contains(CurrentState);
	}

	UFUNCTION(Category = "Fishing", Meta = (ExpandBoolAsExecs = "ReturnValue"), DisplayName = "Is State (branch)")
	bool IsState_Branch(TArray<EFishingState> StatesToCheck)
	{
		return StatesToCheck.Contains(CurrentState);
	}
	// #endregion
};

struct FCatchContext
{
	UPROPERTY()
	UFishItem FishItem;

	UPROPERTY()
	int Quantity = 1;
}

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