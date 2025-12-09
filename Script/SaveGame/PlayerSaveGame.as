class UPlayerSaveGame : USaveGame
{
    UPROPERTY(Category = "Data")
    FVector SavedLocation;

    UPROPERTY(Category = "Data")
    FRotator SavedRotation;
}