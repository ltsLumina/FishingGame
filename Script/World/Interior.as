class AInterior : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Void;

	UPROPERTY(Meta=(MakeEditWidget))
    FVector EnterPosition;

    UPROPERTY(DefaultComponent)
    UInteractableComponent Interactable;

    UPROPERTY()
    AHouse Exterior;

    UFUNCTION()
    void Exit()
    {
        auto Pawn = Gameplay::GetPlayerPawn(0);
        FVector WorldPosition = Exterior.Interactable.WorldLocation;
        Pawn.Teleport(WorldPosition, Pawn.ActorRotation);
    }
};