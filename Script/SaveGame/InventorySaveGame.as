class UInventorySaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    int SavedGil;
    
    UPROPERTY(Category = "Data")
    TArray<TSubclassOf<UItem>> SavedItemClass;
    
    UPROPERTY(Category = "Data")
    TArray<FItemData> SavedBaseData;

    UPROPERTY(Category = "Data")
    TArray<FFishItemData> SavedFishData;


    UPROPERTY(Category = "Data")
    TArray<FInventoryInstanceData> SavedInstanceData;
}
