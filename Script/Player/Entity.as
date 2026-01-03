class AFishEntity : ACharacter
{
	UPROPERTY(DefaultComponent)
	UWidgetComponent Nametag;

	UPROPERTY(Category = "Initialization", BlueprintHidden, EditDefaultsOnly, meta = (Units = "s", UIMin = "0.01", UIMax = "1.0", AdvancedDisplay))
	float RetryDelay = 0.1f;

	UPROPERTY(Category = "Initialization", BlueprintHidden, EditDefaultsOnly, meta = (AdvancedDisplay))
	int MaxTries = 50;

	UPROPERTY(Category = "Initialization", BlueprintReadOnly, NotVisible)
	bool bInitialized = false;
	
	/**
	 * Will always be valid after initialization.
	 * Unlike FishComponentBase, this reference will always point to the local player's FishCharacter.
	 */
	UPROPERTY(Category = "Fish Entity", BlueprintReadOnly, NotVisible, DisplayName = "Character")
	AFishCharacter Character;

	/**
	 * Will always be valid after initialization.
	 * Unlike FishComponentBase, this reference will always point to the local player's FishPlayerState.
	 */
	UPROPERTY(Category = "Fish Entity", BlueprintReadOnly, NotVisible, DisplayName = "Player State")
	AFishPlayerState FishState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		Initialize();
	}

	int Tries = 0;
	float InitializationTime = 0.0f;

	UFUNCTION(NotBlueprintCallable)
	private void Initialize()
	{
		if (bInitialized)
			return;

		Character = Cast<AFishCharacter>(GetFishCharacterBase(0));
		FishState = IsValid(Character) ? Cast<AFishPlayerState>(Character.PlayerState) : nullptr;

		if (!IsValid(Character) || !IsValid(FishState))
		{
			if (Tries < MaxTries)
			{
				Tries++;
				System::SetTimer(this, n"Initialize", RetryDelay, false);
				return;
			}

			PrintError(f"FishEntity: ({GetName()}) timed out! \nFailed to initialize: Character or PlayerState is null after multiple attempts.");
			return;
		}

		// both refs are valid here
		bInitialized = true;
		InitializationTime = Tries * RetryDelay;

		PostInitialize(Character, FishState, InitializationTime);
		ReceivePostInitialize(Character, FishState, InitializationTime);

		System::ClearTimer(this, "Initialize");

#if EDITOR
		Print(f"FishEntity: ({GetActorLabel()}) initialized successfully in {InitializationTime} seconds.", 3.0f, FLinearColor::Green);
#endif
	}

	/**
	 * Called after the component has been initialized and BeginPlay has run successfully.
	 * References to Character and State are guaranteed to be valid here.
	 * @note Tick is not enabled in BeginPlay by default. Calling to Super will enable it.
	 */
	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime)
	{
		SetActorTickEnabled(true);
	}

	/**
	 * Called after the component has been initialized and BeginPlay has run successfully.
	 * References to Character and State are guaranteed to be valid here.
	 * Components are also guaranteed to be initialized at this point.
	 * @note Tick is not enabled in BeginPlay by default. Calling to Super will enable it.
	 */
	UFUNCTION(BlueprintEvent, DisplayName = "Post Initialize")
	void ReceivePostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, float InInitializationTime)
	{}
};