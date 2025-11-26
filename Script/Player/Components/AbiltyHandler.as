event void FOnInvokeEvent(UAbilityData Ability);

class UAbilityHandlerComponent : UActorComponent
{
    UPROPERTY()
    FOnInvokeEvent OnInvoke;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        OnInvoke.AddUFunction(this, n"InvokeAbility");
    }

    UFUNCTION(BlueprintEvent)
    void InvokeAbility(UAbilityData Ability)
    {
        Print("Ability invoked: " + Ability.GetName());
    }
};