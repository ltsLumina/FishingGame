class UItem : UObject
{
	UPROPERTY(Category = "Fish | Info", DisplayName = "ID", VisibleAnywhere, BlueprintReadOnly, ExposeOnSpawn)
    FName ID;
	default ID = GenerateItemID(ItemName);

	UPROPERTY(Category = "Fish | Info", DisplayName = "Name", BlueprintReadOnly, ExposeOnSpawn)
	FText ItemName = FText::FromString("Default Item");

	UPROPERTY(Category = "Fish | Info", Meta = (MultiLine), BlueprintReadOnly, ExposeOnSpawn)
	FText Description = FText::FromString("A generic fish. \nNothing special about it.");

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly, ExposeOnSpawn)
	UTexture2D Thumbnail;

	void Init(FName InID, FText InItemName, FText InDescription, UTexture2D InThumbnail)
    {
        ID = InID;
        ItemName = InItemName;
        Description = InDescription;
        Thumbnail = InThumbnail;
    }
}

UFUNCTION(Category = "Utility")
FName GenerateItemID(FText ItemName)
{
	return FName(ItemName.ToString().ToLower().Replace(" ", "_"));
}