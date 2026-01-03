class UFishCheatManager : UCheatManager
{
    UFUNCTION(Exec)
    void ResetPlayerState()
    {
        GetFishPlayerStateBase().ResetPlayerState();
    }

    UFUNCTION(Exec)
    void GrantFish(FName FishID, int Quantity, EFishTag Tag = EFishTag::None)
    {
        auto PS = GetFishPlayerStateBase();

        UFishItem FishItem = NewObject(this, UFishItem);
        FishItem.BaseData.ID = FishID;
        FishItem.BaseData.ItemName = FText::FromString(FishID.ToString());
        
        FInventoryInstanceData InventoryInstance;
        FFishInstanceData FishInstance;
        FishInstance.Tag = Tag;

        InventoryInstance.FishInstanceData = FishInstance;
        
        PS.InventoryComponent.AddItem(FishItem, InventoryInstance, Quantity);

        Print(f"Granted {Quantity}x {FishID}!", 5.0f, FLinearColor::Green);
    }

    UFUNCTION(Exec)
    void LevelUp(int Levels = 1)
    {
        auto PS = GetFishPlayerStateBase();
        for (int i = 0; i < Levels; i++)
            PS.ExperienceComponent.LevelUp();

        Print(f"Leveled up {Levels} times!", 5.0f, FLinearColor::Green);
    }
}