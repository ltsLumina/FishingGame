class UFishItem : UItem
{
    UPROPERTY(Category = "Fish | Info", ExposeOnSpawn, SaveGame)
	FFishItemData FishData;

	void Init(AFish Fish)
    {
		BaseData.ID = GenerateItemID(Fish.FishName);
		BaseData.ItemName = Fish.FishName;
		BaseData.Description = Fish.Description;
		BaseData.Thumbnail = Fish.Thumbnail;

        FishData.FishClass = Fish.GetClass();
		FishData.RecommendedLevel = Fish.RecommendedLevel;
		FishData.FishType = Fish.FishType;
		FishData.Rarity = Fish.Rarity;
		FishData.PreferredBaits = Fish.RequiredBaits;
		FishData.VendorValue = Fish.VendorValue;
		FishData.Size = Fish.Size;
		FishData.Weight = Fish.Weight;
		FishData.IsTiny = Fish.IsTiny;
		FishData.IsLarge = Fish.IsLarge;
    }
}

struct FFishItemData
{
	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, SaveGame)
    TSubclassOf<AFish> FishClass;

	/**
	 * Recommended player level to catch this fish.
	 * Does not restrict catching; purely informational.
	 */
	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "1", UIMax = "100"), VisibleAnywhere, SaveGame)
	int RecommendedLevel = 1;

	/**
	 * Which area types this fish can be found in.
	 * Only cosmetic.
	 */
	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, SaveGame)
	EFishType FishType = EFishType::Freshwater;

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, SaveGame)
	EFishRarity Rarity = EFishRarity::Basic;

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, SaveGame)
	TArray<UBait> PreferredBaits;

	/**
	 * Sell price to vendors.
	 */
	UPROPERTY(Category = "Fish | Shop", VisibleAnywhere, SaveGame)
	int VendorValue = 1;

	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "cm"), VisibleAnywhere, SaveGame)
	float Size = 10.0f;

	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "kg"), VisibleAnywhere, SaveGame)
	float Weight = 0.5f;
	
	UPROPERTY(Category = "Fish | Physical", VisibleInstanceOnly, SaveGame)
    bool IsTiny;

    UPROPERTY(Category = "Fish | Physical", VisibleInstanceOnly, SaveGame)
    bool IsLarge;
}