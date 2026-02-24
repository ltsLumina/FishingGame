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
	
	UPROPERTY(Category = "NPC | Dialogue", Meta = (InlineEditConditionToggle))
	bool HasDialogue = false;

	UPROPERTY(Category="NPC | Menu", Meta=(EditCondition="HasDialogue"))
    TArray<FText> DialogueEntries;
	

	default bReplicates = false;
	default bReplicateMovement = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		NPC_ID = FName(NPCName.ToString().ToLower().Replace(" ", "_"));

		//Nametag.SetText(NPCName);
		//Nametag.SetAbsolute(bNewAbsoluteLocation = false, bNewAbsoluteRotation = true, bNewAbsoluteScale = false);

		QuestBillboard.SetHiddenInGame(false);
		QuestBillboard.SetVisibility(HasQuests);

		FVector Extent = InteractionBox.BoxExtent;
		InteractionDistance = Math::Sqrt((Extent.X * Extent.X) + (Extent.Y * Extent.Y));
	}

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, AFishController InController) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InController);
		
		if (AvailableQuests.Num() == 0)
			return;

		auto QuestComponent = InPlayerState.QuestComponent;
		QuestComponent.OnQuestBegun.AddUFunction(this, n"QuestBegun");
		QuestComponent.OnQuestProgressed.AddUFunction(this, n"QuestProgressed");
		QuestComponent.OnQuestCompleted.AddUFunction(this, n"QuestCompleted");
		
		System::SetTimerForNextTick(this, "InitQuests"); // idk why but its necessary
	}

	// - QUESTS -

	UFUNCTION()
	void QuestBegun(FQuestEntry Entry)
	{
		if (!HasQuest(Entry, GetCurrentQuest())) // The quest that completed is not from this NPC
			return;

		QuestBillboard.SetSprite(FindQuestIcon(n"unsatisfied"));

		QuestBegunEvent();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Quest Begun")
	void QuestBegunEvent()
	{}

	UFUNCTION()
	void QuestProgressed(FQuestEntry Entry)
	{
		if (!HasQuest(Entry, GetCurrentQuest())) // The quest that completed is not from this NPC
			return;

		if (!Entry.IsCompleted)
			return;

		QuestBillboard.SetSprite(FindQuestIcon(n"completed"));
	}

	UFUNCTION()
	void QuestCompleted(FQuestEntry Entry)
	{
		if (!HasQuest(Entry, GetCurrentQuest())) // The quest that completed is not from this NPC
			return;

		AvailableQuests.RemoveAt(0);

		bool HasAdditionalQuests = AvailableQuests.Num() > 0;
		if (!HasAdditionalQuests)
		{
			QuestBillboard.SetHiddenInGame(true);
			HasQuests = false;
			return;
		}

		QuestBillboard.SetSprite(FindQuestIcon(n"progressed"));

		QuestCompletedEvent();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Quest Completed")
	void QuestCompletedEvent()
	{}

	UFUNCTION(BlueprintPure)
	UQuest GetCurrentQuest()
	{
		if (AvailableQuests.Num() == 0)
			return nullptr;

		return AvailableQuests[0].Quest;
	}

	UFUNCTION(BlueprintPure)
	bool HasQuest(FQuestEntry Entry, UQuest Quest)
	{
		return Entry.Quest == Quest;
	}

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
	void ToggleSelection(AFishController InController)
	{
		if (IsSelected)
		{
			Deselect(InController);
			return;
		}

		Select(InController);
	}

	/**
	 * Selects the NPC, marking it as selected and notifying the controller.
	 */
	UFUNCTION()
	void Select(AFishController InController)
	{
		IsSelected = true;
		OnSelected();
		InController.OnInteract.Broadcast(this, ESelectionState::Selected);
	}

	/**
	 * Deselects the NPC, marking it as not selected and notifying the controller.
	 */
	UFUNCTION()
	void Deselect(AFishController InController)
	{
		IsSelected = false;
		OnDeselected();
		InController.OnInteract.Broadcast(this, ESelectionState::Deselected);
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

	UFUNCTION()
	bool LoadQuests()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerQuestLog", 0);
		if (SaveGame == nullptr)
			return false;

		auto LoadedSave = Cast<UQuestSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return false;

		for (auto& CompletedQuestID : LoadedSave.SavedCompletedQuests)
		{
			for (int i = AvailableQuests.Num() - 1; i >= 0; i--)
			{
				if (AvailableQuests[i].Quest.QuestID == CompletedQuestID)
				{
					AvailableQuests.RemoveAt(i);
					Print("Removed Completed Quest: " + CompletedQuestID.ToString(), 3.0f, FLinearColor::Green);
				}
			}
		}

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void InitQuests()
	{
		HasQuests = AvailableQuests.Num() > 0;

		if (!HasQuests)
		{
			QuestBillboard.SetHiddenInGame(true);
			return;
		}

		FQuestEntry Entry;
		auto QuestComp = FishState.QuestComponent;
		QuestComp.QuestLog.Find(GetCurrentQuest().QuestID, Entry);
		if (!IsValid(Entry.Quest))
		{
			UTexture2D Texture;
			QuestIcons.Find(n"not_started", Texture);
			QuestBillboard.SetSprite(Texture);
			return;
		}

		if (Entry.IsCompleted)
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
};