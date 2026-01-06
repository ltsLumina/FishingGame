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

    /**
     * @note Path is not case-sensitive.
     */
    UFUNCTION(Exec)
    void GrantRod(FString InRodName = "DA_Rod_DEBUG")
    {
        #if EDITOR
        FString RodName = InRodName;
        
        if (!RodName.StartsWith("DA_Rod_"))
        {
            RodName = "DA_Rod_" + RodName;
        }
        auto DebugRod = EditorAsset::GetEditorAsset(f"/Game/FishingGame/Blueprints/Rods/{RodName}.{RodName}");

        auto PS = GetFishPlayerStateBase();
        PS.InventoryComponent.EquipRod(FishingRod::GenerateRod(this, Cast<URodData>(DebugRod)));
        #endif
    }

    UFUNCTION(Exec)
    void GrantTitle(FString TitleKey)
    {
        auto PS = GetFishPlayerStateBase();
        FText TitleName = FText::FromString(TitleKey);

        if (PS.OwnedTitles.Contains(TitleName))
        {
            PrintError(f"Player already owns title \"{TitleName}\"!");
            return;
        }

        PS.OwnedTitles.AddUnique(TitleName);
        Print(f"Granted title \"{TitleName}\"!", 5.0f, FLinearColor::Green);
    }

    UFUNCTION(Exec)
    void GrantToken(FGameplayTag Token, int Amount = 1, int MaxTokens = 5, float Duration = 60.0f, bool RefreshDuration = true, FName Identifier = NAME_None)
    {
        auto PS = GetFishPlayerStateBase();
        FTokenEntry NewEntry;
        int CurrentTokens;
        bool bSuccess = PS.TokenComponent.AddTokenForDuration(Token, Amount, MaxTokens, Duration, RefreshDuration, Identifier, CurrentTokens, NewEntry);

        if (bSuccess)
        {
            Print(f"[Cheat] Granted {Amount}x token \"{Token}\"!", 5.0f, FLinearColor::Yellow);
        }
    }
}