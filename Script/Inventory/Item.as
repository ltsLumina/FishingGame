class UItem : UObject
{
	UPROPERTY(Category = "Fish | Info", DisplayName = "ID", VisibleAnywhere, BlueprintReadOnly)
    FName ID;

	UPROPERTY(Category = "Fish | Info", DisplayName = "Name", BlueprintReadOnly)
	FText ItemName = FText::FromString("Default Item");

	UPROPERTY(Category = "Fish | Info", Meta = (MultiLine), BlueprintReadOnly)
	FText Description = FText::FromString("A generic fish. \nNothing special about it.");

	UPROPERTY(Category = "Fish | Info", VisibleAnywhere, BlueprintReadOnly)
	UTexture2D Thumbnail;

	void Init(FName InID, FText InItemName, FText InDescription, UTexture2D InThumbnail)
    {
        ID = InID;
        ItemName = InItemName;
        Description = InDescription;
        Thumbnail = InThumbnail;
    }
}