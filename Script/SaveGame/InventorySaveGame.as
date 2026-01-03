class UInventorySaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    URodData SavedRod;

    UPROPERTY(Category = "Data")
    TArray<TSubclassOf<UTrait>> SavedRodTraits;
    
    UPROPERTY(Category = "Data")
    TArray<FItemData> SavedBaseData;

    UPROPERTY(Category = "Data")
    TArray<FFishItemData> SavedFishData;

    UPROPERTY(Category = "Data")
    TArray<FInventoryInstanceData> SavedInstanceData;
}
