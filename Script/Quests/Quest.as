class UQuest : UPrimaryDataAsset
{
    UPROPERTY(Category = "Quest | Info", DisplayName = "ID")
    FName QuestID = FName(f"{Class.GetName()}");

    UPROPERTY(Category = "Quest | Info", DisplayName = "Name")
    FText QuestName;
    default QuestName = FText::FromName(Class.GetName());

    UPROPERTY(Category = "Quest | Info", Meta=(MultiLine))
    FText Description;

    UPROPERTY(Category = "Quest | Info")
    UTexture2D Icon;

    UPROPERTY(Category = "Quest | Giver")
    FName QuestGiver;

    UPROPERTY(Category = "Quest | Objectives", EditInline, Instanced)
    TArray<UQuestObjective> Objectives;
}