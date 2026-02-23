class UEquipmentSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    URodItem SavedRod;

    UPROPERTY(Category = "Data")
    TArray<TSubclassOf<UTrait>> SavedRodTraits;

    UPROPERTY(Category = "Data")
    TMap<UBait, int> SavedBaits;
}
