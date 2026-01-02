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

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
						float InInitializationTime) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);
		
		if (AvailableQuests.Num() == 0)
			return;

		auto QuestComponent = InPlayerState.QuestComponent;
		QuestComponent.OnQuestBegun.AddUFunction(this, n"QuestBegun");
		QuestComponent.OnQuestProgressed.AddUFunction(this, n"QuestProgressed");
		QuestComponent.OnQuestCompleted.AddUFunction(this, n"QuestCompleted");

		SetQuestSprite();
	}

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

		//if (AvailableQuests.Num() > 0) 
		//	System::SetTimer(this, n"SetQuestSprite", 1.5f, false);

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void SetQuestSprite()
	{
		FQuestEntry Entry;
		auto QuestComp = FishState.QuestComponent;
		QuestComp.QuestLog.Find(AvailableQuests[0].Quest.QuestID, Entry);
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
};