/**
 * Defined in angelscript because it was easier to setup than doing it in Blueprint.
 */
class USpecificFish : UQuestObjective
{
	UPROPERTY(Category = "Quest | Objective", DisplayName = "Fish")
	TSubclassOf<AFish> FishClass;

	UPROPERTY(Category = "Quest | Objective", Meta = (UIMin = "1", UIMax = "100", Delta = "1"))
	int Quantity = 1;

	UPROPERTY(Category = "Quest | Objective")
	bool IsLarge;

	UFUNCTION(BlueprintOverride)
	bool IsSatisfied(AFishCharacter User)
	{
		UInventoryComponent Inventory = UInventoryComponent::Get(User.PlayerState);
		auto CDO = FishClass.DefaultObject;

		int CurrentQuantity = Inventory.GetItemQuantity(CDO.FishID);
		bool bMeetsQuantity = CurrentQuantity >= Quantity;

		bool bMeetsSize = false;
		for (auto& Info : Inventory.Items)
		{
			if (Cast<UFishItem>(Info).FishClass != FishClass)
				continue;

			if (Cast<UFishItem>(Info).IsLarge == IsLarge)
			{
				bMeetsSize = true;
				break;
			}
		}

		if (bMeetsQuantity && bMeetsSize)
		{
			return true;
		}

		return false;
	}
}