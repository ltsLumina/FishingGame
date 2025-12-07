class UQuest : UPrimaryDataAsset
{
    UPROPERTY(Category = "Quest | Info", DisplayName = "ID")
    FName QuestID = FName(f"{Class.GetName()}");

    UPROPERTY(Category = "Quest | Info", DisplayName = "Name")
    FText QuestName;
    default QuestName = FText::FromName(Class.GetName());

    UPROPERTY(Category = "Quest | Info", Meta=(MultiLine))
    FText Description;

    UPROPERTY(Category = "Quest | Info", Meta=(MultiLine))
    FText ObjectiveDescription;

    UPROPERTY(Category = "Quest | Info")
    int MinimumLevel = 1;

    UPROPERTY(Category = "Quest | Info")
    UTexture2D Icon;

    UPROPERTY(Category = "Quest | Giver")
    FName QuestGiver;

    UPROPERTY(Category = "Quest | Objectives", EditInline, Instanced)
    TArray<UQuestObjective> Objectives;

    UPROPERTY(Category = "Quest | Reward")
    FQuestReward Reward;

    UFUNCTION(Category = "Quest | Objectives")
    FText GetObjectiveSteps()
    {
        FString Result;

        for (auto& Objective : Objectives)
        {
            auto Obj = Cast<USpecificFish>(Objective);
            int Quantity = Obj.Quantity;
            FText FishName = Obj.FishClass.DefaultObject.FishName;
            bool IsLarge = Obj.IsLarge;
            FString LargeText = IsLarge ? "(L)" : "";

            FString Step = FString(f"• Catch {Quantity}x {FishName} {LargeText}");
            Result = Result.Append(Step).Append("\n");
        }

        return FText::FromString(Result);
    }
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
    TMap<UBait, int> Items;
}