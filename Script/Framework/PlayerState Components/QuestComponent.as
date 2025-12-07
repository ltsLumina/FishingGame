class UQuestComponent : UFishComponent
{
	UPROPERTY(Category = "Quest")
	UQuest CurrentQuest;

	UPROPERTY(Category = "Quest")
	int Progress;

	UPROPERTY(Category = "Quest")
	int Steps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BP_BeginPlay();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay() { }

	void LatePlay() override
	{
		Super::LatePlay();
		State.InventoryComponent.OnInventoryChanged.AddUFunction(this, n"HandleInventoryChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleInventoryChanged(FName ItemID, UItem Item, EInventoryChangeType Change)
	{
		if (CurrentQuest == nullptr)
			return;

		for (auto& Objective : CurrentQuest.Objectives)
		{
			if (Objective.IsSatisfied(Character))
			{
				Print("Objective satisfied: " + Objective.GetName(), 3.0f, FLinearColor::Green);
			}
		}
	}
};