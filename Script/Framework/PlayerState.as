class AFishPlayerState : APlayerState
{
	UPROPERTY(Category = "Components", VisibleInstanceOnly, BlueprintHidden)
	UStatsComponent StatsComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly, BlueprintHidden)
	UInventoryComponent InventoryComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly, BlueprintHidden)
	UExperienceComponent ExperienceComponent;

	UPROPERTY(Category = "Components", VisibleInstanceOnly, BlueprintHidden)
	UQuestComponent QuestComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StatsComponent = UStatsComponent::Get(this);
		InventoryComponent = UInventoryComponent::Get(this);
		ExperienceComponent = UExperienceComponent::Get(this);
		QuestComponent = UQuestComponent::Get(this);

		//ResetPlayerState();

		BP_BeginPlay();

		System::SetTimer(this, n"LatePlay", 0.2f, false);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	UFUNCTION(NotBlueprintCallable)
	void LatePlay()
	{
		if (InventoryComponent.LoadInventory())
			Print(f"Loaded Inventory successfully.", 5.0f);
		else Print("No Inventory save found.", 5.0f);
		if (StatsComponent.LoadStats())
			Print(f"Loaded Stats successfully.", 5.0f);
		else Print("No Stats save found.", 5.0f);
		if (ExperienceComponent.LoadExperience())
			Print(f"Loaded Experience successfully.", 5.0f);
		else Print("No Experience save found.", 5.0f);
		if (QuestComponent.LoadQuests())
			Print(f"Loaded Quests successfully.", 5.0f);
		else Print("No Quests save found.", 5.0f);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		StatsComponent.SaveStats();
		InventoryComponent.SaveInventory();
		ExperienceComponent.SaveExperience();
		QuestComponent.SaveQuests();
	}

	UFUNCTION(Category = "Save Game")
	void ResetPlayerState()
	{
		Gameplay::DeleteGameInSlot("PlayerStats", 0);
		Gameplay::DeleteGameInSlot("PlayerInventory", 0);
		Gameplay::DeleteGameInSlot("PlayerExperience", 0);
		Gameplay::DeleteGameInSlot("PlayerQuestLog", 0);
	}
};

AFishPlayerState GetFishPlayerStateBase()
{
	return Cast<AFishPlayerState>(GetFishCharacterBase().PlayerState);
}