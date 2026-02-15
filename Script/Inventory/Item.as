class UItem : UPrimaryDataAsset
{
	UPROPERTY(Category = "Item", ExposeOnSpawn, SaveGame, Meta=(ShowOnlyInnerProperties))
	FItemData BaseData;

	UFUNCTION(Category = "Item | Info", BlueprintPure)
	FName GetID()
	{
		if (BaseData.ID == n"default_item" || BaseData.ID.IsNone())
		{
			if (GetItemName().ToString().Len() > 0)
			{
				BaseData.ID = GenerateID(GetItemName());
			}
			else
			{
				PrintError("Item has no name set, cannot generate ID!");
			}
		}

		return BaseData.ID;
	}

	UFUNCTION(Category = "Item | Info", BlueprintPure)
	FText GetItemName()
	{
		return BaseData.ItemName;
	}

	UFUNCTION(Category = "Item | Info", BlueprintPure)
	FText GetDescription()
	{
		return BaseData.Description;
	}

	UFUNCTION(Category = "Item | Info", BlueprintPure)
	UTexture2D GetThumbnail()
	{
		return BaseData.Thumbnail;
	}
}

USTRUCT(Meta=(HiddenByDefault))
struct FItemData
{
	UPROPERTY(Category = "Item | Info", DisplayName = "ID", SaveGame)
    FName ID = n"default_item";

	UPROPERTY(Category = "Item | Info", DisplayName = "Name", SaveGame)
	FText ItemName = FText::FromString("Default Item");

	UPROPERTY(Category = "Item | Info", Meta = (MultiLine), SaveGame)
	FText Description = FText::FromString("A generic Item. \nNothing special about it.");

	UPROPERTY(Category = "Item | Info", SaveGame)
	UTexture2D Thumbnail;
}

UFUNCTION(Category = "Utility", BlueprintPure)
FName GenerateID(FText ItemName)
{
	return FName(ItemName.ToString().ToLower().Replace(" ", "_"));
}

UFUNCTION(Category = "Utility", BlueprintPure)
FText GenerateDisplayName(FString Filename)
{
	FString Chopped = Filename.RightChop(3); // removes BP_/DA_ prefixes
	FString WithSpaces = Chopped.Replace("_", " ");
	return FText::FromString(WithSpaces.ToDisplayName());
}