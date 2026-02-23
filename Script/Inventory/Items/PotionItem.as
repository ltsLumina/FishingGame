class UPotionItem : UItem
{
	UPROPERTY(Category = "Potion | Info", ExposeOnSpawn, SaveGame)
	FPotionItemData PotionData;
}

struct FPotionItemData
{
	UPROPERTY(Category = "Potion | Info", SaveGame)
    float ManaRestoreAmount = 50.0f;

    /**
     * Duration of the potion's effect in seconds.
     * If zero, the effect is instantaneous.
     */
    UPROPERTY(Category = "Potion | Info", Meta = (Units = "s"), SaveGame)
    float Duration = 0.0f;

    /**
     * Cooldown time before the potion can be used again, in seconds.
     */
    UPROPERTY(Category = "Potion | Info", Meta = (Units = "s"), SaveGame)
    float Cooldown = 60.0f;
}
