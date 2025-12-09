class UItem : UObject
{
	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, ExposeOnSpawn, SaveGame)
	FItemData BaseData;

	void Init(FName InID, FText InItemName, FText InDescription, UTexture2D InThumbnail)
    {
        BaseData.ID = InID;
        BaseData.ItemName = InItemName;
        BaseData.Description = InDescription;
        BaseData.Thumbnail = InThumbnail;
    }
}

struct FItemData
{
	UPROPERTY(Category = "Fish | Info", DisplayName = "ID", VisibleAnywhere, SaveGame)
    FName ID;

	UPROPERTY(Category = "Fish | Info", DisplayName = "Name", SaveGame)
	FText ItemName = FText::FromString("Default Item");

	UPROPERTY(Category = "Fish | Info", Meta = (MultiLine), SaveGame)
	FText Description = FText::FromString("A generic fish. \nNothing special about it.");

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, SaveGame)
	UTexture2D Thumbnail;
}

UFUNCTION(Category = "Utility", BlueprintPure)
FName GenerateItemID(FText ItemName)
{
	return FName(ItemName.ToString().ToLower().Replace(" ", "_"));
}