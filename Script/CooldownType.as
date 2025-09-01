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