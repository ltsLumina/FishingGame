class UQuest : UPrimaryDataAsset
{
    UPROPERTY(DisplayName = "ID")
    FName QuestID;

    UPROPERTY(DisplayName = "Name")
    FText QuestName;
    default QuestName = FText::FromName(Class.GetName());

    UPROPERTY(Meta=(MultiLine))
    FText Description;

    UPROPERTY()
    UTexture2D Icon;
}