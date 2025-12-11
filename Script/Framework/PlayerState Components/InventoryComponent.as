event void FOnInventoryChanged(FName ItemID, UItem Item, EInventoryChangeType Change);

enum EInventoryChangeType
{
	Added,
	Removed
};

class UInventoryComponent : UFishComponentBase
{
	UPROPERTY(Category = "Inventory", VisibleInstanceOnly)
	TArray<UItem> Items;

	UPROPERTY(Category = "Inventory", EditDefaultsOnly)
	TMap<UBait, int> Baits;

    UPROPERTY(Category = "Inventory")
    FOnInventoryChanged OnInventoryChanged;

	default bReplicates = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay() { }

	void LatePlay() override
	{
		Super::LatePlay();
		BP_LatePlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay() { }

	UFUNCTION(Category = "Inventory")
	void AddItem(UItem Item, int Quantity = 1)
	{
		if (Items.Num() >= 40) return;

		for (int i = 0; i < Quantity; i++)
		{
			Items.Add(Item);
		}
		//Print("Added " + Quantity + " x " + Item.BaseData.ItemName.ToString() + " to inventory.", 3.0);
		OnInventoryChanged.Broadcast(Item.BaseData.ID, Item, EInventoryChangeType::Added);
		UCollectionComponent::Get(GetOwner()).AddToCollection(Cast<UFishItem>(Item));
	}

	UFUNCTION(Category = "Inventory", Meta=(ReturnDisplayName="Found"))
	bool FindItem(FName ID, int&out Index)
	{
		for (int i = 0; i < Items.Num(); i++)
		{
			if (Items[i].BaseData.ID == ID)
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
		return Items.Num() - 1;
	}

	UFUNCTION(Category = "Inventory")
	bool HasItem(FName ID)
	{
		for (auto& Pair : Items)
		{
			if (Pair.BaseData.ID == ID)
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
		for (int i = Items.Num() - 1; i >= 0; i--)
		{
			if (Items[i].BaseData.ID == ID)
			{
				auto RemovedItem = Items[i];
				Items.RemoveAt(i);
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

		auto RemovedItem = Items[Index];
		Items.RemoveAt(Index);

		OnInventoryChanged.Broadcast(RemovedItem.BaseData.ID, RemovedItem, EInventoryChangeType::Removed);
		return true;
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
		//Print("Cleared inventory.");
		OnInventoryChanged.Broadcast(FName("Everything"), nullptr, EInventoryChangeType::Removed);
	}

	UFUNCTION(Category = "Inventory", BlueprintPure, Meta = (CompactNodeTitle = "Contains", Keywords = "has,find"))
	bool Contains(TSubclassOf<AFish> FishClass)
	{
		for (auto& Pair : Items)
        {
            if (Cast<UFishItem>(Pair).FishData.FishClass == FishClass)
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
		for (auto& Pair : Items)
		{
			if (Pair.BaseData.ID == ID)
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

	UFUNCTION(Category = "Save Game")
    bool SaveInventory()
    {
        TArray<FItemData> SavedBaseData;
        TArray<FFishItemData> SavedFishData;

        auto SaveGame = Gameplay::CreateSaveGameObject(UInventorySaveGame);

        SavedBaseData.Empty();
        SavedFishData.Empty();

        for (auto& Item : Items)
        {
            SavedBaseData.Add(Item.BaseData);
            if (Item.IsA(UFishItem))
            {
                auto FishItem = Cast<UFishItem>(Item);
                SavedFishData.Add(FishItem.FishData);
            }
        }

        SaveGame.SavedBaseData = SavedBaseData;
        SaveGame.SavedFishData = SavedFishData;

        return Gameplay::SaveGameToSlot(SaveGame, "PlayerInventory", 0);
    }

	UFUNCTION()
	bool LoadInventory()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerInventory", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UInventorySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		Items.Empty();

		for (int i = 0; i < LoadedSave.SavedBaseData.Num(); i++)
		{
			if (i < LoadedSave.SavedFishData.Num())
			{
				auto FishItem = NewObject(this, UFishItem);
				FishItem.BaseData = LoadedSave.SavedBaseData[i];
				FishItem.FishData = LoadedSave.SavedFishData[i];
				AddItem(FishItem, 1);
			}
		}

		return true;
	}
};