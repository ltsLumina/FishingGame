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

	float GetRarityWeight(EFishRarity Rarity)
	{
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
			default:
				return 100.0f;
		}
	}

	namespace InstanceData
	{
		/**
		 * Makes an instance data for a fish item, including a random tag and size data based on its item data.
		 * @note The values are not random (besides tag, which is always randomized). They are generated based on the fish item data.
		 */
		UFUNCTION(BlueprintPure, Category = "Fish | Instance Data")
		FFishInstanceData MakeFishInstanceData(FFishItemData FishItemData)
		{
			FFishInstanceData InstanceData;
			InstanceData.Tag = Fish::InstanceData::Tag::RollTag();
			InstanceData.SizeData = Fish::InstanceData::Size::CalculateSize(FishItemData);
			return InstanceData;
		}

		UFUNCTION(Category = "Fish | Size", BlueprintPure)
		mixin bool GetIsTiny(FFishInstanceData& FishInstanceData)
		{
			return FishInstanceData.SizeData.IsTiny;
		}

		UFUNCTION(Category = "Fish | Size", BlueprintPure)
		mixin bool GetIsLarge(FFishInstanceData& FishInstanceData)
		{
			return FishInstanceData.SizeData.IsLarge;
		}

		UFUNCTION(Category = "Fish | Size", BlueprintPure)
		mixin float GetSize(FFishInstanceData& FishInstanceData)
		{
			return FishInstanceData.SizeData.Size;
		}

		UFUNCTION(Category = "Fish | Size", BlueprintPure)
		mixin float GetWeight(FFishInstanceData& FishInstanceData)
		{
			return FishInstanceData.SizeData.Weight;
		}

		UFUNCTION(Category = "Fish | Size", BlueprintPure)
		mixin int GetVendorValue(FFishInstanceData& FishInstanceData)
		{
			return FishInstanceData.SizeData.VendorValue;
		}

		UFUNCTION(Category = "Fish | Size", BlueprintPure)
		mixin EFishTag GetTag(FFishInstanceData& FishInstanceData)
		{
			return FishInstanceData.Tag;
		}

		namespace Size
		{
			const float TINY_THRESHOLD = 25.0f;
			const float LARGE_THRESHOLD = 75.0f;

			/**
			 * Generates size data for a fish based on its item data.
			 * @note Size and weight are randomized within the size span defined in the fish item data.
			 */
			UFUNCTION(Category = "Fish | Size", BlueprintPure)
			FFishSizeData CalculateSize(FFishItemData FishItemData)
			{
				// Randomize size and weight within span
				float Size = Math::RandRange(FishItemData.SizeSpan.X, FishItemData.SizeSpan.Y);
				float Weight = Size * 0.1f; // Simple formula: weight is 10% of size

				Size = RoundTo(Size, 2);
				Weight = RoundTo(Weight, 2);

				float SpanMin = FishItemData.SizeSpan.X;
				float SpanMax = FishItemData.SizeSpan.Y;
				float SpanRange = Math::Max(0.0001f, SpanMax - SpanMin); // avoid division by zero
				float Normalized = (Size - SpanMin) / SpanRange;
				float NormalizedPercent = Percent::From(Normalized);

				// considered Tiny if in lowest 25% of the span, Large if in highest 25%
				bool IsTiny = NormalizedPercent < TINY_THRESHOLD;
				bool IsLarge = NormalizedPercent > LARGE_THRESHOLD;

				int VendorValue = Math::RoundToInt((Size + Weight) * 2 * Math::Max(1, float(FishItemData.Rarity))); // Simple formula: (size + weight) * 2 * rarity
				return FFishSizeData(Size, Weight, IsTiny, IsLarge, VendorValue);
			}
		}

		namespace Tag
		{
			const float UMBRAL_CHANCE = 5.0f; // 5%
			const float ASTRAL_CHANCE = 5.0f; // 5%

			UFUNCTION(Category = "Fish | Tag", BlueprintPure)
			EFishTag RollTag()
			{
				float LuckStat;
				Stats::GetStat(GetFishCharacterBase(), GameplayTags::Stat_Fishing_Luck, false, false, LuckStat);
				float Roll = Math::RandRange(0.0f, 100.0f) + LuckStat; // E.g., 5% luck would be a flat 5% increase to getting a tag.

				if (Roll < UMBRAL_CHANCE)
					return EFishTag::Umbral;
				else if (Roll < UMBRAL_CHANCE + ASTRAL_CHANCE)
					return EFishTag::Astral;
				else
					return EFishTag::None;
			}
		}
	}
}

UCLASS(Abstract, NotPlaceable, ClassGroup = "Fishing", Meta = (PrioritizeCategories = "Fish"))
class AFish : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Fish")
	UFishItem Item;

	UPROPERTY(Category = "Fish", NotVisible, BlueprintReadOnly, ExposeOnSpawn)
	FFishInstanceData FishInstanceData;

	default bReplicates = true;

	bool OnSpawnCalled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimerForNextTick(this, "Foo");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Foo()
	{
		if (!OnSpawnCalled)
			throw("OnSpawn was not called!");
	}

	/**
	 * @note Must be called after spawning the fish to initialize it!
	 */
	UFUNCTION(Category = "Fish")
	void OnSpawn(UFishItem InItem)
	{
		Item = InItem;

		auto Data = Item.FishData;

		Mesh.SetStaticMesh(Data.Mesh);

		if (Data.PreferredBaits.Num() == 0)
		{
			PrintError(f"{Item.BaseData.ItemName} has no required baits set!");
			return;
		}

		FishInstanceData = Fish::InstanceData::MakeFishInstanceData(Data);

		OnSpawnCalled = true;
	}

#if EDITOR
	void OnCaught(AFishCharacter Catcher)
	{
		auto FishData = Item.FishData;

		FString SizeInformation = FishInstanceData.SizeData.IsTiny ? "Tiny" : (FishInstanceData.SizeData.IsLarge ? "Large" : "Normal");
		FString HookInformation = f"{Item.GetItemName()} \nSize: {FishInstanceData.SizeData.Size} cm \nWeight: {FishInstanceData.SizeData.Weight} kg \nType: {FishData.FishType} \nRarity: {FishData.Rarity} \nSize Category: {SizeInformation} \nTag: {FishInstanceData.Tag:n}";
		Print(f"{Catcher.ActorNameOrLabel} caught a {HookInformation}", 3.5f, FLinearColor::DPink);
	}
#endif
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
	/*
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