/**
 * A utility class for percentage calculations.
 */
class UPercent
{

}

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

UFUNCTION(BlueprintPure, Category = "Math")
float AddPercent(float BaseValue, float PercentToAdd)
{
    return BaseValue * (1.0f + ToPercent(PercentToAdd));
}

UFUNCTION(BlueprintPure, Category = "Math")
float SubtractPercent(float BaseValue, float PercentToSubtract)
{
    return BaseValue * (1.0f - ToPercent(PercentToSubtract));
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