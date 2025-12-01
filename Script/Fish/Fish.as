UCLASS(Abstract)
class AFish : AActor
{
    UPROPERTY(Category = "Fish | Info", DisplayName = "Name")
    FText FishName = FText::FromString("Default Fish");

    UPROPERTY(Category = "Fish | Info", Meta=(MultiLine))
    FText Description = FText::FromString("A generic fish. Nothing special about it.");

    UPROPERTY(Category = "Fish | Info")
    TArray<UBait> RequiredBaits;

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

    UPROPERTY(Category = "Fish | Physical", Meta=(Units="cm"), VisibleAnywhere)
    float Size = 10.0f;

    UPROPERTY(Category = "Fish | Physical", Meta=(Units="kg"), VisibleAnywhere)
    float Weight = 0.5f;

    UPROPERTY(Category = "Fish | Physical", NotVisible)
    bool IsTiny;

    UPROPERTY(Category = "Fish | Physical", NotVisible)
    bool IsLarge;

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
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (RequiredBaits.Num() == 0)
        {
            PrintError("Fish " + FishName.ToString() + " has no required baits set!");
            return;
        }

        // Randomize size and weight within span
        Size = Math::RandRange(SizeSpan.X, SizeSpan.Y);
        Weight = Size * 0.1f; // Simple formula: weight is 10% of size

        Size = RoundTo(Size, 2);
        Weight = RoundTo(Weight, 2);

        float SpanMin = SizeSpan.X;
        float SpanMax = SizeSpan.Y;
        float SpanRange = Math::Max(0.0001f, SpanMax - SpanMin); // avoid division by zero
        float Normalized = (Size - SpanMin) / SpanRange;

        // considered Tiny if in lowest 25% of the span, Large if in highest 25%
        IsTiny = Normalized < 0.25f;
        IsLarge = Normalized > 0.75f;
    }

    void OnCaught(AFishCharacter Catcher)
    {
		FString SizeInformation = IsTiny ? "Tiny" : (IsLarge ? "Large" : "Normal");
		FString HookInformation = f"{GetName()} \nSize: {Size} cm \nWeight: {Weight} kg \nType: {FishType} \nRarity: {Rarity} \nSize Category: {SizeInformation}";
		Print(f"{Catcher.ActorNameOrLabel} ({Catcher.PlayerState.PlayerId}) caught a {HookInformation}", 3.5f, FLinearColor::DPink);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Reeled In")
    void BP_OnCaught(AFishCharacter Catcher) { }
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
    Relic,
    Legendary // quest-only
}