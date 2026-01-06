struct FStatusEffect
{
    UPROPERTY(Category = "Details", BlueprintReadOnly)
    FGameplayTag Tag;

    UPROPERTY(Category = "Details", BlueprintReadOnly)
    bool DisplayMaxStackCount = true;

    UPROPERTY(Category = "Details")
    FText EffectName;

    UPROPERTY(Category = "Details", Meta = (MultiLine))
    FText Description;

    UPROPERTY(Category = "Visuals")
    UTexture2D Icon;
};