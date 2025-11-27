event void FOnInvokeEvent(UAbilityData Ability);

class UAbilityHandlerComponent : UActorComponent
{
    /* Events */

    UPROPERTY()
    FOnInvokeEvent OnInvoke;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        OnInvoke.AddUFunction(this, n"InvokeAbility");
    }

    UFUNCTION(NotBlueprintCallable)
    void InvokeAbility(UAbilityData Ability)
    {
        Print("Ability invoked: " + Ability.GetName());

        BP_InvokeAbility(Ability);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Invoke Ability")
void BP_InvokeAbility(UAbilityData AbilityData) { }
};