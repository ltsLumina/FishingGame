/**
 * Compares two UObject references for equality.
 * @param Result Optional output parameter that will contain the result of the comparison.
 * @return True if both references point to the same object, false otherwise.
 */
UFUNCTION(Meta = (ExpandBoolAsExecs = "ReturnValue", CompactNodeTitle = "=="))
bool Equals(UObject A, UObject B, bool&out Result)
{
    Result = A == B;
    return A == B;
}