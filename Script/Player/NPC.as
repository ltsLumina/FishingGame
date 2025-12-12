class AFishNPC : AFishEntity
{
	UPROPERTY(DefaultComponent)
	UBoxComponent InteractionBox;

	UPROPERTY(Category = "NPC | Info", DisplayName = "ID", EditDefaultsOnly)
	FName NPC_ID = n"NPC";

	UPROPERTY(Category = "NPC | Info", DisplayName = "Name")
	FText NPCName = FText::FromString("Fish NPC");

	UPROPERTY(Category = "NPC | Info", Meta = (MultiLine))
	FText Description = FText::FromString("A generic fish NPC. \nNothing special about it.");

	UPROPERTY(Category = "NPC | Quests")
	TArray<FQuestEntry> AvailableQuests;

	UPROPERTY(Category = "NPC | Quests", EditDefaultsOnly)
	TMap<FName, UTexture2D> QuestIcons;

	UBillboardComponent Billboard;

	default bReplicates = false;
	default bReplicateMovement = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();

		Billboard = UBillboardComponent::Get(this);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	void LatePlay() override
	{
		Super::LatePlay();
		BP_LatePlay();

		if (AvailableQuests.Num() == 0) return;

		auto QuestComponent = UQuestComponent::Get(State);
		QuestComponent.OnQuestBegun.AddUFunction(this, n"QuestBegun");
		QuestComponent.OnQuestProgressed.AddUFunction(this, n"QuestProgressed");
		QuestComponent.OnQuestCompleted.AddUFunction(this, n"QuestCompleted");
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay()
	{}

	UFUNCTION()
	void QuestBegun(FQuestEntry Entry)
	{
		UTexture2D Texture;
		QuestIcons.Find(n"unsatisfied", Texture);
		Billboard.SetSprite(Texture);

		QuestBegunEvent();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Quest Begun")
	void QuestBegunEvent() {}

	UFUNCTION()
	void QuestProgressed(FQuestEntry Entry)
	{
		if (!Entry.Completed)
			return;

		UTexture2D Texture;
		QuestIcons.Find(n"completed", Texture);
		Billboard.SetSprite(Texture);
	}

	UFUNCTION()
	void QuestCompleted(FQuestEntry Entry)
	{
		AvailableQuests.RemoveAt(0);

		bool HasAdditionalQuests = AvailableQuests.Num() > 0;
		if (!HasAdditionalQuests)
		{
			Billboard.SetHiddenInGame(false);
			return;
		}

		UTexture2D NextQuest;
		QuestIcons.Find(n"progressed", NextQuest);
		Billboard.SetSprite(NextQuest);

		QuestCompletedEvent();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Quest Completed")
	void QuestCompletedEvent() {}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		auto OtherChar = Cast<AFishCharacter>(OtherActor);
		if (OtherChar == nullptr)
			return;

		if (!OtherChar.IsLocallyControlled())
			return;

		HideWidget();
	}

	UFUNCTION(BlueprintEvent)
	void HideWidget()
	{}

	UFUNCTION(Category = "Save Game")
	bool SaveQuests()
	{
		auto SaveGame = NewObject(this, UNPCSaveGame);
		for (auto& Entry : AvailableQuests)
		{
			SaveGame.AvailableQuests.Add(Entry);
		}
		return Gameplay::SaveGameToSlot(SaveGame, f"{NPC_ID}_Quests", 0);
	}

	UFUNCTION(Category = "Save Game")
	bool LoadQuests()
	{
#if EDITOR
		Gameplay::DeleteGameInSlot(f"{NPC_ID}_Quests", 0); // TEMP DELETE
#endif

		auto SaveGame = Gameplay::LoadGameFromSlot(f"{NPC_ID}_Quests", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UNPCSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		AvailableQuests.Empty();
		for (auto& Entry : LoadedSave.AvailableQuests)
		{
			AvailableQuests.Add(Entry);
			Print("Loaded Quest: " + Entry.Quest.QuestID.ToString(), 3.0f, FLinearColor::Green);
		}

		System::SetTimer(this, n"SetQuestSprite", 0.3f, false);
		return true;
	}

	UFUNCTION()
	void SetQuestSprite()
	{
		FQuestEntry Entry;
		UQuestComponent::Get(State).QuestLog.Find(AvailableQuests[0].Quest.QuestID, Entry);
		if (!IsValid(Entry.Quest))
		{
			UTexture2D Texture;
			QuestIcons.Find(n"not_started", Texture);
			Billboard.SetSprite(Texture);
			return;
		}
		
		if (Entry.Completed)
		{
			UTexture2D Texture;
			QuestIcons.Find(n"completed", Texture);
			Billboard.SetSprite(Texture);
		}
		else
		{
			UTexture2D Texture;
			QuestIcons.Find(n"unsatisfied", Texture);
			Billboard.SetSprite(Texture);
		}
	}

	UFUNCTION(Category = "Save Game")
	void ResetQuests()
	{
		Gameplay::DeleteGameInSlot(f"{NPC_ID}_Quests", 0);
	}
};