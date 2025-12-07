class AFishEntity : ACharacter
{
    default bReplicates = true;
    default bReplicateMovement = true;

    AFishPlayerState State;
	AFishCharacter Character;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimer(this, n"LatePlay", 0.3f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void LatePlay()
	{
        Character = Cast<AFishCharacter>(GetFishCharacterBase());
        State = Cast<AFishPlayerState>(Character.PlayerState);
	}
};