class AFishNPC : AFishEntity
{
	UPROPERTY(DefaultComponent)
	UBoxComponent InteractionBox;

	UPROPERTY(Category = "NPC | Info", DisplayName = "ID", VisibleInstanceOnly)
	FName NPC_ID = FName(FGuid::NewGuid().ToString());

	UPROPERTY(Category = "NPC | Info", DisplayName = "Name")
	FText NPCName = FText::FromString("Fish NPC");

	UPROPERTY(Category = "NPC | Info", Meta = (MultiLine))
	FText Description = FText::FromString("A generic fish NPC. \nNothing special about it.");

	UPROPERTY(Category = "NPC | Quests")
	TArray<UQuest> AvailableQuests;

	UPROPERTY(Category = "NPC | Quests", EditDefaultsOnly)
	TArray<UTexture2D> QuestProgressIcons;

	UQuestComponent QuestComponent;

	default bReplicates = false;
	default bReplicateMovement = false;

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

		QuestComponent = State.QuestComponent;

		InteractionBox.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		State.InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
					  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
					  const FHitResult&in SweepResult)
	{
		if (!Cast<AFishCharacter>(OtherActor).IsLocallyControlled())
			return;

		if (AvailableQuests.Num() > 0)
			PromptQuest(AvailableQuests[0], Cast<AFishCharacter>(OtherActor), PendingCompletion);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if (!Cast<AFishCharacter>(OtherActor).IsLocallyControlled())
			return;

		if (QuestComponent.CurrentQuest == nullptr && AvailableQuests.Num() > 0)
			PromptQuest(nullptr, nullptr, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleInventoryChanged(FName ItemID, UItem Item, EInventoryChangeType Change)
	{
		if (QuestComponent.CurrentQuest != nullptr)
			ProgressQuest();
	}

	UFUNCTION(Category = "Quest")
	void BeginQuest()
	{
		auto QuestComp = QuestComponent;

		if (QuestComp.CurrentQuest == nullptr && AvailableQuests.Num() > 0)
		{
			QuestComp.CurrentQuest = AvailableQuests.Num() > 0 ? AvailableQuests[0] : nullptr;
			Print("Quest started!");

			UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
			QuestIcon.SetSprite(QuestProgressIcons[3]);

			QuestBegun();
		}

		ProgressQuest();	 // Check if already completed

		if (PendingCompletion)
			CompleteQuest(); // try to complete right away
	}

	bool PendingCompletion;

	UFUNCTION(Category = "Quest")
	void ProgressQuest()
	{
		auto QuestComp = QuestComponent;

		if (IsValid(QuestComp.CurrentQuest))
		{
			int Objectives = QuestComp.CurrentQuest.Objectives.Num();
			int Completed = 0;
			for (auto& Objective : QuestComp.CurrentQuest.Objectives)
			{
				if (Objective.IsSatisfied(Character))
				{
					Completed++;
					QuestProgressed(Objective);
					break;
				}
				else
				{
					Print(f"Quest: not yet completed. ({Objective.GetName()})", 1.5f, FLinearColor::Yellow);
					UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
					QuestIcon.SetSprite(QuestProgressIcons[3]);
					break;
				}
			}

			PendingCompletion = (Completed >= Objectives);
			if (PendingCompletion)
			{
				Print("Quest ready to complete!", 1.5f, FLinearColor(0.84, 0.62, 0.15));

				UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
				QuestIcon.SetSprite(QuestProgressIcons[2]);
			}
		}
	}

	UFUNCTION()
	void CompleteQuest()
	{
		Print("Quest completed!", 3.0f, FLinearColor::Green);
		PendingCompletion = false;
		
		if (AvailableQuests.IsValidIndex(0))
			AvailableQuests.RemoveAt(0);
		
		// Grant rewards
		auto Reward = QuestComponent.CurrentQuest.Reward;
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


		UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
		if (AvailableQuests.Num() > 1)
			QuestIcon.SetSprite(QuestProgressIcons[1]);
		else
			QuestIcon.SetHiddenInGame(true);

		QuestComponent.CurrentQuest = nullptr;
		QuestCompleted();
	}

	UFUNCTION(BlueprintEvent)
	void PromptQuest(UQuest Quest, AFishCharacter Claimant, bool InPendingCompletion)
	{}

	UFUNCTION(BlueprintEvent)
	void PromptQuestCompletion(UQuest Quest)
	{}

	UFUNCTION(BlueprintEvent)
	void QuestBegun()
	{}

	UFUNCTION(BlueprintEvent)
	void QuestProgressed(UQuestObjective Objective)
	{}

	UFUNCTION(BlueprintEvent)
	void QuestCompleted()
	{}
};