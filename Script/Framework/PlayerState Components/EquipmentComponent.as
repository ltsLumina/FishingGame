event void FOnRodEquipped(UFishingRod NewRod);
event void FOnRodUnequipped(UFishingRod OldRod);

// TODO: put bait and rod here; moved from inventory
class UEquipmentComponent : UFishComponentBase
{

	UPROPERTY(Category = "Licence", VisibleInstanceOnly, Meta = (Categories = "Licence"))
	FGameplayTagContainer Licences;
	default Licences.AddTag(GameplayTags::Licence_Zone1);

	UPROPERTY(Category = "Rod", EditDefaultsOnly, SaveGame)
	URodItem DefaultRodData;

	UPROPERTY(Category = "Rod", VisibleInstanceOnly, SaveGame)
	UFishingRod EquippedRod;

	// literally just used to prevent garbage collection of traits
	UPROPERTY(NotEditable, NotVisible, BlueprintHidden)
	TArray<UTrait> AppliedTraits;

#if EDITOR
	UPROPERTY(Category = "Rod", VisibleInstanceOnly, EditFixedSize, Meta = (TitleProperty = "TraitName", EditFixedOrder))
	TArray<FDebugTraitInfo> TraitInfos;
#endif

	UPROPERTY(Category = "Inventory", EditDefaultsOnly, VisibleInstanceOnly, SaveGame)
	TMap<UBait, int> Baits;

	UPROPERTY(Category = "Rod | Events")
	FOnRodEquipped OnRodEquipped;

	UPROPERTY(Category = "Rod | Events")
	FOnRodUnequipped OnRodUnequipped;

	default bWaitForOwningActorInitialized = true;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		OnRodEquipped.AddUFunction(this, n"HandleRodEquipped");
		OnRodUnequipped.AddUFunction(this, n"HandleRodUnequipped");

		if (EquippedRod == nullptr && !Gameplay::DoesSaveGameExist("PlayerEquipment", 0))
		{
			EquipRod(FishingRod::GenerateRod(this, DefaultRodData));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodEquipped(UFishingRod NewRod)
	{
#if EDITOR
		Print(f"Equipped rod: {NewRod.RodItem.Name} with {NewRod.Traits.Num()} traits.", 3.0f, FLinearColor::Purple);
		PrintTraitDebugInfo(NewRod);
#endif
	}

#if EDITOR
	void PrintTraitDebugInfo(UFishingRod Rod)
	{
		TraitInfos.Empty();

		TArray<FString> TraitNames;
		for (auto& TraitClass : Rod.Traits)
		{
			auto Trait = TraitClass.GetDefaultObject();

			FDebugTraitInfo Info;
			Info.TraitName = Trait.TraitName.ToString();
			Info.Description = Trait.Description.ToString();
			Info.Effect = Trait.BasicEffect.ToString();

			TraitNames.Add(Info.TraitName);
			TraitInfos.Add(Info);
		}
		Print("Traits: " + String::JoinStringArray(TraitNames, ", "), 3.0f, FLinearColor::Purple);
	}
#endif

	UFUNCTION(NotBlueprintCallable)
	void HandleRodUnequipped(UFishingRod OldRod)
	{
#if EDITOR
		TraitInfos.Empty();
#endif

		AppliedTraits.Empty();
		System::CollectGarbage(); // terrible solution but it works so far
	}

	void EquipRod(UFishingRod NewRod)
	{
		if (EquippedRod != nullptr)
		{
			OnRodUnequipped.Broadcast(EquippedRod);
		}

		EquippedRod = NewRod;

		if (EquippedRod != nullptr)
		{
			// apply rod stat modifiers
			for (auto& TraitClass : EquippedRod.Traits)
			{
				if (TraitClass == nullptr)
				{
					throw("TraitClass is nullptr!");
					continue;
				}

				if (Character == nullptr)
					Character = GetFishCharacterBase();

				auto Trait = NewObject(this, TraitClass);
				Trait.Init(Character.FishingComponent, PlayerState.StatsComponent, PlayerState.TokenComponent);
				AppliedTraits.Add(Trait);

				bool IsEnhanced = false;
				if (Trait.CanBeEnhanced)
				{
					float Chance = FishingRod::GetEnhanceChance(EquippedRod.RodItem.RodData.Tier);
					IsEnhanced = Percent::RollPercentChance(Chance);
					if (IsEnhanced)
						Print(f"Trait {Trait.TraitName} was enhanced! ({Chance}% chance)", 3.0f, FLinearColor::Purple);
				}

				if (!IsEnhanced)
					Trait.ApplyTrait(Character, PlayerState);
				else
					Trait.ApplyTraitEnhanced(Character, PlayerState);
			}

			OnRodEquipped.Broadcast(EquippedRod);
		}
	}

	// #region Bait
	UFUNCTION(Category = "Inventory | Bait")
	void AddBait(UBait Bait, int Quantity = 1)
	{
		if (Baits.Contains(Bait))
		{
			Baits[Bait] += Quantity;
		}
		else
		{
			Baits.Add(Bait, Quantity);
		}
		Print("Added " + Quantity + " x " + Bait.BaitName.ToString() + " to bait inventory.", 3.0);
	}

	UFUNCTION(Category = "Inventory | Bait")
	void ConsumeBait(UBait Bait)
	{
		if (!Baits.Contains(Bait))
			return;

		Baits[Bait] = Math::Max(0, Baits[Bait] - 1);

		if (Baits[Bait] == 0)
		{
			auto FishingComponent = UFishingComponent::Get(Character);

			FishingComponent.CurrentBait = nullptr;
			PrintWarning("You have run out of " + Bait.BaitName.ToString() + "!");

			GetFishHUD().AddNotification(f"You have run out of {Bait.BaitName}");
		}
	}
	// #endregion

	// #region Save/Load

	UFUNCTION(Category = "Inventory", BlueprintPure)
	bool IsValidSlot(FInventorySlot Slot)
	{
		return Slot.Item != nullptr;
	}

	bool SaveEquipment()
	{
		auto SaveGame = Gameplay::CreateSaveGameObject(UEquipmentSaveGame);

		SaveGame.SavedRod = EquippedRod.RodItem;
		SaveGame.SavedRodTraits = EquippedRod.Traits;
        SaveGame.SavedBaits = Baits;

		return Gameplay::SaveGameToSlot(SaveGame, "PlayerEquipment", 0);
	}

	ELoadResult LoadEquipment()
	{
        EquippedRod = nullptr;

		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerEquipment", 0);
		if (SaveGame == nullptr)
			return ELoadResult::NoData;

		auto LoadedSave = Cast<UEquipmentSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		auto LoadedRod = FishingRod::GenerateRod(this, LoadedSave.SavedRod);
		LoadedRod.Traits = LoadedSave.SavedRodTraits; // traits are saved separately to preserve randomization
		EquipRod(LoadedRod);
		Print(f"Loaded rod ({LoadedSave.SavedRod.GetName()}) with " + LoadedSave.SavedRodTraits.Num() + " traits from save.", 3.0f, FLinearColor::Purple);
#if EDITOR
		PrintTraitDebugInfo(LoadedRod);
#endif

        Baits = LoadedSave.SavedBaits; // TODO

		return ELoadResult::Success;
	}
	// #endregion
};