class AFishCharacter : AFishEntity
{
    
};

UFUNCTION(BlueprintPure)
AFishCharacter GetFishCharacterBase(int PlayerIndex = 0)
{
    return Cast<AFishCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}