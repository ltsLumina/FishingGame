/**
 * Defined in angelscript because it was easier to setup than doing it in Blueprint.
 */
class USpecificFish : UQuestObjective
{
	UPROPERTY(Category = "Quest | Objective", DisplayName = "Fish")
	TSubclassOf<AFish> FishClass;

	UPROPERTY(Category = "Quest | Objective", Meta = (UIMin = "1", UIMax = "100", Delta = "1"))
	int Quantity = 1;

	UPROPERTY(Category = "Quest | Objective", Meta = (InlineEditConditionToggle))
	bool HasWeightThreshold;

	UPROPERTY(Category = "Quest | Objective", Meta = (EditCondition = "HasWeightThreshold", Units = "kg"), DisplayName = "Weight Threshold")
	float Weight = 1;

	UPROPERTY(Category = "Quest | Objective")
	bool IsLarge;

	UFUNCTION(BlueprintOverride)
	bool IsSatisfied(AFishCharacter User)
	{
		UInventoryComponent Inventory = UInventoryComponent::Get(User.PlayerState);
		auto CDO = FishClass.DefaultObject;

		int CurrentQuantity = Inventory.GetItemQuantity(CDO.FishID);
		bool bMeetsQuantity = CurrentQuantity >= Quantity;

		bool bMeetsWeight = false;
		for (auto& Info : Inventory.Items)
		{
			if (Cast<UFishItem>(Info).FishClass != FishClass)
				continue;

			if (Cast<UFishItem>(Info).Weight >= Weight)
			{
				bMeetsWeight = true;
				break;
			}
		}

		if (bMeetsQuantity && (!HasWeightThreshold || bMeetsWeight))
		{
			return true;
		}

		return false;
	}
}