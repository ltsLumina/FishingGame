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

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay()
	{}
};

AFishPlayerState GetFishPlayerStateBase()
{
	return Cast<AFishPlayerState>(GetFishCharacterBase().PlayerState);
}