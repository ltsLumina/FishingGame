class AFishCharacter : AFishEntity
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {

    }
};

UFUNCTION(BlueprintPure)
AFishCharacter GetFishCharacterBase(int PlayerIndex = 0)
{
    return Cast<AFishCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}