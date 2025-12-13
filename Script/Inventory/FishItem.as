UCLASS(Meta = (PrioritizeCategories = "Item"))
class UFishItem : UItem
{
	UPROPERTY(Category = "Fish", ExposeOnSpawn, SaveGame)
	FFishItemData FishData;

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	TSubclassOf<AFish> GetFishClass()
	{
		return FishData.FishClass;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	int GetRecommendedLevel()
	{
		return FishData.RecommendedLevel;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	int GetMinimumGathering()
	{
		return FishData.MinimumGathering;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	float GetExperienceValue()
	{
		return FishData.ExperienceValue;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	int GetVendorValue()
	{
		return FishData.VendorValue;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	EFishType GetFishType()
	{
		return FishData.FishType;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	EFishRarity GetRarity()
	{
		return FishData.Rarity;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	TArray<UBait> GetPreferredBaits()
	{
		return FishData.PreferredBaits;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	float GetCatchRate()
	{
		return FishData.CatchRate;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	bool GetIsMoochable()
	{
		return FishData.IsMoochable;
	}

	UFUNCTION(Category = "Fish | Info", BlueprintPure)
	FVector2D GetSizeSpan()
	{
		return FishData.SizeSpan;
	}
}

USTRUCT(Meta = (HiddenByDefault))
struct FFishItemData
{
	UPROPERTY(Category = "Fish | Info", SaveGame)
	TSubclassOf<AFish> FishClass;

	/**
	 * Time it takes for this fish to bite (in seconds).
	 */
	UPROPERTY(Category = "Fish | Info", Meta = (Units = "s", UIMin = "5.0", UIMax = "30.0", Delta = "0.5"))
	float BiteTime = 5; // NOT IN DATA, KEEP

	/**
	 * Chance to catch this (0-100).
	 * If the catch fails, the fish escapes.
	 */
	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "0.0", UIMax = "100.0", Delta = "0.5", Units = "%"))
	float CatchRate = 95.0f; // NOT IN DATA, KEEP

	/**
	 * Recommended player level to catch this fish.
	 * Does not restrict catching; purely informational.
	 */
	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "1", UIMax = "100"), SaveGame)
	int RecommendedLevel = 1;

	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "0", UIMax = "1000", Delta = "1"))
	int MinimumGathering = 0; // NOT IN DATA, KEEP

	/**
	 * Experience points awarded when this fish is caught.
	 */
	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "0", UIMax = "1000", Delta = "1"))
	float ExperienceValue = 10; // NOT IN DATA, KEEP

	/**
	 * Which area types this fish can be found in.
	 * Only cosmetic.
	 */
	UPROPERTY(Category = "Fish | Info", SaveGame)
	EFishType FishType = EFishType::Freshwater;

	UPROPERTY(Category = "Fish | Info", SaveGame)
	EFishRarity Rarity = EFishRarity::Basic;

	UPROPERTY(Category = "Fish | Info", SaveGame)
	TArray<UBait> PreferredBaits;

	UPROPERTY(Category = "Fish | Info", Meta = (UIMin = "0.0", UIMax = "100.0", Delta = "0.5", Units = "%", EditCondition = "Rarity == EFishRarity::Legendary", EditConditionHides))
	float LegendaryWeight = 100.0f;														 // NOT IN DATA, KEEP

	UPROPERTY(Category = "Fish | Info", EditDefaultsOnly, DisplayName = "Moochable") // NOT IN DATA, KEEP
	bool IsMoochable;

	UPROPERTY(Category = "Fish | Info", EditInline)
	TArray<UFishCondition> Conditions; // NOT IN DATA, KEEP

	/**
	 * Sell price to vendors.
	 */
	UPROPERTY(Category = "Fish | Shop", SaveGame)
	int VendorValue = 1;

	/**
	 * Size span of the fish (min and max size in cm).
	 */
	UPROPERTY(Category = "Fish | Physical", Meta = (Units = "cm")) // NOT IN DATA, KEEP
	FVector2D SizeSpan = FVector2D(5.0f, 15.0f);
}

struct FFishSizeData
{
	UPROPERTY(Category = "Fish | Physical")
	float Size = 0.0f;

	UPROPERTY(Category = "Fish | Physical")
	float Weight = 0.0f;

	UPROPERTY(Category = "Fish | Physical")
	bool IsTiny = false;

	UPROPERTY(Category = "Fish | Physical")
	bool IsLarge;

	UPROPERTY(Category = "Fish | Physical")
	int VendorValue = 0;

	FFishSizeData(float InSize = 0.0f, float InWeight = 0.0f, bool InIsTiny = false, bool InIsLarge = false, int InVendorValue = 0)
	{
		Size = InSize;
		Weight = InWeight;
		IsTiny = InIsTiny;
		IsLarge = InIsLarge;
		VendorValue = InVendorValue;
	}
}

UFUNCTION(BlueprintPure, Category = "Fish | Info")
int GetVendorValue(FFishSizeData SizeData, UFishItem FishItem)
{
	auto Data = FishItem.FishData;
	return Math::RoundToInt((SizeData.Size + SizeData.Weight) * 2 * Math::Max(1,float(Data.Rarity))); // Simple formula: (size + weight) * 2 * rarity
}