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