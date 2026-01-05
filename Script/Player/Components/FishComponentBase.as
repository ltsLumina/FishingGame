event void FOnInitialized(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime);

UCLASS(Abstract)
class UFishComponentBase : UActorComponent
{
	UPROPERTY(Category = "Component", BlueprintReadOnly, EditDefaultsOnly)
	EFishComponentType ComponentType;

	UPROPERTY(Category = "Component", BlueprintHidden, EditDefaultsOnly, meta = (Units = "s", UIMin = "0.01", UIMax = "1.0", AdvancedDisplay))
	float RetryDelay = 0.1f;

	UPROPERTY(Category = "Component", BlueprintHidden, EditDefaultsOnly, meta = (AdvancedDisplay))
	int MaxTries = 50;

	UPROPERTY(Category = "Initialization", BlueprintReadOnly, NotVisible)
	bool bInitialized = false;

	/**
	 * By default, components in unreal run their BeginPlay before their owning Actor's BeginPlay has run.
	 * This can lead to issues where the owning Actor is not fully initialized when the component's BeginPlay runs.
	 * Setting this to true will delay initialization of the component until after the owning Actor has initialized.
	 * @note Must be set before BeginPlay is called. (i.e., in the constructor)
	 */
	UPROPERTY(Category = "Initialization", BlueprintHidden, NotVisible)
	bool bWaitForOwningActorInitialized = false;

	/**
	 * Will always be valid after initialization.
	 * @note May be null during BeginPlay depending on ComponentType.
	 */
	UPROPERTY(Category = "Fish Component", BlueprintReadOnly, NotVisible, DisplayName = "Character")
	AFishCharacter Character;

	/**
	 * Will always be valid after initialization.
	 * @note May be null during BeginPlay depending on ComponentType.
	 */
	UPROPERTY(Category = "Fish Component", BlueprintReadOnly, NotVisible, DisplayName = "Player State")
	AFishPlayerState PlayerState;

	UPROPERTY(Category = "Events", EditAnywhere, NotVisible)
	FOnInitialized OnInitialized;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);

		Initialize();
	}

	int Tries = 0;
	float InitializationTime = 0.0f;

	UFUNCTION(NotBlueprintCallable)
	private void Initialize()
	{
		if (bInitialized)
			return;

		switch (ComponentType)
		{
			case EFishComponentType::PlayerState:
				PlayerState = Cast<AFishPlayerState>(GetOwner());
				if (IsValid(PlayerState))
				{
					Character = Cast<AFishCharacter>(PlayerState.GetPawn());
				}
				break;

			case EFishComponentType::Character:
				Character = Cast<AFishCharacter>(GetOwner());
				if (IsValid(Character))
				{
					PlayerState = Cast<AFishPlayerState>(Character.PlayerState);
				}
				break;
		}

		// retry until both refs are valid or we exhaust tries
		if (!IsValid(Character) || !IsValid(PlayerState))
		{
			if (Tries < MaxTries)
			{
				Tries++;
				System::SetTimer(this, n"Initialize", RetryDelay, false);
				return;
			}

			PrintError(f"FishComponentBase: ({GetName()}) timed out! \nFailed to initialize: Character or PlayerState is null after multiple attempts.");
			return;
		}

		if (bWaitForOwningActorInitialized && !GetOwner().HasActorBegunPlay())
		{
			PrintWarning(f"{GetName()} is waiting for owning actor to initialize...", 3.0f);
			Tries++;
			System::SetTimer(this, n"Initialize", RetryDelay, false);
			return;
		}

		bInitialized = true;
		InitializationTime = Tries * RetryDelay;

		PostInitialize(Character, PlayerState, InitializationTime);
		ReceivePostInitialize(Character, PlayerState, InitializationTime);
		OnInitialized.Broadcast(Character, PlayerState, InitializationTime);
	}

	/**
	 * Called after the component has been initialized and BeginPlay has run successfully.
	 * References to Character and State are guaranteed to be valid here.
	 * @note Tick is not enabled in BeginPlay by default. Calling to Super will enable it.
	 */
	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime)
	{
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Post Initialize")
	void ReceivePostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime)
	{}
};

enum EFishComponentType
{
	PlayerState,
	Character
}