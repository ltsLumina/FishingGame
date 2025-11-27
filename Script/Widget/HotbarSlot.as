class UHotbarSlot : UUserWidget
{
    UPROPERTY(BindWidget)
    UButton CastButton;

    UPROPERTY(BindWidget)
    UProgressBar CooldownBar;

    UPROPERTY()
    UAbilityData AbilityData;

    float CooldownPercent;

    UFUNCTION(BlueprintEvent)
    void Invoke()
    {
        if (OnCooldown)
            return;

        auto AbilityHandler = UAbilityHandlerComponent::Get(GetOwningPlayerPawn());
        AbilityHandler.InvokeAbility(AbilityData);
    }
    

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        CooldownPercent = 1.0f;

        CastButton.OnClicked.AddUFunction(this, n"Invoke");

        BP_Construct();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Construct")
    void BP_Construct() { }

    bool OnCooldown;

    UFUNCTION(BlueprintOverride)
    void Tick(FGeometry MyGeometry, float InDeltaTime)
    {
        if (!OnCooldown)
            return;

        CooldownPercent = Math::FInterpConstantTo(CooldownPercent, 0, InDeltaTime, 1);
        CooldownBar.SetPercent(CooldownPercent);

        if (CooldownPercent <= 0.01f || Math::IsNearlyZero(CooldownPercent))
        {
            CooldownPercent = 1.0f;
            OnCooldown = false;
        }
    }

    UFUNCTION()
    void StartCooldown()
    {
        OnCooldown = true;
        CooldownPercent = 1.0f;
    }
}