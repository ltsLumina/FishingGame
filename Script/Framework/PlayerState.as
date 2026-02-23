event void FOnTitleUnlocked(FText NewTitle);
event void FOnTitleChanged(FText NewTitle);

class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Player Info | Title", VisibleAnywhere, SaveGame)
	FText Title = Text::EmptyText;

	UPROPERTY(Category = "Player Info | Title", VisibleAnywhere, SaveGame)
	TArray<FText> OwnedTitles;

	UPROPERTY(Category = "Player Info | Title", EditDefaultsOnly)
	UTitles TitlesDataAsset;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UStatsComponent StatsComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UInventoryComponent InventoryComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UEquipmentComponent EquipmentComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UExperienceComponent ExperienceComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UQuestComponent QuestComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UCollectionComponent CollectionComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UGamblingComponent GamblingComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UTokenComponent TokenComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UCurrencyComponent CurrencyComponent;

	UPROPERTY(Category = "Components", BlueprintReadOnly, NotVisible)
	UMinigameComponent MinigameComponent;

	UPROPERTY(Category = "Player Info | Title")
	FOnTitleUnlocked OnTitleUnlocked;

	UPROPERTY(Category = "Player Info | Title")
	FOnTitleChanged OnTitleChanged;

	AFishCharacter Character;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		StatsComponent = UStatsComponent::Get(this);
		InventoryComponent = UInventoryComponent::Get(this);
		EquipmentComponent = UEquipmentComponent::Get(this);
		ExperienceComponent = UExperienceComponent::Get(this);
		QuestComponent = UQuestComponent::Get(this);
		CollectionComponent = UCollectionComponent::Get(this);
		GamblingComponent = UGamblingComponent::Get(this);
		TokenComponent = UTokenComponent::Get(this);
		CurrencyComponent = UCurrencyComponent::Get(this);
		MinigameComponent = UMinigameComponent::Get(this);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		ResetPlayerState();
#endif
		TryLoadPlayerState();

		System::SetTimer(this, n"Init", 0.2f, false);

		BP_BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Init()
	{
		Character = Cast<AFishCharacter>(GetPawn());
		Character.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
	}

	UFUNCTION()
	void OnFishCaught(AFish Fish, UBait Bait, UFishingHoleComponent FishingHole)
	{
		TArray<FString> AllTitles;
		TitlesDataAsset.Titles.GetKeys(AllTitles);

		for (int i = 0; i < AllTitles.Num(); i++)
		{
			auto TitleName = FText::FromString(AllTitles[i]);
			if (OwnedTitles.Contains(TitleName))
			{
				continue; // already owned
			}

			auto Condition = TitlesDataAsset.Titles[AllTitles[i]];

			if (Condition == nullptr)
			{
				PrintError(f"Title (\"{TitleName}\") has no unlock condition set!");
				continue;
			}

			if (Condition.IsSatisfied(Character, this, Fish) || Condition.AutoUnlock)
			{
				Title = TitleName;
				OwnedTitles.AddUnique(TitleName);
				Print(f"New title unlocked: \"{TitleName}\"", 5.0f, FLinearColor::Purple);
				OnTitleUnlocked.Broadcast(TitleName);
				OnTitleChanged.Broadcast(TitleName);
				break;
			}
		}
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION()
	void TryLoadPlayerState()
	{
		switch (LoadTitles())
		{
			case ELoadResult::Success:
				Print("Titles loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::NoData:
				Print("No titles save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load titles from save.", 25.0f);
				break;
		}

		// Load all components' data

		switch (StatsComponent.LoadStats())
		{
			case ELoadResult::Success:
				Print("Stats loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::NoData:
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
			case ELoadResult::NoData:
				Print("No inventory save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load inventory from save.", 25.0f);
				break;
		}

		switch (EquipmentComponent.LoadEquipment())
		{
			case ELoadResult::Success:
				Print("Equipment loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::NoData:
				Print("No equipment save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load equipment from save.", 25.0f);
				break;
		}

		switch (ExperienceComponent.LoadExperience())
		{
			case ELoadResult::Success:
				Print("Experience loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::NoData:
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
			case ELoadResult::NoData:
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
			case ELoadResult::NoData:
				Print("No collection save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load collection from save.", 25.0f);
				break;
		}

		switch (CurrencyComponent.LoadCurrencies())
		{
			case ELoadResult::Success:
				Print("Currencies loaded from save.", 3.0f, FLinearColor::Green);
				break;
			case ELoadResult::NoData:
				Print("No Currencies save found.", 3.0f, FLinearColor::Yellow);
				break;
			case ELoadResult::Failure:
				PrintError("Failed to load Currencies from save.", 25.0f);
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		SaveTitles();

		StatsComponent.SaveStats();
		InventoryComponent.SaveInventory();
		ExperienceComponent.SaveExperience();
		QuestComponent.SaveQuests();
		CollectionComponent.SaveCollection();
		CurrencyComponent.SaveCurrencies();
	}

	bool SaveTitles()
	{
		auto SaveGame = Gameplay::CreateSaveGameObject(UTitlesSaveGame);
		SaveGame.SavedTitle = Title;
		SaveGame.SavedOwnedTitles = OwnedTitles;

		return Gameplay::SaveGameToSlot(SaveGame, "PlayerTitles", 0);
	}

	ELoadResult LoadTitles()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerTitles", 0);
		if (SaveGame == nullptr)
			return ELoadResult::NoData;

		auto LoadedSave = Cast<UTitlesSaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		Title = LoadedSave.SavedTitle;
		OwnedTitles = LoadedSave.SavedOwnedTitles;

		return ELoadResult::Success;
	}

	UFUNCTION(Category = "Save Game")
	void ResetPlayerState()
	{
		Gameplay::DeleteGameInSlot("PlayerTitles", 0);

		Gameplay::DeleteGameInSlot("PlayerStats", 0);
		Gameplay::DeleteGameInSlot("PlayerInventory", 0);
		Gameplay::DeleteGameInSlot("PlayerExperience", 0);
		Gameplay::DeleteGameInSlot("PlayerQuestLog", 0);
		Gameplay::DeleteGameInSlot("PlayerCollection", 0);
		Gameplay::DeleteGameInSlot("PlayerCurrencies", 0);

		PrintWarning("Player state reset: all save data deleted.", 5.0f);
	}
};

enum ELoadResult
{
	Success,
	NoData,
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