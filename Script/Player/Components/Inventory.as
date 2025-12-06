event void FOnInventoryChanged(FName ItemID, UItem Item, EInventoryChangeType Change);

enum EInventoryChangeType
{
	Added,
	Removed
};

class UInventoryComponent : UActorComponent
{
	UPROPERTY(Category = "Inventory", VisibleInstanceOnly)
	TArray<UItem> Items;

	UPROPERTY(Category = "Inventory", EditDefaultsOnly)
	TMap<UBait, int> Baits;

    UPROPERTY(Category = "Inventory")
    FOnInventoryChanged OnInventoryChanged;

	default bReplicates = false;

	UFUNCTION(Category = "Inventory")
	void AddItem(UItem Item)
	{
		Items.Add(Item);
        Print("Added fish to inventory: " + Item.ItemName.ToString(), 3.0);
        OnInventoryChanged.Broadcast(Item.ID, Item, EInventoryChangeType::Added);
	}

	UFUNCTION(Category = "Inventory")
	bool RemoveItem(FName ID)
    {
        for (int i = 0; i < Items.Num(); i++)
        {
            if (Items[i].ID == ID)
            {
                Items.RemoveAt(i);
                Print("Removed fish from inventory: " + ID.ToString());
                OnInventoryChanged.Broadcast(ID, nullptr, EInventoryChangeType::Removed);
                return true;
            }
        }
        return false;
    }

	UFUNCTION(Category = "Inventory")
	void ClearInventory()
	{
		Items.Empty();
		Print("Cleared inventory.");
		OnInventoryChanged.Broadcast(FName("Everything"), nullptr, EInventoryChangeType::Removed);
	}

	UFUNCTION(Category = "Inventory", BlueprintPure, Meta = (CompactNodeTitle = "Contains", Keywords = "has,find"))
	bool Contains(TSubclassOf<AFish> FishClass)
	{
		for (auto& Pair : Items)
        {
            if (Cast<UFishItem>(Pair).FishClass == FishClass)
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
			if (Pair.ID == ID)
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
			TotalValue += Cast<UFishItem>(Pair).VendorValue;
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
			auto State = Cast<AFishPlayerState>(GetOwner());
			auto Character = Cast<AFishCharacter>(State.GetPawn());
			auto FishingComponent = UFishingComponent::Get(Character);
			
			FishingComponent.CurrentBait = nullptr;
			PrintWarning("You have run out of " + Bait.BaitName.ToString() + "!");
		}
	}
};