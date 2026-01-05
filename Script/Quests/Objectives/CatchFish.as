/**
 * Requires the player to catch a specific type and quantity of fish, optionally large size.
 */
UCLASS(Abstract)
class UCatchFishObjective : UQuestObjective
{
	UPROPERTY(Category = "Quest | Objective", DisplayName = "Fish")
	UFishItem Fish;
	
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
			if (!Slot.IsValid())
				continue;

			if (Slot.Item.BaseData.ID != BaseData.ID) // wrong fish
				continue;

			if (Slot.InstanceData.FishInstanceData.SizeData.IsLarge && IsLarge)
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