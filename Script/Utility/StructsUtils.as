struct FMinMaxInt
{
    UPROPERTY()
    int Min;
    UPROPERTY()
    int Max;

    FMinMaxInt(int InMin, int InMax)
    {
        Min = InMin;
        Max = InMax;
    }
};

struct FMinMaxFloat
{
    UPROPERTY(BlueprintReadOnly)
    float Min;
    UPROPERTY(BlueprintReadOnly)
    float Max;
};