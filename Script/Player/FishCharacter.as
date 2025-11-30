class AFishCharacter : AFishEntity
{
    UPROPERTY()
    UAbilityHandlerComponent AbilityHandler;

	 UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        

        BP_BeginPlay();
    }

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Possessed(AController NewController)
    {
#if EDITOR
        SetActorLabel(f"FishCharacter ({NewController.PlayerState.PlayerId})");
#endif
    }

    UFUNCTION(BlueprintEvent)
    void HotbarSlotPressed(int SlotIndex) { }
    
};

UFUNCTION(BlueprintPure)
AFishCharacter GetFishCharacterBase(int PlayerIndex = 0)
{
	return Cast<AFishCharacter>(Gameplay::GetPlayerCharacter(PlayerIndex));
}

float RoundTo(float Value, int DecimalPlaces)
    {
        float Multiplier = Math::Pow(10.0f, DecimalPlaces);
        return Math::RoundToFloat(Value * Multiplier) / Multiplier;
    }