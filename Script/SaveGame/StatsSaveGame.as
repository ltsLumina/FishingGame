class UStatsSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    TMap<FGameplayTag, float> SavedStats;

}