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

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionBox.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
	}

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

		Foo(OtherActor);
	}

	UFUNCTION(NotBlueprintCallable)
	void Foo(AActor OtherActor)
	{
		auto Character = Cast<AFishCharacter>(OtherActor);
		if (Character != nullptr)
		{
			auto PS = Cast<AFishPlayerState>(Character.PlayerState);
			if (PS == nullptr)
				return;

			if (PS.CurrentQuest == nullptr)
			{
				PS.CurrentQuest = AvailableQuests.Num() > 0 ? AvailableQuests[0] : nullptr;
				Print("Started quest!");
			}

			if (PS.CurrentQuest != nullptr)
			{
				for (auto& Objective : PS.CurrentQuest.Objectives)
				{
					if (Objective.IsSatisfied(Character))
					{
						Print(f"Quest Completed! ({Objective.GetName()})", 3.0f, FLinearColor::Green);
						PS.CurrentQuest = nullptr;
						AvailableQuests.RemoveAt(0);
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