event void FOnInventoryChanged(FFishInfo FishInfo, EInventoryChangeType Change);

enum EInventoryChangeType
{
	Added,
	Removed
};

class UInventoryComponent : UActorComponent
{
	UPROPERTY(Category = "Inventory", VisibleAnywhere)
	TArray<FFishInfo> Items;

    UPROPERTY(Category = "Inventory")
    FOnInventoryChanged OnInventoryChanged;

	default IsReplicated = true;
	default bReplicates = true;

	UFUNCTION(Category = "Inventory")
	void AddItem(FFishInfo FishInfo)
	{
		Items.Add(FishInfo);
        Print("Added fish to inventory: " + FishInfo.FishName.ToString(), 1.0);
        OnInventoryChanged.Broadcast(FishInfo, EInventoryChangeType::Added);
	}

	UFUNCTION(Category = "Inventory")
	bool RemoveItem(FName ID)
    {
        for (int i = 0; i < Items.Num(); i++)
        {
            if (Items[i].FishID == ID)
            {
                Items.RemoveAt(i);
                Print("Removed fish from inventory: " + ID.ToString());
                OnInventoryChanged.Broadcast(FFishInfo(), EInventoryChangeType::Removed);
                return true;
            }
        }
        return false;
    }

	UFUNCTION(Category = "Inventory", BlueprintPure, Meta = (CompactNodeTitle = "Contains", Keywords = "has,find"))
	bool Contains(TSubclassOf<AFish> FishClass)
	{
		for (auto& Pair : Items)
        {
            if (Pair.FishClass == FishClass)
            {
                return true;
            }
        }
        return false;
	}

	UFUNCTION(Category = "Inventory", BlueprintPure, Meta = (CompactNodeTitle = "Quantity", Keywords = "count,number"))
	int GetItemQuantity(TSubclassOf<AFish> FishClass)
	{
		int Quantity = 0;
        for (auto& Pair : Items)
        {
            if (Pair.FishClass == FishClass)
            {
                Quantity++;
            }
        }
        return Quantity;
	}
};

/**
 * Data structure to hold fish inventory data.
 */
struct FFishInfo
{
	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly)
	TSubclassOf<AFish> FishClass;

    UPROPERTY(Category = "Fish | Info", DisplayName = "ID", VisibleAnywhere, BlueprintReadOnly)
    FName FishID;

	UPROPERTY(Category = "Fish | Info", DisplayName = "Name", BlueprintReadOnly)
	FText FishName = FText::FromString("Default Fish");

	UPROPERTY(Category = "Fish | Info", Meta = (MultiLine), BlueprintReadOnly)
	FText Description = FText::FromString("A generic fish. \nNothing special about it.");

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly)
	UTexture2D Thumbnail;

	/**
	 * Recommended player level to catch this fish.
	 * Does not restrict catching; purely informational.
	 */
	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "1", UIMax = "100"), VisibleAnywhere, BlueprintReadOnly)
	int RecommendedLevel = 1;

	/**
	 * Which area types this fish can be found in.
	 * Only cosmetic.
	 */
	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly)
	EFishType FishType = EFishType::Freshwater;

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly)
	EFishRarity Rarity = EFishRarity::Basic;

	/**
	 * Sell price to vendors.
	 */
	UPROPERTY(Category = "Fish | Shop", VisibleAnywhere, BlueprintReadOnly)
	int VendorValue = 1;

	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "cm"), VisibleAnywhere, BlueprintReadOnly)
	float Size = 10.0f;

	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "kg"), VisibleAnywhere, BlueprintReadOnly)
	float Weight = 0.5f;

	FFishInfo()
	{}

	FFishInfo(AFish Fish)
	{
        FishClass = Fish.GetClass();
        FishID = FName(FGuid::NewGuid().ToString());
		FishName = Fish.FishName;
		Description = Fish.Description;
		Thumbnail = Fish.Thumbnail;
		RecommendedLevel = Fish.RecommendedLevel;
		FishType = Fish.FishType;
		Rarity = Fish.Rarity;
		VendorValue = Fish.VendorValue;
		Size = Fish.Size;
		Weight = Fish.Weight;
	}
}