class AFishEntity : ACharacter
{
	UPROPERTY(NotVisible)
    AFishPlayerState State;
	AFishCharacter Character;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimer(this, n"LatePlay", 0.2f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void LatePlay()
	{
        Character = Cast<AFishCharacter>(GetFishCharacterBase());
        State = Cast<AFishPlayerState>(Character.PlayerState);
	}
};