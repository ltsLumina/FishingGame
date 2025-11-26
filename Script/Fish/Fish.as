class AFish : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    /* psuedo code for future implementation
    - name
    - flavour text
    - size
    - weight
    - type
    - rarity
    */

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }
};