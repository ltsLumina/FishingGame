event void FOnCollectionChanged(UFishItem Item);

class UCollectionComponent : UFishComponentBase
{
    UPROPERTY()
    TArray<UFishItem> CollectedItems;

    UPROPERTY(Category = "Events")
    FOnCollectionChanged OnCollectionChanged;

    void LatePlay() override
    {
        Super::LatePlay();
        UFishingComponent::Get(Character).OnFishCaught.AddUFunction(this, n"AddToCollectionByFish");
    }

    UFUNCTION(NotBlueprintCallable)
    private void AddToCollectionByFish(AFish Fish)
    {
        if (Fish.Item != nullptr)
        {
            AddToCollection(Fish.Item);
        }
    }

    UFUNCTION()
    void AddToCollection(UFishItem NewItem)
    {
        if (HasItem(NewItem)) return;

        CollectedItems.Add(NewItem);
        OnCollectionChanged.Broadcast(NewItem);
    }

    UFUNCTION(BlueprintPure)
    bool HasItem(UFishItem ItemToCheck)
    {
        for (UFishItem Item : CollectedItems)
        {
            if (Item.BaseData.ID == ItemToCheck.BaseData.ID)
            {
                return true;
            }
        }
        return false;
    }

    //TODO: what was I thinking lol. The inventory might be empty when you load, so this would fail to load anything.
    UFUNCTION()
    bool LoadCollection()
    {
        auto SaveGame = Gameplay::LoadGameFromSlot("PlayerInventory", 0);
        if (SaveGame == nullptr)
            return false;

        auto LoadedSave = Cast<UInventorySaveGame>(SaveGame);
        if (LoadedSave == nullptr)
            return false;

        CollectedItems.Empty();

        for (int i = 0; i < LoadedSave.SavedBaseData.Num(); i++)
        {
            if (i < LoadedSave.SavedFishData.Num())
            {
                auto FishItem = NewObject(this, UFishItem);
                FishItem.BaseData = LoadedSave.SavedBaseData[i];
                FishItem.FishData = LoadedSave.SavedFishData[i];
                AddToCollection(FishItem);
            }
        }

        return true;
    }
};