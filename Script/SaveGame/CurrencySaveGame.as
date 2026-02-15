class UCurrencySaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    TMap<ECurrency, int> Currencies;
}