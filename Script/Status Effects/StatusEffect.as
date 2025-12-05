class UStatusEffect : UPrimaryDataAsset
{
    UPROPERTY(Category = "Details")
    FText Name;

    UPROPERTY(Category = "Details", Meta = (MultiLine))
    FText Description;

    UPROPERTY(Category = "Visuals")
    UTexture2D Icon;
};