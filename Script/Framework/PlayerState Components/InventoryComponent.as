event void FOnRodEquipped(UFishingRod NewRod);
event void FOnRodUnequipped(UFishingRod OldRod);
event void FOnInventoryChanged(FName ItemID, UInventorySlot Slot, EInventoryChangeType Change);

enum EInventoryChangeType
{
	Added,
	Removed
};

class UInventoryComponent : UFishComponentBase
{
	UPROPERTY(Category = "Rod", EditDefaultsOnly)
	URodData DefaultRodData;

	UPROPERTY(Category = "Rod", VisibleInstanceOnly)
	UFishingRod EquippedRod;

#if EDITOR
	UPROPERTY(Category = "Rod", EditFixedSize, Meta = (TitleProperty="TraitName", EditFixedOrder))
	TArray<FDebugTraitInfo> TraitInfos;
#endif

	UPROPERTY(Category = "Inventory", VisibleInstanceOnly)
	TArray<UInventorySlot> Items;

	UPROPERTY(Category = "Inventory", EditDefaultsOnly)
	TMap<UBait, int> Baits;

	UPROPERTY(Category = "Rod | Events")
	FOnRodEquipped OnRodEquipped;

	UPROPERTY(Category = "Rod | Events")
	FOnRodUnequipped OnRodUnequipped;

	UPROPERTY(Category = "Inventory")
	FOnInventoryChanged OnInventoryChanged;

	default bReplicates = false;

	default bWaitForOwningActorInitialized = true;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		OnRodEquipped.AddUFunction(this, n"HandleRodEquipped");
		OnRodUnequipped.AddUFunction(this, n"HandleRodUnequipped");

		if (EquippedRod == nullptr && !Gameplay::DoesSaveGameExist("PlayerInventory", 0))
		{
			EquipRod(FishingRod::GenerateRod(this, DefaultRodData));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodEquipped(UFishingRod NewRod)
	{
#if EDITOR
		TraitInfos.Empty();

		Print(f"Equipped rod: {NewRod.Data.Name} with {NewRod.Traits.Num()} traits.", 3.0f, FLinearColor::Purple);
		TArray<FString> TraitNames;
		for (auto& TraitClass : NewRod.Traits)
		{
			auto Trait = TraitClass.GetDefaultObject();

			FDebugTraitInfo Info;
			Info.TraitName = Trait.TraitName.ToString();
			Info.Description = Trait.Description.ToString();
			Info.Effect = Trait.Effect.ToString();

			TraitNames.Add(Info.TraitName);
			TraitInfos.Add(Info);
		}
		Print("Traits: " + String::JoinStringArray(TraitNames, ", "), 3.0f, FLinearColor::Purple);
#endif
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleRodUnequipped(UFishingRod OldRod)
	{
#if EDITOR
		TraitInfos.Empty();
#endif
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
				auto Trait = TraitClass.GetDefaultObject();
				Trait.ApplyTrait(Character, PlayerState.StatsComponent, Character.FishingComponent);
			}

			OnRodEquipped.Broadcast(EquippedRod);
		}
	}

	UFUNCTION(Category = "Inventory")
	void AddItem(UItem Item, FInventoryInstanceData InstanceData = FInventoryInstanceData(), int Quantity = 1)
	{
		if (Items.Num() >= 40)
			return;

		UInventorySlot Slot;

		for (int i = 0; i < Quantity; i++)
		{
			int SlotIndex = GetFirstEmptySlot();

			// Expand array if needed
			if (SlotIndex >= Items.Num())
			{
				Items.SetNum(SlotIndex + 1);
			}

			Slot = NewObject(this, UInventorySlot);
			Slot.Item = Item;
			Slot.InstanceData = InstanceData;
			Items[SlotIndex] = Slot;
		}
		OnInventoryChanged.Broadcast(Item.BaseData.ID, Slot, EInventoryChangeType::Added);
	}

