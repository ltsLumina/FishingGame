class UAbilitySaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    TArray<FAbilityUnlockInfo> UnlockedAbilities;
}