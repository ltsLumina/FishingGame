UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UQuestObjective : UObject
{
	UFUNCTION(BlueprintEvent)
	bool IsSatisfied(AFishCharacter User)
	{
		return true;
	}
};