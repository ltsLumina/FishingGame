USTRUCT()
struct FAbilityDetails
{
    UPROPERTY()
    FText Name;
    
    UPROPERTY()
    FText Description;

    UPROPERTY()
    UTexture2D Icon;

    UPROPERTY()
    FCooldownType Cooldown;
    
    UPROPERTY()
    FCostType Cost;
};