class UFishingRod : UPrimaryDataAsset
{
    UPROPERTY(Category = "Details")
    FRodDetails Details;
};

struct FRodDetails
{
    UPROPERTY()
    FText Name;

    UPROPERTY(Meta = (MultiLine))
    FText Description;

    /**
     * The effect that the rod has when used, e.g., "Increases fishing speed by 20%."
     */
    UPROPERTY(Meta = (MultiLine))
    FText Effect;

    UPROPERTY()
    UTexture2D Icon;

    UPROPERTY()
    UAbilityData Ability;

    UPROPERTY()
    UQuest UnlockQuest;
};