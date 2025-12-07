class UBait : UPrimaryDataAsset
{
    UPROPERTY(DisplayName = "Name")
    FText BaitName;
    default BaitName = FText::FromName(Class.GetName());

    UPROPERTY(Meta=(MultiLine))
    FText Description;

    UPROPERTY()
    UTexture2D Icon;

    UPROPERTY()
    int Price = 10;
}

UFUNCTION(Meta=(ExpandBoolAsExecs="ReturnValue"))
bool CompareBait(UBait A, UBait B)
{
    return A == B;
}