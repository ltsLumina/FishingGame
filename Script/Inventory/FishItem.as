class UFishItem : UItem
{
    UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly)
    TSubclassOf<AFish> FishClass;

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
	UPROPERTY(Category = "Fish | Shop", VisibleAnywhere, BlueprintReadOnly, ExposeOnSpawn)
	int VendorValue = 1;

	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "cm"), VisibleAnywhere, BlueprintReadOnly)
	float Size = 10.0f;

	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "kg"), VisibleAnywhere, BlueprintReadOnly)
	float Weight = 0.5f;
	
	UPROPERTY(Category = "Fish | Physical", VisibleInstanceOnly)
    bool IsTiny;

    UPROPERTY(Category = "Fish | Physical", VisibleInstanceOnly, ExposeOnSpawn)
    bool IsLarge;

	void Init(AFish Fish)
    {
		ID = Fish.FishID;
		ItemName = Fish.FishName;
        Description = Fish.Description;
        Thumbnail = Fish.Thumbnail;
        
        FishClass = Fish.GetClass();
		RecommendedLevel = Fish.RecommendedLevel;
		FishType = Fish.FishType;
		Rarity = Fish.Rarity;
		VendorValue = Fish.VendorValue;
		Size = Fish.Size;
		Weight = Fish.Weight;
		IsTiny = Fish.IsTiny;
		IsLarge = Fish.IsLarge;
    }
}