UCLASS(Meta=(PrioritizeCategories="NPC"))
class AFishNPC : AFishEntity
{
	/**
	 * A box component that defines the interaction area for the NPC.
	 * The player must be within this area to interact with the NPC.
	 */
	UPROPERTY(DefaultComponent)
	UBoxComponent InteractionBox;

	/**
	 * A box component that defines the clickable area for the NPC.
	 * The player can click on this area to interact with the NPC.
	 */
	UPROPERTY(DefaultComponent)
	UBoxComponent ClickBox;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent Nametag;

	UPROPERTY(DefaultComponent)
	UBillboardComponent QuestBillboard;

	UPROPERTY(Category = "NPC | Info", DisplayName = "ID", EditDefaultsOnly)
	FName NPC_ID = n"NPC";

	UPROPERTY(Category = "NPC | Info", DisplayName = "Name")
	FText NPCName = FText::FromString("Fish NPC");

	UPROPERTY(Category = "NPC | Info", Meta = (MultiLine))
	FText Description = FText::FromString("A generic fish NPC. \nNothing special about it.");

	// - INTERACTION -

	UPROPERTY(Category = "NPC | Interaction", VisibleAnywhere)
	float InteractionDistance = 300.0f;

	UPROPERTY(Category = "NPC | Interaction", VisibleInstanceOnly)
	bool IsSelected;

	// - QUESTS -

	UPROPERTY(Category = "NPC | Quests", Meta = (InlineEditConditionToggle))
	bool HasQuests = false;

	UPROPERTY(Category = "NPC | Quests", Meta = (EditCondition = "HasQuests"))
	TArray<FQuestEntry> AvailableQuests;

	UPROPERTY(Category = "NPC | Quests", EditDefaultsOnly)
	TMap<FName, UTexture2D> QuestIcons;

	// - MENU -

	UPROPERTY(Category = "NPC | Menu", Meta = (InlineEditConditionToggle))
	bool HasMenu = false;

	UPROPERTY(Category = "NPC | Menu", Meta = (EditCondition = "HasMenu"))
	TSubclassOf<UFishWidget> MenuWidgetClass;

	default bReplicates = false;
	default bReplicateMovement = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		NPC_ID = FName(NPCName.ToString().ToLower().Replace(" ", "_"));

		Nametag.SetText(NPCName);
		Nametag.SetAbsolute(bNewAbsoluteLocation = false, bNewAbsoluteRotation = true, bNewAbsoluteScale = false);

		QuestBillboard.SetHiddenInGame(false);
		QuestBillboard.SetVisibility(HasQuests);

		FVector Extent = InteractionBox.BoxExtent;
		InteractionDistance = Math::Sqrt((Extent.X * Extent.X) + (Extent.Y * Extent.Y));
	}

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

		if (AvailableQuests.Num() == 0)
			return;

		auto QuestComponent = UQuestComponent::Get(State);
		QuestComponent.OnQuestBegun.AddUFunction(this, n"QuestBegun");
		QuestComponent.OnQuestProgressed.AddUFunction(this, n"QuestProgressed");
		QuestComponent.OnQuestCompleted.AddUFunction(this, n"QuestCompleted");
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Late Play")
	void BP_LatePlay()
	{}

	// - QUESTS -

	UFUNCTION()
	void QuestBegun(FQuestEntry Entry)
	{
		QuestBillboard.SetSprite(FindQuestIcon(n"unsatisfied"));

		QuestBegunEvent();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Quest Begun")
	void QuestBegunEvent()
	{}

	UFUNCTION()
	void QuestProgressed(FQuestEntry Entry)
	{
		if (!Entry.Completed)
			return;

		QuestBillboard.SetSprite(FindQuestIcon(n"completed"));
	}

	UFUNCTION()
	void QuestCompleted(FQuestEntry Entry)
	{
		AvailableQuests.RemoveAt(0);

		bool HasAdditionalQuests = AvailableQuests.Num() > 0;
		if (!HasAdditionalQuests)
		{
			QuestBillboard.SetHiddenInGame(false);
			return;
		}

		QuestBillboard.SetSprite(FindQuestIcon(n"progressed"));

		QuestCompletedEvent();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Quest Completed")
	void QuestCompletedEvent()
	{}

	UTexture2D FindQuestIcon(FName IconName)
	{
		UTexture2D Texture;
		QuestIcons.Find(IconName, Texture);
		return Texture;
	}

	// - INTERACTION -

	/**
	 * Handles click interaction with the NPC.
	 * If the NPC is already selected, it will be deselected, and vice versa.
	 */
	UFUNCTION()
	void ToggleSelection()
	{
		if (IsSelected)
		{
			Deselect();
			return;
		}

		Select();
	}

	/**
	 * Selects the NPC, marking it as selected and notifying the controller.
	 */
	UFUNCTION()
	void Select()
	{
		IsSelected = true;
		OnSelected();
	}

	/**
	 * Deselects the NPC, marking it as not selected and notifying the controller.
	 */
	UFUNCTION()
	void Deselect()
	{
		IsSelected = false;
		OnDeselected();
	}

	UFUNCTION(BlueprintEvent)
	void OnSelected()
	{}

	UFUNCTION(BlueprintEvent)
	void OnDeselected()
	{}

	UFUNCTION(BlueprintPure)
	bool IsInRange(APawn OtherActor)
	{
		return GetDistanceTo(OtherActor) <= InteractionDistance;
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		auto OtherChar = Cast<AFishCharacter>(OtherActor);
		if (OtherChar == nullptr)
			return;

		if (!OtherChar.IsLocallyControlled())
			return;

		EnteredInteractionBox();
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		auto OtherChar = Cast<AFishCharacter>(OtherActor);
		if (OtherChar == nullptr)
			return;

		if (!OtherChar.IsLocallyControlled())
			return;

		ExitedInteractionBox();
	}

	UFUNCTION(BlueprintEvent)
	void EnteredInteractionBox()
	{}

	UFUNCTION(BlueprintEvent)
	void ExitedInteractionBox()
	{}

	// - SAVE/LOAD -

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

	UFUNCTION(NotBlueprintCallable)
	private void SetQuestSprite()
	{
		FQuestEntry Entry;
		UQuestComponent::Get(State).QuestLog.Find(AvailableQuests[0].Quest.QuestID, Entry);
		if (!IsValid(Entry.Quest))
		{
			UTexture2D Texture;
			QuestIcons.Find(n"not_started", Texture);
			QuestBillboard.SetSprite(Texture);
			return;
		}

		if (Entry.Completed)
		{
			UTexture2D Texture;
			QuestIcons.Find(n"completed", Texture);
			QuestBillboard.SetSprite(Texture);
		}
		else
		{
			UTexture2D Texture;
			QuestIcons.Find(n"unsatisfied", Texture);
			QuestBillboard.SetSprite(Texture);
		}
	}

	UFUNCTION(Category = "Save Game")
	void ResetQuests()
	{
		Gameplay::DeleteGameInSlot(f"{NPC_ID}_Quests", 0);
	}
};