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

    UPROPERTY(Category = "Quest | Reward")
    FQuestReward Reward;
}

struct FQuestReward
{
    UPROPERTY(Category = "Quest | Reward")
    int32 Gil = 50;

    UPROPERTY(Category = "Quest | Reward")
    int32 Experience = 100;

    UPROPERTY(Category = "Quest | Reward", Meta=(InlineEditConditionToggle))
    bool GrantsItem;

    UPROPERTY(Category = "Quest | Reward", Meta=(EditCondition="GrantsItem"))
    TSubclassOf<UItem> Item;

    UPROPERTY(Category = "Quest | Reward", Meta=(EditCondition="Item != nullptr", EditConditionHides))
    int32 Quantity = 1;
}