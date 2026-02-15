struct FInventorySlot
{
    UPROPERTY(Category = "Inventory", VisibleAnywhere, BlueprintHidden, Transient)
    FText SlotName;
    
    UPROPERTY(Category = "Inventory", VisibleAnywhere, SaveGame)
    UItem Item;

    UPROPERTY(Category = "Inventory", VisibleAnywhere, SaveGame)
    FInventoryInstanceData InstanceData;
}

struct FInventoryInstanceData
{
    UPROPERTY(Category = "Inventory", SaveGame)
    FFishInstanceData FishInstanceData;

    /**
     * Constructor for Fish items.
     */
    FInventoryInstanceData(FFishSizeData InFishSizeData, EFishTag InTag = EFishTag::None)
    {
        FishInstanceData.SizeData = InFishSizeData;
        FishInstanceData.Tag = InTag;
    }

    FInventoryInstanceData(FFishInstanceData InFishInstanceData)
    {
        FishInstanceData = InFishInstanceData;
    }
}

USTRUCT(Meta=(HasNativeMake="/Script/Angelscript.MakeFishInstanceData")) // dont think this actually works, but it blocks the native make function which is intended
struct FFishInstanceData
{
    UPROPERTY(Category = "Fish", SaveGame)
    FFishSizeData SizeData;

    UPROPERTY(Category = "Fish", SaveGame)
    EFishTag Tag;
}

enum EFishTag
{
    None,
    Umbral,
    Astral
}