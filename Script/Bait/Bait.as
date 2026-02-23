namespace Bait
{
	const float TIER_1_SPECTRAL_CHANCE = 5;
	const float TIER_2_SPECTRAL_CHANCE = 10;
	const float TIER_3_SPECTRAL_CHANCE = 15;
	const float DEBUG_SPECTRAL_CHANCE = 100;

	float GetSpectralChance(UBait Bait)
	{
		switch (Bait.SpectralTier)
		{
			case ESpectralTier::Tier1:
				return TIER_1_SPECTRAL_CHANCE;
			case ESpectralTier::Tier2:
				return TIER_2_SPECTRAL_CHANCE;
			case ESpectralTier::Tier3:
				return TIER_3_SPECTRAL_CHANCE;
			case ESpectralTier::DEBUG:
				return DEBUG_SPECTRAL_CHANCE;
			default:
				return 0.0f;
		}
	}

	UFUNCTION(Meta = (ExpandBoolAsExecs = "ReturnValue"))
	bool CompareBait(UBait A, UBait B)
	{
		return A == B;
	}

	UFUNCTION()
	bool HasBait(UBait BaitToCheck, TArray<UBait> BaitArray)
	{
		for (UBait Bait : BaitArray)
		{
			if (CompareBait(Bait, BaitToCheck))
			{
				return true;
			}
		}
		return false;
	}
}

class UBait : UPrimaryDataAsset
{
	UPROPERTY(DisplayName = "Name")
	FText BaitName;
	default BaitName = FText::FromName(Class.GetName());

	UPROPERTY(Meta = (MultiLine))
	FText Description;

	UPROPERTY()
	UTexture2D Icon;

	UPROPERTY()
	int Price = 10;

	UPROPERTY(Category = "Spectral")
	bool IsSpectral;

	UPROPERTY(Category = "Spectral", Meta = (EditCondition = "IsSpectral", EditConditionHides))
	ESpectralTier SpectralTier = ESpectralTier::Tier1;
}

enum ESpectralTier
{
	UMETA(Hidden)
	None,
	Tier1, // 5% chance
	Tier2, // 10% chance
	Tier3, // 15% chance
	DEBUG
}