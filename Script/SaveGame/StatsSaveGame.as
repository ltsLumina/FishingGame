class UStatsSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    int SavedGil;
    
    UPROPERTY(Category = "Data")
    TMap<FGameplayTag, float> SavedStats;

}