event void FOnAbilityGranted(UAbilityData AbilityData);
event void FOnAbilityRevoked(UAbilityData AbilityData);

class UAbilityHandlerComponent : UFishComponentBase
{
	UPROPERTY(Category = "Abilities", VisibleInstanceOnly, BlueprintReadOnly)
	TArray<UAbilityData> Abilities;

	UPROPERTY(Category = "Abilities", EditDefaultsOnly, BlueprintReadOnly)
	UDataTable AbilityUnlockTable;

	TArray<FAbilityUnlockInfo> UnlockInfos;

	UPROPERTY(Category = "Abilities | Events")
	FOnAbilityGranted OnAbilityGranted;

	UPROPERTY(Category = "Abilities | Events")
	FOnAbilityRevoked OnAbilityRevoked;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		Abilities.Empty();
		AbilityUnlockTable.GetAllRows(UnlockInfos);
		check(UnlockInfos.Num() > 0, "AbilityUnlockTable has no rows!");
		check(UnlockInfos[0].Ability != nullptr, "AbilityUnlockTable has invalid AbilityData references! (IT CLEARED ITSELF AGAINNNNNNNNNNNNNNNNNNN)");

		for (FAbilityUnlockInfo Info : UnlockInfos)
		{
			if (Info.UnlockLevel <= 1) // Starting abilities
			{
				auto LoadedAbility = LoadAbility(Info.Ability);
				GrantAbility(LoadedAbility);
			}
		}

		PlayerState.ExperienceComponent.OnLevelUp.AddUFunction(this, n"OnLevelUp");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnLevelUp(int NewLevel)
	{
		for (FAbilityUnlockInfo Info : UnlockInfos)
		{
			if (Info.UnlockLevel == NewLevel)
			{
				auto LoadedAbility = LoadAbility(Info.Ability);
				GrantAbility(LoadedAbility);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void InvokeAbility(UAbilityData Ability)
	{
		// Print("Ability invoked: " + Ability.GetName());

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

	UFUNCTION(Category = "Abilities", BlueprintPure)
	bool HasAbility(UAbilityData AbilityData)
	{
		return Abilities.Contains(AbilityData);
	}

	UFUNCTION(Category = "Abilities", BlueprintPure, DisplayName = "Has Ability (Soft Ref)")
	bool HasAbilitySoft(TSoftObjectPtr<UAbilityData> AbilityDataPtr)
	{
		auto AbilityData = LoadAbility(AbilityDataPtr);
		return Abilities.Contains(AbilityData);
	}

	UFUNCTION(Category = "Abilities", BlueprintPure, DisplayName = "Has Ability")
	bool HasAbilityByName(FString AbilityName)
	{
		for (UAbilityData AbilityData : Abilities)
		{
			if (AbilityData.Details.Name.ToString() == AbilityName)
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(Category = "Save Game")
	bool SaveAbilities()
	{
		auto SaveGame = NewObject(this, UAbilitySaveGame);

		TArray<FAbilityUnlockInfo> UnlockedAbilities;
		for (UAbilityData AbilityData : Abilities)
		{
			for (FAbilityUnlockInfo Info : UnlockInfos)
			{
				if (Info.Ability == AbilityData)
				{
					UnlockedAbilities.Add(Info);
					break;
				}
			}
		}

		SaveGame.UnlockedAbilities = UnlockedAbilities;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerAbilities", 0);
	}

	UFUNCTION(Category = "Save Game")
	bool LoadAbilities()
	{
#if EDITOR
		Gameplay::DeleteGameInSlot("PlayerAbilities", 0); // TEMP DELETE
		PrintWarning("Deleted PlayerAbilities save for testing.", 5.0f);
#endif

		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerAbilities", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UAbilitySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		for (FAbilityUnlockInfo UnlockInfo : LoadedSave.UnlockedAbilities)
		{
			if (!HasAbilitySoft(UnlockInfo.Ability))
			{
				auto LoadedAbility = LoadAbility(UnlockInfo.Ability);
				GrantAbility(LoadedAbility);
				Print("Loaded ability from save: " + LoadedAbility.Details.Name.ToString(), 3.0f, FLinearColor::Green);
			}
		}

		return true;
	}

	UAbilityData LoadAbility(TSoftObjectPtr<UAbilityData> SoftAbilityData)
	{
		auto LoadedAblity = System::LoadAsset_Blocking(SoftAbilityData);
		if (!IsValid(LoadedAblity))
		{
			PrintError("AbilityHandlerComponent LoadAbility: Failed to load ability data asset from soft reference!");
			return nullptr;
		}

		return Cast<UAbilityData>(LoadedAblity);
	}
};

struct FAbilityUnlockInfo
{
	UPROPERTY(Category = "Ability", SaveGame)
	TSoftObjectPtr<UAbilityData> Ability;

	UPROPERTY(Category = "Ability", Meta = (UIMin = "1", UIMax = "100"), SaveGame)
	int UnlockLevel = 1;
}