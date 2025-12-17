class UInventorySlot : UObject
{
    UPROPERTY(Category = "Inventory")
    UItem Item;

    UPROPERTY(Category = "Inventory", SaveGame)
    FInventoryInstanceData InstanceData;

    UFUNCTION(Category = "Inventory", BlueprintPure)
    FFishSizeData GetFishSizeData()
    {
        return InstanceData.SizeData;
    }
}

struct FInventoryInstanceData
{
    UPROPERTY(Category = "Inventory", SaveGame)
    FFishSizeData SizeData;

    UPROPERTY(Category = "Inventory", SaveGame)
	EFishTag Tag;

    FInventoryInstanceData(FFishSizeData InFishSizeData, EFishTag InTag = EFishTag::None)
    {
        SizeData = InFishSizeData;
        Tag = InTag;
    }
}

enum EFishTag
{
    None,
    Umbral,
    Astral
}