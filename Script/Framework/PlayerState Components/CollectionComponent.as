event void FOnCollectionChanged(FCollectionEntry NewEntry, int Index = -1);

struct FCollectionEntry
{
	UPROPERTY()
	UFishItem Item;

	UPROPERTY()
	FFishInstanceData InstanceData;

	UPROPERTY()
	TSet<EFishTag> Tags;

	/**
	 * Whether the fish has been perfected (caught in all available tags).
	 * May include additional requirements in the future. (Like size or quality)
	 */
	UPROPERTY()
	bool IsPerfected;
}

class UCollectionComponent : UFishComponentBase
{
	UPROPERTY()
	TArray<FCollectionEntry> CollectedItems;

	UPROPERTY(Category = "Events")
	FOnCollectionChanged OnCollectionChanged;

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		InCharacter.FishingComponent.OnFishCaught.AddUFunction(this, n"AddToCollectionByFish");
		InPlayerState.InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION()
	private void HandleInventoryChanged(FName ItemID, FInventorySlot InventorySlot,
								EInventoryChangeType Change)
	{
		if (Change == EInventoryChangeType::Added)
		{
			bool bIsFish = InventorySlot.Item.IsA(UFishItem);
			if (bIsFish)
			{
				auto FishItem = Cast<UFishItem>(InventorySlot.Item);
				AddToCollection(FishItem, InventorySlot.InstanceData.FishInstanceData);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void AddToCollectionByFish(AFish Fish, UFishingHoleComponent FishingHole)
	{
		if (Fish.Item != nullptr)
		{
			AddToCollection(Fish.Item, Fish.FishInstanceData);
		}
	}

	UFUNCTION()
	void AddToCollection(UFishItem NewItem, FFishInstanceData InstanceData)
	{
		if (HasItem(NewItem))
		{
			// Update existing entry to include new tag
			for (auto& Entry : CollectedItems)
			{
				if (Entry.Item.BaseData.ID == NewItem.BaseData.ID)
				{
					if (InstanceData.Tag != EFishTag::None && !Entry.Tags.Contains(InstanceData.Tag))
					{
						Entry.Tags.Add(InstanceData.Tag);
						Print(f"Updated {NewItem.BaseData.ItemName} in collection with new tag {InstanceData.Tag}", 5.0f, FLinearColor::Purple);

						if (Entry.Tags.Contains(EFishTag::Astral) && Entry.Tags.Contains(EFishTag::Umbral))
						{
							Entry.IsPerfected = true;
							Print(f"{NewItem.BaseData.ItemName} has been perfected!", 5.0f, FLinearColor::Purple);
						}
						
						OnCollectionChanged.Broadcast(Entry, CollectedItems.FindIndex(Entry)); // index of updated entry
					}
					return;
				}
			}

			return; // already in collection (shouldn't reach here)
		}

		FCollectionEntry Entry;
		Entry.InstanceData = InstanceData;
		Entry.Item = NewItem;
		if (InstanceData.Tag != EFishTag::None)
		{
			Entry.Tags.Add(InstanceData.Tag);
		}

		CollectedItems.Add(Entry);
		OnCollectionChanged.Broadcast(Entry, CollectedItems.Num() - 1); // last index
	}

	UFUNCTION(BlueprintPure)
	bool HasItem(UFishItem ItemToCheck)
	{
		for (auto& Entry : CollectedItems)
		{
			UFishItem Item = Entry.Item;
			if (Item.BaseData.ID == ItemToCheck.BaseData.ID)
			{
				return true;
			}
		}
		return false;
	}

	/**
	 * Check if the collection has an item with the specified tag.
	 * @param TagToCheck The EFishTag to look for.
	 * @param FoundTag Output parameter that will contain the found tag if it exists.
	 * @return True if an item with the specified tag is found, false otherwise.
	 */
	UFUNCTION(Category = "Collection", BlueprintPure)
	bool HasTag(EFishTag TagToCheck, EFishTag&out FoundTag)
	{
		for (auto& Entry : CollectedItems)
		{
			FFishInstanceData InstanceData = Entry.InstanceData;
			if (InstanceData.Tag == TagToCheck)
			{
				FoundTag = InstanceData.Tag;
				return true;
			}
		}

		FoundTag = EFishTag::None;
		return false;
	}

	UFUNCTION(DisplayName = "Has Tag", Meta = (ExpandBoolAsExecs = "ReturnValue"))
	bool HasTagExec(EFishTag TagToCheck)
	{
		EFishTag FoundTag;
		return HasTag(TagToCheck, FoundTag);
	}

	UFUNCTION()
	bool SaveCollection()
	{
		auto SaveGame = Gameplay::CreateSaveGameObject(UInventorySaveGame); // Using InventorySaveGame for simplicity, as it already has the necessary arrays.
		if (SaveGame == nullptr)
			return false;

		auto InventorySave = Cast<UInventorySaveGame>(SaveGame);
		if (InventorySave == nullptr)
			return false;

		for (auto& Entry : CollectedItems)
		{
			UFishItem Item = Entry.Item;
			FFishInstanceData InstanceData = Entry.InstanceData;

			InventorySave.SavedInstanceData.Add(FInventoryInstanceData(InstanceData));
			InventorySave.SavedItemClass.Add(Item.Class);
			InventorySave.SavedBaseData.Add(Item.BaseData);
			InventorySave.SavedFishData.Add(Item.FishData);
		}

		return Gameplay::SaveGameToSlot(InventorySave, "PlayerCollection", 0);
	}

	UFUNCTION()
	ELoadResult LoadCollection()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerCollection", 0);
		if (SaveGame == nullptr)
			return ELoadResult::SuccessNoData;

		auto LoadedSave = Cast<UInventorySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		CollectedItems.Empty();

		int FishIndex = 0;
		for (int i = 0; i < LoadedSave.SavedBaseData.Num(); i++)
		{
			FInventoryInstanceData InstanceData = LoadedSave.SavedInstanceData[i];

			bool bIsFish = LoadedSave.SavedItemClass[i].DefaultObject.IsA(UFishItem);
			if (bIsFish && LoadedSave.SavedFishData.IsValidIndex(FishIndex))
			{
				auto FishItem = NewObject(this, UFishItem);
				FishItem.BaseData = LoadedSave.SavedBaseData[i];
				FishItem.FishData = LoadedSave.SavedFishData[FishIndex];
				FishIndex++;

				AddToCollection(FishItem, InstanceData.FishInstanceData);
			}
		}

		return ELoadResult::Success;
	}
};

UFUNCTION(BlueprintPure, Category = "Collection")
mixin bool HasAstral(FCollectionEntry& Entry)
{
	return Entry.Tags.Contains(EFishTag::Astral);
}

UFUNCTION(BlueprintPure, Category = "Collection")
mixin bool HasUmbral(FCollectionEntry& Entry)
{
	return Entry.Tags.Contains(EFishTag::Umbral);
}