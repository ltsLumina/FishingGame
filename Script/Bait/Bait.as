class UBait : UPrimaryDataAsset
{
    UPROPERTY()
    FText BaitName;
    default BaitName = FText::FromName(Class.GetName());

    UPROPERTY(Meta=(MultiLine))
    FText Description;

    UPROPERTY()
    UTexture2D Icon;
}