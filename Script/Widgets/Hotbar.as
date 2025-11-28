class UHotbar : UUserWidget
{
    UPROPERTY(BindWidget)
    UUniformGridPanel HotbarGrid;

    UFUNCTION()
    void GlobalCooldown()
    {
        for (UWidget Child : HotbarGrid.GetAllChildren())
        {
            UHotbarSlot HotbarSlot = Cast<UHotbarSlot>(Child);
            if (HotbarSlot != nullptr)
            {
                HotbarSlot.StartCooldown();
            }
        }
    }
}