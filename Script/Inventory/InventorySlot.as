class UInventorySlot : UObject
{
    UPROPERTY(Category = "Inventory")
    UItem Item;

    UPROPERTY(Category = "Inventory", SaveGame)
    FInventoryInstanceData InstanceData;

    UFUNCTION(Category = "Inventory", BlueprintPure)
    FFishSizeData GetFishSizeData()
    {
        return InstanceData.FishSizeData;
    }
}

struct FInventoryInstanceData
{
    UPROPERTY(Category = "Inventory", SaveGame)
    FFishSizeData FishSizeData;

    FInventoryInstanceData(FFishSizeData InFishSizeData)
    {
        FishSizeData = InFishSizeData;
    }
}