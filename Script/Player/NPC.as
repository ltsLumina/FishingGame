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

		InteractionBox.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(NotBlueprintCallable)
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
					  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
					  const FHitResult&in SweepResult)
	{
		auto Character = Cast<AFishCharacter>(OtherActor);
		if (Character == nullptr)
			return;

		// This ensures the code runs only for the local player's pawn (works for clients and host player).
		if (!Character.IsLocallyControlled())
			return;

		ProgressQuest(OtherActor);
	}

	UFUNCTION(NotBlueprintCallable)
	void ProgressQuest(AActor OtherActor)
	{
		auto Character = Cast<AFishCharacter>(OtherActor);
		if (Character != nullptr)
		{
			auto PS = Cast<AFishPlayerState>(Character.PlayerState);
			if (PS == nullptr)
				return;

			auto QuestComp = UQuestComponent::Get(PS);

			if (QuestComp.CurrentQuest == nullptr && AvailableQuests.Num() > 0)
			{
				QuestComp.CurrentQuest = AvailableQuests.Num() > 0 ? AvailableQuests[0] : nullptr;
				Print("Quest started!");

				UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
				QuestIcon.SetSprite(QuestProgressIcons[3]);
			}

			if (QuestComp.CurrentQuest != nullptr)
			{
				for (auto& Objective : QuestComp.CurrentQuest.Objectives)
				{
					if (Objective.IsSatisfied(Character))
					{
						Print(f"Quest Completed! ({Objective.GetName()})", 3.0f, FLinearColor::Green);
						QuestComp.CurrentQuest = nullptr;
						AvailableQuests.RemoveAt(0);

						if (AvailableQuests.Num() == 0)
						{
							UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
							QuestIcon.SetSprite(nullptr);
						}
						else
						{
							UBillboardComponent QuestIcon = UBillboardComponent::Get(this);
							QuestIcon.SetSprite(QuestProgressIcons[0]);
						}
						break;
					}
					else
					{
						Print(f"Quest: not yet completed. ({Objective.GetName()})", 1.5f, FLinearColor::Yellow);
						break;
					}
				}
			}
		}
	}
};