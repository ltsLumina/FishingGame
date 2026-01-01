class UQuestSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    TMap<FName, FQuestEntry> SavedQuestLog;

    UPROPERTY(Category = "Data")
    TArray<FName> SavedCompletedQuests;
}