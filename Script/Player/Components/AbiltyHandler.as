event void FOnAbilityGranted(UAbilityData AbilityData);
event void FOnAbilityRevoked(UAbilityData AbilityData);

class UAbilityHandlerComponent : UFishComponentBase
{
	UPROPERTY(Category = "Abilities", VisibleInstanceOnly, BlueprintReadOnly)
	TArray<UAbilityData> Abilities;

	UPROPERTY(Category = "Abilities", EditDefaultsOnly, BlueprintReadOnly)
	UDataTable AbilityUnlockTable;

	UPROPERTY(Category = "Abilities | Events")
	FOnAbilityGranted OnAbilityGranted;

	UPROPERTY(Category = "Abilities | Events")
	FOnAbilityRevoked OnAbilityRevoked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Abilities.Empty();

		TArray<FAbilityUnlockInfo> UnlockInfos;
		AbilityUnlockTable.GetAllRows(UnlockInfos);
		check(UnlockInfos.Num() > 0, "AbilityUnlockTable has no rows!");
		check(UnlockInfos[0].Ability != nullptr, "AbilityUnlockTable has invalid AbilityData references! (IT CLEARED ITSELF AGAINNNNNNNNNNNNNNNNNNN)");
		
		for (FAbilityUnlockInfo Info : UnlockInfos)
		{
			if (Info.UnlockLevel <= 1) // Starting abilities
			{
				UAbilityData AbilityData = Info.Ability;
				GrantAbility(AbilityData);
			}
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	void LatePlay() override
	{
		Super::LatePlay();
		BP_LatePlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay() {}

	UFUNCTION(NotBlueprintCallable)
	void InvokeAbility(UAbilityData Ability)
	{
		//Print("Ability invoked: " + Ability.GetName());

		Invoke(Ability);
	}

	void Invoke(UAbilityData AbilityData)
	{
		Print(f"used {AbilityData.Details.Name}", 0.75f, FLinearColor::Yellow);
		auto Ability = NewObject(this, AbilityData.AbilityClass);
		if (Ability != nullptr)
		{
			auto Instigator = Cast<AFishCharacter>(GetOwner());
			auto FishingComponent = UFishingComponent::Get(Instigator);
			Ability.Execute(AbilityData, Instigator, FishingComponent);
		}
		else
		{
			PrintError("Failed to create ability object for: " + AbilityData.Details.Name);
		}
	}

	UFUNCTION(Category = "Abilities")
	void GrantAbility(UAbilityData AbilityData)
	{
		if (!Abilities.Contains(AbilityData))
		{
			Abilities.Add(AbilityData);
			OnAbilityGranted.Broadcast(AbilityData);
			Print("Granted ability: " + AbilityData.Details.Name.ToString(), 3.0f, FLinearColor::Green);
		}
	}

	UFUNCTION(Category = "Abilities")
	void RevokeAbility(UAbilityData AbilityData)
	{
		if (Abilities.Contains(AbilityData))
		{
			Abilities.Remove(AbilityData);
			OnAbilityRevoked.Broadcast(AbilityData);
			Print("Revoked ability: " + AbilityData.Details.Name.ToString(), 3.0f, FLinearColor::Red);
		}
	}

	UFUNCTION(Category = "Save Game")
	bool SaveAbilities()
	{
		auto SaveGame = NewObject(this, UAbilitySaveGame);
		TArray<FAbilityUnlockInfo> UnlockedAbilities;
		if (AbilityUnlockTable != nullptr)
		{
			AbilityUnlockTable.GetAllRows(UnlockedAbilities);
			for (int i = UnlockedAbilities.Num() - 1; i >= 0; i--)
			{
				if (!Abilities.Contains(UnlockedAbilities[i].Ability))
				{
					UnlockedAbilities.RemoveAt(i);
				}
			}
		}
		SaveGame.UnlockedAbilities = UnlockedAbilities;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerAbilities", 0);
	}

	UFUNCTION(Category = "Save Game")
	bool LoadAbilities()
	{
		Gameplay::DeleteGameInSlot("PlayerAbilities", 0); // TEMP DELETE

		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerAbilities", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UAbilitySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		for (FAbilityUnlockInfo UnlockInfo : LoadedSave.UnlockedAbilities)
		{
			if (!Abilities.Contains(UnlockInfo.Ability))
				GrantAbility(UnlockInfo.Ability);
		}

		return true;
	}
};