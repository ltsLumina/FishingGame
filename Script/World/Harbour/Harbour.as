class AHarbour : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Mesh;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }
};