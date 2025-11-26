class AFishEntity : ACharacter
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        
    }
};