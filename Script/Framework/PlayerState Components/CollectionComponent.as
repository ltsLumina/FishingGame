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

    UFUNCTION()
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
};