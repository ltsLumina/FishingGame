event void FOnStatsLoadingComplete(bool bSuccess);

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

	UPROPERTY(Category = "Components", VisibleInstanceOnly, BlueprintHidden)
	UCollectionComponent CollectionComponent;
	
	UPROPERTY(Category = "Events")
	FOnStatsLoadingComplete OnStatsLoadingComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StatsComponent = UStatsComponent::Get(this);
		InventoryComponent = UInventoryComponent::Get(this);
		ExperienceComponent = UExperienceComponent::Get(this);
		QuestComponent = UQuestComponent::Get(this);
		CollectionComponent = UCollectionComponent::Get(this);

#if EDITOR
		//ResetPlayerState();
#endif

		BP_BeginPlay();

		System::SetTimer(this, n"LatePlay", 0.2f, false);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}

	FAsyncLoadGameFromSlotDynamicDelegate InventoryDelegate;
	FAsyncLoadGameFromSlotDynamicDelegate ExperienceDelegate;

	UFUNCTION(NotBlueprintCallable)
	void LatePlay()
	{
		InventoryComponent.AsyncLoadInventory(InventoryDelegate);
		InventoryDelegate.BindUFunction(this, n"OnInventoryLoaded_Internal");
		
		FAsyncLoadGameFromSlotDynamicDelegate StatsDelegate;
		StatsComponent.AsyncLoadStats(StatsDelegate);
		StatsDelegate.BindUFunction(this, n"OnStatsLoaded_Internal");
		
		ExperienceComponent.AsyncLoadExperience(ExperienceDelegate);
		ExperienceDelegate.BindUFunction(this, n"OnExperienceLoaded_Internal");
		
		FAsyncLoadGameFromSlotDynamicDelegate QuestDelegate;
		QuestComponent.LoadQuests(QuestDelegate);
		QuestDelegate.BindUFunction(this, n"OnQuestsLoaded_Internal");
	}

	UFUNCTION()
	private void OnInventoryLoaded_Internal(FString SlotName, int UserIndex, USaveGame SaveGameObject)
	{
		Print("Inventory loaded!.", 3.0f, FLinearColor::Green);
	}

	UFUNCTION()
	private void OnStatsLoaded_Internal(FString SlotName, int UserIndex, USaveGame SaveGameObject)
	{
		Print("Stats loaded!.", 3.0f, FLinearColor::Green);
	}

	UFUNCTION()
	private void OnExperienceLoaded_Internal(FString SlotName, int UserIndex, USaveGame SaveGameObject)
	{
		Print("Experience loaded!.", 3.0f, FLinearColor::Green);
	}

	UFUNCTION()
	private void OnQuestsLoaded_Internal(FString SlotName, int UserIndex, USaveGame SaveGameObject)
	{
		Print("Quests loaded!.", 3.0f, FLinearColor::Green);
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

UFUNCTION(BlueprintPure, Category = "PlayerState")
AFishPlayerState GetFishPlayerStateBase()
{
	return Cast<AFishPlayerState>(GetFishCharacterBase().PlayerState);
}