	UFUNCTION(Category = "Inventory", Meta = (ReturnDisplayName = "Found"))
	bool FindItem(FName ID, int&out Index)
	{
		for (int i = 0; i < Items.Num(); i++)
		{
			if (Items[i].Item.BaseData.ID == ID)
			{
				Index = i;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(Category = "Inventory", BlueprintPure)
	int GetFirstEmptySlot()
	{
		for (int i = 0; i < Items.Num(); i++)
		{
			if (Items[i] == nullptr)
				return i;
		}
		return Items.Num(); // Return next slot if no empty ones found
	}

	UFUNCTION(Category = "Inventory")
	bool HasItem(FName ID)
	{
		for (auto& Pair : Items)
		{
			if (Pair.Item.BaseData.ID == ID)
			{
				return true;
			}
		}
		return false;
	}

	/**
	 * Removes an item from the inventory by its ID.
	 * @param ID The ID of the item to remove.
	 * @param RemoveDuplicates If true, removes all instances of the item with the given ID
	 */
	UFUNCTION(Category = "Inventory")
	bool RemoveItem(FName ID, bool RemoveDuplicates = false)
	{
		bool bRemoved = false;
		for (int i = 0; i < Items.Num(); i++)
		{
			if (Items[i] != nullptr && Items[i].Item.BaseData.ID == ID)
			{
				auto RemovedItem = Items[i];
				Items[i] = nullptr; // Clear the slot instead of removing it
				bRemoved = true;
				OnInventoryChanged.Broadcast(ID, RemovedItem, EInventoryChangeType::Removed);
				if (!RemoveDuplicates)
					break;
			}
		}
		return bRemoved;
	}

	UFUNCTION(Category = "Inventory")
	bool RemoveItemByIndex(int Index)
	{
		if (Index < 0 || Index >= Items.Num())
			return false;

		auto RemovedSlot = Items[Index];
		Items[Index] = nullptr; // Clear the slot instead of removing it

		OnInventoryChanged.Broadcast(RemovedSlot.Item.BaseData.ID, RemovedSlot, EInventoryChangeType::Removed);
		return true;
	}

	/**
	 * Removes an item from the inventory by its slot.
	 * @param Slot The inventory slot to remove.
	 * @param ItemFilter Optional filter to only remove if the item is in the filter list.
	 */
	UFUNCTION()
	bool RemoveItemBySlot(UInventorySlot Slot, TArray<TSubclassOf<UItem>> ItemFilter = TArray<TSubclassOf<UItem>>())
	{
		for (int i = 0; i < Items.Num(); i++)
		{
			if (Items[i] == Slot && (ItemFilter.Num() == 0 || ItemFilter.Contains(Slot.Item.GetClass())))
			{
				Items[i] = nullptr; // Clear the slot instead of removing it
				OnInventoryChanged.Broadcast(Slot.Item.BaseData.ID, Slot, EInventoryChangeType::Removed);
				return true;
			}
		}
		return false;
	}

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

	UFUNCTION(Category = "Inventory")
	void ClearInventory()
	{
		Items.Empty();
		// Print("Cleared inventory.");
		OnInventoryChanged.Broadcast(FName("Everything"), nullptr, EInventoryChangeType::Removed);
	}

	UFUNCTION(Category = "Inventory", BlueprintPure, Meta = (CompactNodeTitle = "Contains", Keywords = "has,find"))
	bool Contains(FName ID)
	{
		for (auto& Slot : Items)
		{
			if (Slot.Item.GetID() == ID)
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(Category = "Inventory", BlueprintPure, Meta = (CompactNodeTitle = "Quantity", Keywords = "count,number"))
	int GetItemQuantity(FName ID)
	{
		int Quantity = 0;
		for (auto& Slot : Items)
		{
			if (Slot == nullptr)
				continue;

			if (Slot.Item.BaseData.ID == ID)
			{
				Quantity++;
			}
		}
		return Quantity;
	}

	UFUNCTION(Category = "Inventory", BlueprintPure)
	int GetTotalValue()
	{
		int TotalValue = 0;
		for (auto& Pair : Items)
		{
			if (Cast<UFishItem>(Pair) == nullptr)
				continue;
			TotalValue += Cast<UFishItem>(Pair).FishData.VendorValue;
		}
		return TotalValue;
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

	bool SaveInventory()
	{
		TArray<FItemData> SavedBaseData;
		TArray<FFishItemData> SavedFishData;
		TArray<FInventoryInstanceData> SavedInstanceData;

		auto SaveGame = Gameplay::CreateSaveGameObject(UInventorySaveGame);

		SavedBaseData.Empty();
		SavedFishData.Empty();
		SavedInstanceData.Empty();

		for (auto& Slot : Items)
		{
			if (Slot == nullptr)
				continue;

			SavedBaseData.Add(Slot.Item.BaseData);

			auto FishItem = Cast<UFishItem>(Slot.Item);
			if (FishItem != nullptr)
			{
				SavedFishData.Add(FishItem.FishData);
				SavedInstanceData.Add(Slot.InstanceData);
			}
		}

		SaveGame.SavedRod = EquippedRod.Data;
		SaveGame.SavedRodTraits = EquippedRod.Traits;

		SaveGame.SavedBaseData = SavedBaseData;
		SaveGame.SavedFishData = SavedFishData;
		SaveGame.SavedInstanceData = SavedInstanceData;

		return Gameplay::SaveGameToSlot(SaveGame, "PlayerInventory", 0);
	}

	UFUNCTION()
	ELoadResult LoadInventory()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerInventory", 0);
		if (SaveGame == nullptr)
			return ELoadResult::SuccessNoData;

		auto LoadedSave = Cast<UInventorySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		auto LoadedRod = FishingRod::GenerateRod(this, LoadedSave.SavedRod);
		LoadedRod.Traits = LoadedSave.SavedRodTraits; // traits are saved separately to preserve randomization
		EquipRod(LoadedRod);
		Print(f"Loaded rod ({LoadedSave.SavedRod.GetName()}) with " + LoadedSave.SavedRodTraits.Num() + " traits from save.", 3.0f, FLinearColor::Green);

		Items.Empty();
		for (int i = 0; i < LoadedSave.SavedBaseData.Num(); i++)
		{
			if (i < LoadedSave.SavedFishData.Num())
			{
				auto FishItem = NewObject(this, UFishItem);
				FishItem.BaseData = LoadedSave.SavedBaseData[i];
				FishItem.FishData = LoadedSave.SavedFishData[i];
				auto SizeData = LoadedSave.SavedInstanceData[i];

				AddItem(FishItem, SizeData, 1);
			}
			else
			{
				auto Item = NewObject(this, UItem);
				Item.BaseData = LoadedSave.SavedBaseData[i];
				AddItem(Item, FInventoryInstanceData(), 1);
			}
		}

		return ELoadResult::Success;
	}
};

#if EDITOR
struct FDebugTraitInfo
{
	UPROPERTY(VisibleAnywhere)
	FString TraitName;

	UPROPERTY(VisibleAnywhere)
	FString Description;

	UPROPERTY(VisibleAnywhere)
	FString Effect;
}
#endif