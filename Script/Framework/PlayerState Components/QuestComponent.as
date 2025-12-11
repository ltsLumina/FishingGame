event void FOnQuestBegun(FQuestEntry Entry);
event void FOnQuestProgressed(FQuestEntry Entry);
event void FOnQuestCompleted(FQuestEntry Entry);

struct FQuestEntry
{
	UPROPERTY(Category = "Quest", SaveGame)
	UQuest Quest;

	UPROPERTY(Category = "Quest", SaveGame)
	int Progress;

	UPROPERTY(Category = "Quest", SaveGame)
	bool Completed;

	FQuestEntry()
	{
		Quest = nullptr;
		Progress = 0;
		Completed = false;
	}

	FQuestEntry(UQuest InQuest, int InProgress, bool InCompleted)
	{
		Quest = InQuest;
		Progress = InProgress;
		Completed = InCompleted;
	}
}

class UQuestComponent : UFishComponentBase
{
	UPROPERTY(Category = "Quest", VisibleInstanceOnly, SaveGame)
	TMap<FName, FQuestEntry> QuestLog;

	UPROPERTY(Category = "Quest", VisibleInstanceOnly, SaveGame)
	TArray<FName> CompletedQuests;

	UPROPERTY(Category = "Events")
	FOnQuestBegun OnQuestBegun;

	UPROPERTY(Category = "Events")
	FOnQuestProgressed OnQuestProgressed;

	UPROPERTY(Category = "Events")
	FOnQuestCompleted OnQuestCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	void LatePlay() override
	{
		Super::LatePlay();
		BP_LatePlay();

		State.InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay()
	{}

	UFUNCTION(NotBlueprintCallable)
	void HandleInventoryChanged(FName ItemID, UItem Item, EInventoryChangeType Change)
	{
		for (auto& LogEntry : QuestLog)
		{
			ProgressQuest(LogEntry.Value.Quest); // Check each quest for progress
		}
	}

	UFUNCTION(Category = "Quest", Keywords="AddQuest,NewQuest")
	bool AddEntry(UQuest Quest, FQuestEntry& OutEntry)
	{
		check(Quest.QuestID != NAME_None, "QuestID cannot be None when adding a quest to the log.");

		if (HasQuest(Quest))
		{
			PrintWarning("Quest already in log: " + Quest.QuestID.ToString(), 3.0f);
			OutEntry = QuestLog[Quest.QuestID];
			return false;
		}

		OutEntry = FQuestEntry(Quest, 0, false);

		QuestLog.Add(Quest.QuestID, OutEntry);
		Print(f"Quest added to log: {Quest.QuestID}", 3.0f, FLinearColor::Green);

		return true;
	}

	UFUNCTION(Category = "Quest", Keywords="RemoveQuest,DeleteQuest")
	bool RemoveEntry(UQuest Quest)
	{
		if (!HasQuest(Quest))
		{
			PrintWarning("Quest not found in log: " + Quest.QuestID.ToString(), 3.0f);
			return false;
		}

		QuestLog.Remove(Quest.QuestID);
		Print("Quest removed from log: " + Quest.QuestID.ToString(), 3.0f, FLinearColor::Green);
		return true;
	}

	UFUNCTION(Category = "Quest", BlueprintPure, Keywords="contains")
	bool HasQuest(UQuest Quest)
	{
		return QuestLog.Contains(Quest.QuestID);
	}

	UFUNCTION(Category = "Quest")
	void BeginQuest(UQuest Quest)
	{
		FQuestEntry Entry; 
		if (!AddEntry(Quest, Entry)) return;
		
		Print("Quest started!");

		OnQuestBegun.Broadcast(Entry);
		QuestBegun(Quest);

		if (ProgressQuest(Quest))
			CompleteQuest(Quest);
	}

	/**
	 * Progresses the current quest by checking each objective for completion.
	 * @return True if the quest was progressed, false otherwise.
	 */
	UFUNCTION(Category = "Quest")
	bool ProgressQuest(UQuest Quest)
	{
		if (!HasQuest(Quest))
		{
			PrintWarning("Quest not found in log: " + Quest.QuestID.ToString(), 3.0f);
			return false;
		}
		
		FQuestEntry Entry = QuestLog[Quest.QuestID];

		int Objectives = Entry.Quest.Objectives.Num();
		for (auto& Objective : Quest.Objectives)
		{
			if (Objective.IsSatisfied(Character))
			{
				Print("Objective completed: " + Objective.GetName(), 3.0f, FLinearColor::Green);

				Entry.Progress++;
				Entry.Completed = (Entry.Progress >= Objectives);
				OnQuestProgressed.Broadcast(Entry);
				QuestProgressed(Entry.Quest, Entry.Progress >= Objectives);
			}
		}

		QuestLog[Quest.QuestID] = Entry;

		if (Entry.Completed)
		{
			Print("Quest ready to complete!", 1.5f, FLinearColor(0.84, 0.62, 0.15));
		}

		return Entry.Completed;
	}

	UFUNCTION(Category = "Quest")
	void CompleteQuest(UQuest Quest)
	{
		Print("Quest completed!", 3.0f, FLinearColor::Green);
		
		FQuestEntry Entry = QuestLog[Quest.QuestID];

		// Grant rewards
		auto Reward = Entry.Quest.Reward;
		State.StatsComponent.GainGil(Reward.Gil);
		State.ExperienceComponent.GainExperience(Reward.Experience);
		if (Reward.GrantsItem)
		{
			check(Reward.Items.Num() > 0, "Quest reward marked as granting item, but no items specified.");
			for (auto& Pair : Reward.Items)
			{
				State.InventoryComponent.AddBait(Pair.Key, Pair.Value);
			}
		}

		QuestLog.Remove(Quest.QuestID);
		CompletedQuests.Add(Quest.QuestID);
		OnQuestCompleted.Broadcast(Entry);
		QuestCompleted(Entry);
	}

	UFUNCTION(BlueprintEvent)
	void QuestBegun(UQuest Quest)
	{}

	UFUNCTION(BlueprintEvent)
	void QuestProgressed(UQuest Quest, bool Completed)
	{}

	UFUNCTION(BlueprintEvent)
	void QuestCompleted(FQuestEntry Entry)
	{}

	UFUNCTION(Category = "Save Game")
	bool SaveQuests()
	{
		auto SaveGame = NewObject(this, UQuestSaveGame);
		SaveGame.SavedQuestLog = QuestLog;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerQuestLog", 0);
	}

	UFUNCTION(Category = "Save Game")
	bool LoadQuests()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerQuestLog", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UQuestSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		QuestLog = LoadedSave.SavedQuestLog;
		SavedQuestLog = LoadedSave.SavedQuestLog;

		System::SetTimer(this, n"DelayedLoad", 0.3f, false);
		return true;
	}

	TMap<FName, FQuestEntry> SavedQuestLog;

	UFUNCTION()
	void DelayedLoad()
	{
		for (auto& Pair : SavedQuestLog)
		{
			//BeginQuest(Pair.Value.Quest);
			Print(f"Loaded Quest: {Pair.Value.Quest.QuestID}", 3.0f, FLinearColor::Green);
		}
	}

};