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

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();	
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay() { }

	void LatePlay() override
	{
		Super::LatePlay();

		InteractionBox.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		State.InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
					  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
					  const FHitResult&in SweepResult)
	{		
		if (!Character.IsLocallyControlled())
			return;

		if (State.QuestComponent.CurrentQuest == nullptr && AvailableQuests.Num() > 0)
			PromptQuest(AvailableQuests[0]);
		else if (State.QuestComponent.CurrentQuest != nullptr)
			ProgressQuest();
		
		if (PendingCompletion)
			CompleteQuest();
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if (State.QuestComponent.CurrentQuest == nullptr && AvailableQuests.Num() > 0)
			PromptQuest(nullptr);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleInventoryChanged(FName ItemID, UItem Item, EInventoryChangeType Change)
	{
		if (State.QuestComponent.CurrentQuest != nullptr)
			ProgressQuest();
	}

	UFUNCTION(Category = "Quest")
	void BeginQuest()
	{
		auto QuestComp = State.QuestComponent;

		if (QuestComp.CurrentQuest == nullptr && AvailableQuests.Num() > 0)
		{
			QuestComp.CurrentQuest = AvailableQuests.Num() > 0 ? AvailableQuests[0] : nullptr;
			Print("Quest started!");

			UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
			QuestIcon.SetSprite(QuestProgressIcons[3]);

			QuestBegun();
		}

		ProgressQuest(); // Check if already completed

		CompleteQuest(); // try to complete right away
	}

	bool PendingCompletion;

	UFUNCTION(Category = "Quest")
	void ProgressQuest()
	{
		auto QuestComp = State.QuestComponent;

		if (IsValid(QuestComp.CurrentQuest))
		{
			int Objectives = QuestComp.CurrentQuest.Objectives.Num();
			int Completed = 0;
			for (auto& Objective : QuestComp.CurrentQuest.Objectives)
			{
				if (Objective.IsSatisfied(Character))
				{
					Completed++;
					break;
				}
				else
				{
					Print(f"Quest: not yet completed. ({Objective.GetName()})", 1.5f, FLinearColor::Yellow);
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

	void CompleteQuest()
	{
		Print("Quest completed!", 3.0f, FLinearColor::Green);
			auto Reward = State.QuestComponent.CurrentQuest.Reward;
			State.StatsComponent.GainGil(Reward.Gil);
			State.ExperienceComponent.GainExperience(Reward.Experience);
			if (Reward.GrantsItem && Reward.Item != nullptr)
			{
				State.InventoryComponent.AddItem(Reward.Item.GetDefaultObject(), Reward.Quantity); // TODO: move add bait to inventory rather than baitmenu widget
			}
			
			PendingCompletion = false;

			UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
			if (AvailableQuests.Num() > 1)
				QuestIcon.SetSprite(QuestProgressIcons[1]);
			else
				QuestIcon.SetHiddenInGame(true);

			QuestCompleted();
			State.QuestComponent.CurrentQuest = nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void PromptQuest(UQuest Quest)
	{}

	UFUNCTION(BlueprintEvent)
	void QuestBegun()
	{}

	UFUNCTION(BlueprintEvent)
	void QuestProgressed()
	{}

	UFUNCTION(BlueprintEvent)
	void QuestCompleted()
	{}
};