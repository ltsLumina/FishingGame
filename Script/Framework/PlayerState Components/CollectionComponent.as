event void FOnCollectionChanged(UFishItem Item);

class UCollectionComponent : UFishComponentBase
{
    UPROPERTY()
    TArray<UFishItem> CollectedItems;

    UPROPERTY(Category = "Events")
    FOnCollectionChanged OnCollectionChanged;

    void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
                        float InInitializationTime) override
    {
        Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);
        
        InCharacter.FishingComponent.OnFishCaught.AddUFunction(this, n"AddToCollectionByFish");
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

    UFUNCTION()
    bool SaveCollection()
    {
        auto SaveGame = Gameplay::CreateSaveGameObject(UInventorySaveGame); // Using InventorySaveGame for simplicity, as it already has the necessary arrays.
        if (SaveGame == nullptr)
            return false;

        auto InventorySave = Cast<UInventorySaveGame>(SaveGame);
        if (InventorySave == nullptr)
            return false;

        for (UFishItem Item : CollectedItems)
        {
            InventorySave.SavedBaseData.Add(Item.BaseData);
            InventorySave.SavedFishData.Add(Item.FishData);
        }

        return Gameplay::SaveGameToSlot(InventorySave, "PlayerCollection", 0);
    }

    //TODO: what was I thinking lol. The inventory might be empty when you load, so this would fail to load anything.
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

        return ELoadResult::Success;
    }
};