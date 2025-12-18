UCLASS(Abstract)
class UFishComponentBase : UActorComponent
{
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
        // if this is a player state component:

		State = Cast<AFishPlayerState>(GetOwner());
        if (State != nullptr)
             Character = Cast<AFishCharacter>(State.GetPawn());

        // if this is a character component:

        if (Character == nullptr)
        {
            Character = Cast<AFishCharacter>(GetOwner());
            if (Character != nullptr)
                State = Cast<AFishPlayerState>(Character.PlayerState);
        }
	}
};