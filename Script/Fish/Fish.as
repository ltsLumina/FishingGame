namespace Fish
{
    float GetRarityWeight(AFish Fish)
    {
        EFishRarity Rarity = Fish.Rarity;

        switch (Rarity)
        {
            case EFishRarity::Basic:
                return 100.0f;
            case EFishRarity::Aetherial:
                return 75.0f;
            case EFishRarity::Dungeon:
                return 50.0f;
            case EFishRarity::Tomestone:
                return 30.0f;
            case EFishRarity::Relic:
                return 15.0f;
            case EFishRarity::Legendary:
                return Fish.RarityWeight;
            default:
                return 100.0f;
        }
    }
}

UCLASS(Abstract)
class AFish : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Mesh;

    /**
     * The inventory data for this fish.
     */
    UPROPERTY(Category = "Fish | Info", NotVisible)
    FFishInfo FishInfo;

    UPROPERTY(Category = "Fish | Info", DisplayName = "Name")
    FText FishName = FText::FromString("Default Fish");

    UPROPERTY(Category = "Fish | Info", Meta=(MultiLine))
    FText Description = FText::FromString("A generic fish. \nNothing special about it.");

    UPROPERTY(Category = "Fish | Info")
    TArray<UBait> RequiredBaits;

    /**
     * Time it takes for this fish to bite (in seconds).
     */
    UPROPERTY(Category = "Fish | Info", Meta=(Units="s"))
    float BiteTime = 5;

    /**
     * Chance to catch this (0-100).
     * If the catch fails, the fish escapes.
     */
    UPROPERTY(Category = "Fish | Info", Meta=(UIMin="0.0", UIMax="100.0", Delta="0.5", Units="%"))
    float CatchRate = 95.0f;

    float CurrentCatchRate;

    /**
     * Recommended player level to catch this fish.
     * Does not restrict catching; purely informational.
     */
    UPROPERTY(Category = "Fish | Info", Meta=(UIMin="1", UIMax="100", Delta="1"))
    int RecommendedLevel = 1;

    UPROPERTY(Category = "Fish | Info", Meta=(UIMin="0", UIMax="1000", Delta="1"))
    int MinimumGathering = 0;

    /**
     * Which area types this fish can be found in.
     * Only cosmetic.
     */
    UPROPERTY(Category = "Fish | Info")
    EFishType FishType = EFishType::Freshwater;

    UPROPERTY(Category = "Fish | Info")
    EFishRarity Rarity = EFishRarity::Basic;

    UPROPERTY(Category = "Fish | Info", Meta=(UIMin="0.0", UIMax="100.0", Delta="0.5", Units="%", EditCondition ="Rarity == EFishRarity::Legendary", EditConditionHides))
    float RarityWeight = 100.0f;

    UPROPERTY(Category = "Fish | Info", EditInline, Instanced)
    TArray<UFishCondition> Conditions;

    /**
     * Sell price to vendors.
     */
    UPROPERTY(Category = "Fish | Shop")
    int VendorValue = 1;

    /**
     * Size span of the fish (min and max size in cm).
     */
    UPROPERTY(Category = "Fish | Physical", Meta=(Units="cm"))
    FVector2D SizeSpan = FVector2D(5.0f, 15.0f);

    UPROPERTY(Category = "Fish | Physical", Meta=(Units="cm"), VisibleAnywhere)
    float Size = 10.0f;

    UPROPERTY(Category = "Fish | Physical", Meta=(Units="kg"), VisibleAnywhere)
    float Weight = 0.5f;

    UPROPERTY(Category = "Fish | Physical", NotVisible)
    bool IsTiny;

    UPROPERTY(Category = "Fish | Physical", NotVisible)
    bool IsLarge;

    default Replicates = true;

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

        FishInfo = FFishInfo(this);
    }

    void OnCaught(AFishCharacter Catcher)
    {
		FString SizeInformation = IsTiny ? "Tiny" : (IsLarge ? "Large" : "Normal");
		FString HookInformation = f"{GetName()} \nSize: {Size} cm \nWeight: {Weight} kg \nType: {FishType} \nRarity: {Rarity} \nSize Category: {SizeInformation}";
		Print(f"{Catcher.ActorNameOrLabel} caught a {HookInformation}", 3.5f, FLinearColor::DPink);
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
    /**
     * 100% catch rate weight.
     */
    Basic,
    /**
     * 75% catch rate weight
     */
    Aetherial,
    /**
     * 50% catch rate weight.
     */
    Dungeon,
    /**
     * 30% catch rate weight.
     */
    Tomestone,
    /**
     * 15% catch rate weight.
     */
    Relic,
    /**
     * Legendary fish are obtained through quests only.
     * 5% catch rate weight.
     */
    UMETA(DisplayName="Legendary (Quest)")
    Legendary
}