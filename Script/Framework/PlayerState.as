class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Player Info", VisibleAnywhere)
	FText Title = FText::FromString("Angler");

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UStatsComponent StatsComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UInventoryComponent InventoryComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UExperienceComponent ExperienceComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UQuestComponent QuestComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UCollectionComponent CollectionComponent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		StatsComponent = UStatsComponent::Get(this);
		InventoryComponent = UInventoryComponent::Get(this);
		ExperienceComponent = UExperienceComponent::Get(this);
		QuestComponent = UQuestComponent::Get(this);
		CollectionComponent = UCollectionComponent::Get(this);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		ResetPlayerState();
#endif

		BP_BeginPlay();

		TryLoadPlayerState();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	void TryLoadPlayerState()
	{
		// Load all components' data from save files.

		switch (StatsComponent.LoadStats())
		{
			case ELoadResult::Success:
				Print("Stats loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::SuccessNoData:
				Print("No stats save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load stats from save.", 25.0f);
				break;
		}

		switch (InventoryComponent.LoadInventory())
		{
			case ELoadResult::Success:
				Print("Inventory loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::SuccessNoData:
				Print("No inventory save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load inventory from save.", 25.0f);
				break;
		}

		switch (ExperienceComponent.LoadExperience())
		{
			case ELoadResult::Success:
				Print("Experience loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::SuccessNoData:
				Print("No experience save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load experience from save.", 25.0f);
				break;
		}

		switch (QuestComponent.LoadQuests())
		{
			case ELoadResult::Success:
				Print("Quests loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::SuccessNoData:
				Print("No quest log save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load quest log from save.", 25.0f);
				break;
		}

		switch (CollectionComponent.LoadCollection())
		{
			case ELoadResult::Success:
				Print("Collection loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::SuccessNoData:
				Print("No collection save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load collection from save.", 25.0f);
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		StatsComponent.SaveStats();
		InventoryComponent.SaveInventory();
		ExperienceComponent.SaveExperience();
		QuestComponent.SaveQuests();
		CollectionComponent.SaveCollection();
	}

	UFUNCTION(Category = "Save Game")
	void ResetPlayerState()
	{
		Gameplay::DeleteGameInSlot("PlayerStats", 0);
		Gameplay::DeleteGameInSlot("PlayerInventory", 0);
		Gameplay::DeleteGameInSlot("PlayerExperience", 0);
		Gameplay::DeleteGameInSlot("PlayerQuestLog", 0);
		Gameplay::DeleteGameInSlot("PlayerCollection", 0);

		PrintWarning("Player state reset: all save data deleted.", 5.0f);
	}
};

enum ELoadResult
{
	Success,
	SuccessNoData,
	Failure
}

/**
 * Gets the AFishPlayerState of the local player.
 */
UFUNCTION(BlueprintPure, Category = "PlayerState")
AFishPlayerState GetFishPlayerStateBase()
{
	auto PC = Gameplay::GetPlayerController(0);
	if (PC == nullptr)
	{
		return nullptr;
	}

	auto PS = Cast<AFishPlayerState>(PC.PlayerState);
	if (PS == nullptr)
	{
		return nullptr;
	}

	return PS;
}