/**
 * Defined in angelscript because it was easier to setup than doing it in Blueprint.
 */
class USpecificFish : UQuestObjective
{
	UPROPERTY(Category = "Quest | Objective", DisplayName = "Fish")
	UFishItem Fish; // TODO: Change to FishItem later?

	UPROPERTY(Category = "Quest | Objective", Meta = (UIMin = "1", UIMax = "100", Delta = "1"))
	int Quantity = 1;

	UPROPERTY(Category = "Quest | Objective")
	bool IsLarge;

	UFUNCTION(BlueprintOverride)
	bool IsSatisfied(AFishCharacter User)
	{
		UInventoryComponent Inventory = UInventoryComponent::Get(User.PlayerState);
		auto BaseData = Fish.BaseData;

		int CurrentQuantity = Inventory.GetItemQuantity(BaseData.ID);
		bool bMeetsQuantity = CurrentQuantity >= Quantity;

		bool bMeetsSize = false;
		for (auto& Slot : Inventory.Items)
		{
			auto FishItem = Cast<UFishItem>(Slot);
			if (FishItem == nullptr) // if its not a fish,
				continue;

			if (FishItem.BaseData.ID != BaseData.ID) // wrong fish
				continue;

			if (Slot.GetFishSizeData().IsLarge && IsLarge)
			{
				bMeetsSize = true;
				break;
			}
		}

		if (bMeetsQuantity && (!IsLarge || bMeetsSize))
		{
			return true;
		}

		return false;
	}
}