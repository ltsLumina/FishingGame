event void FOnMinigameFinished(EMinigameResult Result);

UCLASS(Abstract, ClassGroup = "Fishing")
class UMinigameComponent : UFishComponentBase
{
	UPROPERTY(Category = "Minigame", Meta = (EditCondition = "MinigameWidgetClass==nullptr", EditConditionHides))
	TSubclassOf<UMinigameWidget> MinigameWidgetClass;

	UPROPERTY(Category = "Minigame", EditDefaultsOnly)
	int PlayerHealth = 3;

	UPROPERTY(Category = "Minigame", EditDefaultsOnly)
	int FishHealth = 5;

	UPROPERTY(Category = "Minigame", VisibleAnywhere)
	bool HasDamageImmunity;

	UPROPERTY(Category = "Minigame", EditDefaultsOnly)
	float ImmunityDuration = 1;

	UPROPERTY(Category = "Minigame", VisibleInstanceOnly)
	float RemainingImmunity;

	UPROPERTY(Category = "Events")
	FOnMinigameFinished MinigameFinished;

	UMinigameWidget MinigameWidget;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RemainingImmunity = Math::Max(0, RemainingImmunity - DeltaSeconds);
		HasDamageImmunity = RemainingImmunity > 0;
	}

	UFUNCTION()
	void StartMinigame(UFishItem FishItem)
	{
		FishHealth = Math::RandRange(10, 25);
		
		UUserWidget Widget = WidgetBlueprint::CreateWidget(MinigameWidgetClass, Gameplay::GetPlayerController(0));

		MinigameWidget = Cast<UMinigameWidget>(Widget);
		MinigameWidget.Data = FMinigameData(PlayerHealth, FishHealth, FishItem);

		Widget::SetInputMode_GameAndUIEx(Gameplay::GetPlayerController(0), MinigameWidget, EMouseLockMode::LockOnCapture, false);

		Widget.AddToViewport();
	}

	UFUNCTION()
	void EndMinigame(EMinigameResult Result)
	{
		Widget::SetInputMode_GameAndUIEx(Gameplay::GetPlayerController(0), nullptr, EMouseLockMode::DoNotLock, true);

		MinigameWidget.BP_RemoveFromParent();
		MinigameFinished.Broadcast(Result);
	}

	UFUNCTION()
	void TakeDamage(int Damage)
	{
		if (HasDamageImmunity)
			return;

		StartDamageImmunity();

		PlayerHealth -= Damage;
		Print(f"Took Damage!", 2, FLinearColor::Red);

		// Gameplay::PlaySound2D()

		if (PlayerHealth <= 0)
		{
			MinigameWidget.BP_RemoveFromParent();
			MinigameFinished.Broadcast(EMinigameResult::Failure);
		}
	}

	UFUNCTION()
	void DealDamage(int Damage)
	{
		FishHealth--;
		//Gameplay::PlaySound2D() // successful loop sound

		if (FishHealth <= 0)
		{
			// Gameplay::PlaySound2D() win sound
			EndMinigame(EMinigameResult::Success);
		}
	}

	void StartDamageImmunity()
	{
		HasDamageImmunity = true;
		RemainingImmunity = ImmunityDuration;
	}
}

struct FMinigameData
{
	UPROPERTY(Category = "Minigame", BlueprintReadOnly)
	int PlayerHealth = 3;

	UPROPERTY(Category = "Minigame", BlueprintReadOnly)
	int FishHealth = 5;

	UPROPERTY(Category = "Minigame", BlueprintReadOnly)
	UFishItem FishItem;

	FMinigameData(int InPlayerHealth, int InFishHealth, UFishItem InFishItem)
	{
		PlayerHealth = InPlayerHealth;
		FishHealth = InFishHealth;
		FishItem = InFishItem;
	}
}

enum EMinigameResult
{
	Success,
	Failure,
}