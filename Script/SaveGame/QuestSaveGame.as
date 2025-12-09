class UQuestSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    TMap<FName, FQuestEntry> SavedQuestLog;
}