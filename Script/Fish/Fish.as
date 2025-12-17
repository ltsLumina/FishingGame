namespace Fish
{
	const float BASIC_WEIGHT = 100.0f;
	const float AETHERIAL_WEIGHT = 75.0f;
	const float PRISMATIC_WEIGHT = 50.0f;
	const float SERAPHIC_WEIGHT = 30.0f;
	const float IRIDESCENT_WEIGHT = 15.0f;

	float GetRarityWeight(UFishItem FishItem)
	{
		EFishRarity Rarity = FishItem.FishData.Rarity;

		switch (Rarity)
		{
			case EFishRarity::Basic:
				return Fish::BASIC_WEIGHT;
			case EFishRarity::Aetherial:
				return Fish::AETHERIAL_WEIGHT;
			case EFishRarity::Prismatic:
				return Fish::PRISMATIC_WEIGHT;
			case EFishRarity::Seraphic:
				return Fish::SERAPHIC_WEIGHT;
			case EFishRarity::Iridescent:
				return Fish::IRIDESCENT_WEIGHT;
			case EFishRarity::Legendary:
				return FishItem.FishData.LegendaryWeight;
			default:
				return 100.0f;
		}
	}

	namespace Tag
	{
		const float UMBRAL_CHANCE = 0.05f;
		const float ASTRAL_CHANCE = 0.05f;

		UFUNCTION(BlueprintPure, Category = "Fish | Tag")
		EFishTag GetRandomTag()
		{
			float Roll = Math::RandRange(0.0f, 1.0f);
			if (Roll < UMBRAL_CHANCE)
				return EFishTag::Umbral;
			else if (Roll < UMBRAL_CHANCE + ASTRAL_CHANCE)
				return EFishTag::Astral;
			else
				return EFishTag::None;
		}
	}
}

UCLASS(Abstract, NotPlaceable, ClassGroup = "Fishing", Meta = (PrioritizeCategories = "Fish"))
class AFish : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Fish")
	UFishItem Item;

	UPROPERTY(Category = "Fish", NotVisible)
	FFishSizeData SizeData;

	UPROPERTY(Category = "Fish", VisibleAnywhere)
	EFishTag Tag;

	default bReplicates = true;

	void Spawn(UFishItem InItem)
	{
		Item = InItem;

		auto Data = Item.FishData;

		Mesh.SetStaticMesh(Data.Mesh);

		if (Data.PreferredBaits.Num() == 0)
		{
			PrintError(f"{Item.BaseData.ItemName} has no required baits set!");
			return;
		}

		// Randomize size and weight within span
		float Size = Math::RandRange(Data.SizeSpan.X, Data.SizeSpan.Y);
		float Weight = Size * 0.1f; // Simple formula: weight is 10% of size

		Size = RoundTo(Size, 2);
		Weight = RoundTo(Weight, 2);

		float SpanMin = Data.SizeSpan.X;
		float SpanMax = Data.SizeSpan.Y;
		float SpanRange = Math::Max(0.0001f, SpanMax - SpanMin); // avoid division by zero
		float Normalized = (Size - SpanMin) / SpanRange;

		// considered Tiny if in lowest 25% of the span, Large if in highest 25%
		bool IsTiny = Normalized < 0.25f;
		bool IsLarge = Normalized > 0.75f;

		int VendorValue = Math::RoundToInt((Size + Weight) * 2 * Math::Max(1, float(Data.Rarity))); // Simple formula: (size + weight) * 2 * rarity

		SizeData = FFishSizeData(Size, Weight, IsTiny, IsLarge, VendorValue);
		Tag = Fish::Tag::GetRandomTag();
	}

	void OnCaught(AFishCharacter Catcher)
	{
		auto FishData = Item.FishData;

		FString SizeInformation = SizeData.IsTiny ? "Tiny" : (SizeData.IsLarge ? "Large" : "Normal");
		FString HookInformation = f"{Item.GetItemName()} \nSize: {SizeData.Size} cm \nWeight: {SizeData.Weight} kg \nType: {FishData.FishType} \nRarity: {FishData.Rarity} \nSize Category: {SizeInformation} \nTag: {Tag:n}";
		Print(f"{Catcher.ActorNameOrLabel} caught a {HookInformation}", 3.5f, FLinearColor::DPink);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Reeled In")
	void BP_OnCaught(AFishCharacter Catcher)
	{}
};

enum EFishType
{
	Freshwater,
	Saltwater,
	Brackish,
	Tropical,
	Coldwater
}

enum EFishRarity
{
	/**
	 * 100% spawn rate weight.
	 */
	Basic,
	/**
	 * 75% spawn rate weight.
	 */
	Aetherial,
	/**
	 * 50% spawn rate weight.
	 */
	Prismatic,
	/**
	 * 30% spawn rate weight.
	 */
	Seraphic,
	/**
	 * 15% spawn rate weight.
	 */
	Iridescent,
	/**
	 * Legendary fish are obtained through quests only.
	 * 5% spawn rate weight (when obtainable).
	 */
	UMETA(DisplayName = "Legendary (Quest)")
	Legendary
}