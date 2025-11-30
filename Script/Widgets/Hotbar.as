class UHotbar : UUserWidget
{
    UPROPERTY(BindWidget)
    UUniformGridPanel HotbarGrid;

    TArray<UWidget> Slots;
    TArray<UHotbarSlot> GCD_Slots;
    TArray<UHotbarSlot> oGCD_Slots;

    UFUNCTION(BlueprintOverride)
    void Construct() // TODO: This will probably break when I decide to add slots in runtime.
    {
        Slots = HotbarGrid.GetAllChildren();

        for (UWidget Child : Slots)
        {
            UHotbarSlot HotbarSlot = Cast<UHotbarSlot>(Child);
            if (HotbarSlot != nullptr)
            {
                if (HotbarSlot.AbilityData == nullptr)
                    continue;

                auto Details = HotbarSlot.AbilityData.Details;
                auto CooldownType = Details.Cooldown.Type;

                if (CooldownType == ECooldownType::GCD)
                {
                    GCD_Slots.Add(HotbarSlot);
                }

                if (CooldownType == ECooldownType::oGCD)
                {
                    oGCD_Slots.Add(HotbarSlot);
                }
            }
        }
    }

    UFUNCTION(Category = "Ability")
    void GlobalCooldown()
    {
        for (UWidget Child : GCD_Slots)
        {
            UHotbarSlot HotbarSlot = Cast<UHotbarSlot>(Child);
            if (HotbarSlot != nullptr)
                HotbarSlot.StartCooldown();
        }
    }

    UFUNCTION(Category = "Ability")
    void OffGlobalCooldown(UAbilityData AbilityData)
    {
        for (UWidget Child : oGCD_Slots)
        {
            UHotbarSlot HotbarSlot = Cast<UHotbarSlot>(Child);
            if (HotbarSlot != nullptr && HotbarSlot.AbilityData == AbilityData)
            {
                HotbarSlot.StartCooldown();
                break;
            }
        }
    }
}