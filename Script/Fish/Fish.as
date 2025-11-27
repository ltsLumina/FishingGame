UCLASS(Abstract)
class AFish : AActor
{
    /* psuedo code for future implementation
    - name
    - flavour text
    - size
    - weight
    - type
    - rarity
    */

    UPROPERTY(Category = "Fish | Info")
    FText FishName = FText::FromString("Default Fish");

    UPROPERTY(Category = "Fish | Info", Meta=(MultiLine))
    FText Description = FText::FromString("A generic fish. Nothing special about it.");

    /**
     * Recommended fishing level to catch this fish.
     */
    UPROPERTY(Category = "Fish | Info")
    int RecommendedFishingLevel = 1;

    /**
     * Which area types this fish can be found in.
     */
    UPROPERTY(Category = "Fish | Info")
    EFishType FishType = EFishType::Freshwater;

    /**
     * Rarity of this fish.
     */
    UPROPERTY(Category = "Fish | Info")
    EFishRarity Rarity = EFishRarity::Basic;

    /**
     * Sell price to vendors.
     */
    UPROPERTY(Category = "Fish | Shop")
    int VendorValue = 1;

    UPROPERTY(Category = "Fish | Physical", Meta=(Units="cm"))
    float Size = 10.0f;

    UPROPERTY(Category = "Fish | Physical", Meta=(Units="kg"))
    float Weight = 0.5f;

    /**
     * Size span of the fish (min and max size in cm).
     */
    UPROPERTY(Category = "Fish | Physical", Meta=(Units="cm"))
    FVector2D SizeSpan = FVector2D(5.0f, 15.0f);



    /**
     * Time it takes for this fish to bite (in seconds).
     */
    UPROPERTY(Category = "Fish | Catch")
    float BiteTime = 5;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        SetReplicates(true);

        // Validate size against size span. If out of bounds, set to -1 (unknown).
        if (Size < SizeSpan.X || Size > SizeSpan.Y)
        {
            Size = -1;
            PrintError("Fish size is out of bounds of its size span!");
        }
    }
};

enum EFishType
{
    Freshwater,
    Saltwater,
    Brackish,
    Tropical,
    Coldwater
}

enum EFishRarity
{
    Basic,
    Aetherial,
    Dungeon,
    Tomestone,
    Relic
}