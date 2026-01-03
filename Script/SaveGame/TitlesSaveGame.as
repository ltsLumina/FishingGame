class UTitlesSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    FText SavedTitle;

    UPROPERTY(Category = "Data")
    TArray<FText> SavedOwnedTitles;

}