UCLASS(Abstract, EditInlineNew)
class UQuestObjective : UObject
{
	UFUNCTION(BlueprintEvent)
	bool IsSatisfied(AFishCharacter User)
	{
		return true;
	}
};