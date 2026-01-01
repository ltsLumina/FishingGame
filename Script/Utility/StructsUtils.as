struct FMinMaxInt
{
    UPROPERTY()
    int Min;
    UPROPERTY()
    int Max;
};

struct FMinMaxFloat
{
    UPROPERTY(BlueprintReadOnly)
    float Min;
    UPROPERTY(BlueprintReadOnly)
    float Max;
};