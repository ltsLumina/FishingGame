event void FOnQuestBegun(FQuestEntry Entry);
event void FOnQuestProgressed(FQuestEntry Entry);
event void FOnQuestCompleted(FQuestEntry Entry);

struct FQuestEntry
{
	UPROPERTY(Category = "Quest", EditInstanceOnly, SaveGame)
	UQuest Quest;

	/**
	 * The current progress of the quest.
	 * Represented as the number of completed objectives.
	 * This means quests with multiple objectives can be progressed in any order.
	 */
	UPROPERTY(Category = "Quest", VisibleAnywhere, SaveGame)
	int Progress;

	UPROPERTY(Category = "Quest", VisibleAnywhere, SaveGame)
	TArray<UQuestObjective> CompletedObjectives;

	UPROPERTY(Category = "Quest", VisibleAnywhere, SaveGame)
	bool IsCompleted;

	FQuestEntry()
	{
		Quest = nullptr;
		Progress = 0;
		IsCompleted = false;
	}

	FQuestEntry(UQuest InQuest, int InProgress, bool InCompleted)
	{
		Quest = InQuest;
		Progress = InProgress;
		IsCompleted = InCompleted;
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

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);

		InPlayerState.InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
		Cast<AFishController>(Gameplay::GetPlayerController(0)).OnInteract.AddUFunction(this, n"HandleNPCInteract"); // TODO: null on client
	}

	UFUNCTION(NotBlueprintCallable)
	private void HandleInventoryChanged(FName _0, FInventorySlot _1, EInventoryChangeType _2)
	{
		for (auto& LogEntry : QuestLog)
		{
			ProgressQuest(LogEntry.Value.Quest); // Check each quest for progress
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void HandleNPCInteract(AFishNPC _0, ESelectionState _1)
	{
		for (auto& LogEntry : QuestLog)
		{
			ProgressQuest(LogEntry.Value.Quest);
		}
	}

	UFUNCTION(Category = "Quest", Keywords = "AddQuest,NewQuest")
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

	UFUNCTION(Category = "Quest", Keywords = "RemoveQuest,DeleteQuest")
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

	UFUNCTION(Category = "Quest", BlueprintPure, Keywords = "contains")
	bool HasQuest(UQuest Quest)
	{
		if (Quest == nullptr)
			PrintError("HasQuest called with null Quest.", 5.0f);
		return QuestLog.Contains(Quest.QuestID);
	}
	UFUNCTION(Category = "Quest", BlueprintPure, Keywords = "contains", DisplayName = "Has Quest (Out)", Meta = (ReturnDisplayName = "Has Quest"))
	bool HasQuestOut(UQuest Quest, FQuestEntry&out FoundEntry)
	{
		if (QuestLog.Contains(Quest.QuestID))
		{
			FoundEntry = QuestLog[Quest.QuestID];
			return true;
		}
		return false;
	}

	UFUNCTION(Category = "Quest")
	void BeginQuest(UQuest Quest)
	{
		FQuestEntry Entry;
		if (!AddEntry(Quest, Entry))
			return;

		QuestBegun(Quest);
		OnQuestBegun.Broadcast(Entry);

		ProgressQuest(Entry.Quest); // Check for any existing progress
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
			if (Objective.IsSatisfied(Character) && !Entry.CompletedObjectives.Contains(Objective))
			{
				Entry.CompletedObjectives.Add(Objective);
			
				Print("Objective completed: " + Objective.GetName(), 3.0f, FLinearColor::Green);

				Entry.Progress++;
				Entry.IsCompleted = (Entry.Progress >= Objectives);
				OnQuestProgressed.Broadcast(Entry);
				QuestProgressed(Entry.Quest, Entry.Progress >= Objectives);
			}
		}

		QuestLog[Quest.QuestID] = Entry;

		if (Entry.IsCompleted)
		{
			Print("Quest ready to complete!", 1.5f, FLinearColor(0.84, 0.62, 0.15));
		}

		return Entry.IsCompleted;
	}

	UFUNCTION(Category = "Quest")
	void CompleteQuest(UQuest Quest)
	{
		Print("Quest completed!", 3.0f, FLinearColor::Green);

		FQuestEntry Entry = QuestLog[Quest.QuestID];

		// Grant rewards
		auto Reward = Entry.Quest.Reward;
		PlayerState.InventoryComponent.GainGil(Reward.Gil);
		PlayerState.ExperienceComponent.GainExperience(Reward.Experience);
		if (Reward.GrantsItem)
		{
			check(Reward.Items.Num() > 0, "Quest reward marked as granting item, but no items specified.");
			for (auto& Pair : Reward.Items)
			{
				PlayerState.InventoryComponent.AddBait(Pair.Key, Pair.Value);
			}
		}
		if (Reward.GrantsFishingRod)
		{
			auto Rod = FishingRod::GenerateRod(Character, Reward.FishingRod);
			PlayerState.InventoryComponent.EquipRod(Rod); // todo: add to inventory instead
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
		SaveGame.SavedCompletedQuests = CompletedQuests;
		return Gameplay::SaveGameToSlot(SaveGame, "PlayerQuestLog", 0);
	}

	UFUNCTION(Category = "Save Game")
	ELoadResult LoadQuests()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerQuestLog", 0);
		if (SaveGame == nullptr)
			return ELoadResult::SuccessNoData;

		auto LoadedSave = Cast<UQuestSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		QuestLog = LoadedSave.SavedQuestLog;
		CompletedQuests = LoadedSave.SavedCompletedQuests;

		Debug_SavedQuestLog = LoadedSave.SavedQuestLog;

		System::SetTimer(this, n"DelayedLoad", 0.3f, false);
		return ELoadResult::Success;
	}

	TMap<FName, FQuestEntry> Debug_SavedQuestLog;

	UFUNCTION()
	void DelayedLoad()
	{
		for (auto& Pair : Debug_SavedQuestLog)
		{
			// BeginQuest(Pair.Value.Quest);
			Print(f"Loaded Quest: {Pair.Value.Quest.QuestID}", 3.0f, FLinearColor::Green);
		}
	}
};