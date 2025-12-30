class UStatsSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    URodData SavedRod;

    UPROPERTY(Category = "Data")
    TArray<TSubclassOf<UTrait>> SavedRodTraits;
    
    UPROPERTY(Category = "Data")
    FStats SavedStats;

    UPROPERTY(Category = "Data")
    int SavedGil;
}