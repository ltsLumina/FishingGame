class UHotbarSlot : UUserWidget
{
    UPROPERTY(BindWidget)
    UButton CastButton;

    UPROPERTY(BindWidget)
    UProgressBar CooldownBar;

    UPROPERTY()
    UAbilityData AbilityData;

    float CooldownPercent;

    UFUNCTION(NotBlueprintCallable)
    void Invoke()
    {
        if (OnCooldown)
            return;

        auto AbilityHandler = UAbilityHandlerComponent::Get(GetOwningPlayerPawn());
        AbilityHandler.InvokeAbility(AbilityData);

        BP_Invoke();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Invoke")
    void BP_Invoke() { }
    

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
        BP_Tick(MyGeometry, InDeltaTime);

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

    UFUNCTION(BlueprintEvent, DisplayName = "Tick")
    void BP_Tick(FGeometry MyGeometry, float InDeltaTime) { }

    UFUNCTION()
    void StartCooldown()
    {
        OnCooldown = true;
        CooldownPercent = 1.0f;
    }
}