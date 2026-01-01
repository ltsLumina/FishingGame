/**
 * Converts a value to a percentage (decimal)
 * @param Value The whole value to convert to a percentage (to decimal)
 * @return The percentage value (as a decimal, e.g. 0.25 for 25%)
 */
UFUNCTION(BlueprintPure, Category = "Math")
float ToPercent(float Value)
{
    return Value / 100.0f;
}

UFUNCTION(BlueprintPure)
float FromPercent(float Percent)
{
    return Percent * 100.0f;
}

UFUNCTION(BlueprintPure, Category = "Math", Meta=(CompactNodeTitle="Add %"))
float AddPercentMultiplicative(float& BaseValue, float PercentToAdd)
{
    BaseValue += (BaseValue * ToPercent(PercentToAdd));
    return BaseValue;
}

UFUNCTION(BlueprintPure, Category = "Math", Meta=(CompactNodeTitle="Add %"))
float AddPercentAdditive(float& BaseValue, float PercentToAdd)
{
    BaseValue += ToPercent(PercentToAdd);
    return BaseValue;
}

UFUNCTION(BlueprintPure, Category = "Math", Meta=(CompactNodeTitle="Subtract %"))
float SubtractPercentMultiplicative(float& BaseValue, float PercentToSubtract)
{
    BaseValue -= (BaseValue * ToPercent(PercentToSubtract));
    return BaseValue;
}

UFUNCTION(BlueprintPure, Category = "Math", Meta=(CompactNodeTitle="Subtract %"))
float SubtractPercentAdditive(float& BaseValue, float PercentToSubtract)
{
    BaseValue -= ToPercent(PercentToSubtract);
    return BaseValue;
}

/**
 * Rolls a percentage chance
 * @param PercentChance The chance percentage (0-100)
 * @return True if the roll was successful, false otherwise
 */
UFUNCTION(BlueprintPure, Category = "Math | Probability")
bool RollPercentChance(float PercentChance)
{
    float Roll = Math::RandRange(0.0f, 100.0f);
    return Roll < PercentChance;
}