class AFishEntity : ACharacter
{
	UPROPERTY(DefaultComponent)
	UWidgetComponent Nametag;

	/**
	 * The local player character reference.
	 * Will always point to the local player's character on the local machine, and be null on remote clients.
	 */
	UPROPERTY(BlueprintReadOnly, NotVisible)
	AFishCharacter Character;

	/**
	 * The local player state reference.
	 * Will always point to the local player's state on the local machine, and be null on remote clients.
	 */
	UPROPERTY(BlueprintReadOnly, NotVisible)
    AFishPlayerState State;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimer(this, n"LatePlay", 0.2f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void LatePlay()
	{
        Character = Cast<AFishCharacter>(GetFishCharacterBase(0));
        State = Cast<AFishPlayerState>(Character.PlayerState);
	}
};