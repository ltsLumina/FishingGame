event void FOnStatsLoadingComplete(bool bSuccess);

class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Components", VisibleInstanceOnly)
	UStatsComponent StatsComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly)
	UInventoryComponent InventoryComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly)
	UExperienceComponent ExperienceComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly)
	UQuestComponent QuestComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly)
	UCollectionComponent CollectionComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StatsComponent = UStatsComponent::Get(this);
		InventoryComponent = UInventoryComponent::Get(this);
		ExperienceComponent = UExperienceComponent::Get(this);
		QuestComponent = UQuestComponent::Get(this);
		CollectionComponent = UCollectionComponent::Get(this);

#if EDITOR
		ResetPlayerState();
#endif

		BP_BeginPlay();

		System::SetTimer(this, n"LatePlay", 0.2f, false);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(NotBlueprintCallable)
	void LatePlay()
	{
		if (StatsComponent.LoadStats()) Print("Stats loaded from save.", 3.0f, FLinearColor::Green);
		else Print("No stats save found.", 3.0f, FLinearColor::Yellow);

		if (InventoryComponent.LoadInventory()) Print("Inventory loaded from save.", 3.0f, FLinearColor::Green);
		else Print("No inventory save found.", 3.0f, FLinearColor::Yellow);

		if (ExperienceComponent.LoadExperience()) Print("Experience loaded from save.", 3.0f, FLinearColor::Green);
		else Print("No experience save found.", 3.0f, FLinearColor::Yellow);

		if (QuestComponent.LoadQuests()) Print("Quests loaded from save.", 3.0f, FLinearColor::Green);
		else Print("No quests save found.", 3.0f, FLinearColor::Yellow);

		if (CollectionComponent.LoadCollection()) Print("Collection loaded from save.", 3.0f, FLinearColor::Green);
		else Print("No collection save found.", 3.0f, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		StatsComponent.SaveStats();
		InventoryComponent.SaveInventory();
		ExperienceComponent.SaveExperience();
		QuestComponent.SaveQuests();
		// Collection is not saved -- it uses the inventory's data to rebuild itself on load.
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