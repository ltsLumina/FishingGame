class UAbilityData : UPrimaryDataAsset
{
    UPROPERTY()
    FAbilityDetails Details;
};

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

struct FCooldownType
{
    UPROPERTY()
    ECooldownType Type;
    
    UPROPERTY(Meta = (EditCondition = "Type == ECooldownType::oGCD", EditConditionHides, ClampMin = "0", ClampMax="120", Delta="10"))
    float Duration = 2.5f;
}

enum ECooldownType
{
    GCD UMETA(DisplayName = "Global Cooldown"),
    oGCD UMETA(DisplayName = "Off-Global Cooldown"),
}

struct FCostType
{
    UPROPERTY()
    ECostType Type;
    
    UPROPERTY(Meta = (EditCondition = "Type != ECostType::None", EditConditionHides, ClampMin = "0", ClampMax="20000", Delta="100"))
    int Amount;
}

enum ECostType
{
    None,
    MP,
    ThaliaksFavor,
}