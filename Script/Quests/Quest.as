class UQuest : UPrimaryDataAsset
{
	UPROPERTY(Category = "Quest | Info", DisplayName = "ID")
	FName QuestID = FName(f"{Class.GetName()}");

	UPROPERTY(Category = "Quest | Info", DisplayName = "Name")
	FText QuestName;
	default QuestName = FText::FromName(Class.GetName());

	UPROPERTY(Category = "Quest | Info", Meta = (MultiLine))
	FText Description;

	UPROPERTY(Category = "Quest | Info")
	int MinimumLevel = 1;

	UPROPERTY(Category = "Quest | Info")
	UTexture2D Icon;

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
			if (Objective.IsA(UCatchFishObjective))
			{
				auto FishObjective = Cast<UCatchFishObjective>(Objective);

				int Quantity = FishObjective.Quantity;
				FText FishName = FishObjective.Fish.GetItemName();
				bool IsLarge = FishObjective.IsLarge;
				FString LargeText = IsLarge ? "(L)" : "";

				FString Step = FString(f"• Catch {Quantity}x {FishName} {LargeText}");
				Result = Result.Append(Step).Append("\n");
			}
            if (Objective.IsA(USpeakWithNPCObjective))
            {
                auto SpeakObjective = Cast<USpeakWithNPCObjective>(Objective);

                FText NPCName = SpeakObjective.NPC.Get().NPCName;

                FString Step = FString(f"• Speak with {NPCName}");
                Result = Result.Append(Step).Append("\n");
            }
            if (Objective.IsA(UHasQuestObjective))
            {
                auto HasQuestObjective = Cast<UHasQuestObjective>(Objective);

                FText ObjectiveQuestName = HasQuestObjective.Quest.QuestName;

                FString Word = HasQuestObjective.MustBeCompleted ? "Complete" : "Accept";
                FString Step = f"• {Word} the quest: {ObjectiveQuestName}";
                Result = Result.Append(Step).Append("\n");
            }
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

	UPROPERTY(Category = "Quest | Reward", Meta = (InlineEditConditionToggle), BlueprintHidden)
	bool GrantsItem;

	UPROPERTY(Category = "Quest | Reward", Meta = (EditCondition = "GrantsItem"))
	TMap<UBait, int> Items;

	UPROPERTY(Category = "Quest | Reward", Meta = (InlineEditConditionToggle), BlueprintHidden)
	bool GrantsFishingRod;

	UPROPERTY(Category = "Quest | Reward", Meta = (EditCondition = "GrantsFishingRod"))
	URodData FishingRod;
}