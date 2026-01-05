#if EDITOR
namespace BlueprintValidation
{
    /**
     * Returns the generated blueprint asset from a given asset.
     * This reference can cast to the appropriate class to access its properties.
     * Not to be confused with Editor::GetBlueprintAsset, which returns the UBlueprint object, which does not have the properties of the blueprint class.
     */
	UFUNCTION(Category = "Validation", Meta=(WorldContext="InAsset"))
	const UObject GetBlueprint(UObject InAsset)
	{
		auto Blueprint = Editor::GetBlueprintAsset(InAsset);

		TArray<FSubobjectDataHandle> SubobjectData;
		Subsystem::GetEngineSubsystem(USubobjectDataSubsystem).GatherSubobjectDataForBlueprint(Blueprint, SubobjectData);
		FSubobjectData Data;
		SubobjectData::GetData(SubobjectData[0], Data);
		auto BlueprintAsset = SubobjectData::GetObjectForBlueprint(Data, Blueprint);

		return BlueprintAsset;
	}

    /**
     * Gathers all components from a blueprint asset.
     * @param InAsset The blueprint asset to gather components from.
     * @param Components The array to store the gathered components.
     * @return True if components were found, false otherwise.
     */
    UFUNCTION(Category = "Validation", Meta=(WorldContext="InAsset"))
    bool GetBlueprintComponents(UObject InAsset, TArray<UObject>&out Components)
    {
        auto Blueprint = Editor::GetBlueprintAsset(InAsset);
        TArray<FSubobjectDataHandle> SubobjectData;
		Subsystem::GetEngineSubsystem(USubobjectDataSubsystem).GatherSubobjectDataForBlueprint(Blueprint, SubobjectData);
        for (auto& Component : SubobjectData)
        {
            FSubobjectData Data;
            SubobjectData::GetData(Component, Data);

            Components.Add(SubobjectData::GetObject(Data));
        }

        return Components.Num() > 0;
    }

    UFUNCTION(Category = "Validation", Meta=(WorldContext="InAsset"))
    UObject GetBlueprintComponent(UObject InAsset, UClass ComponentClass)
    {
        TArray<UObject> Components;
        if (GetBlueprintComponents(InAsset, Components))
        {
            for (int i = 0; i < Components.Num(); i++)
            {
                if (Components[i].IsA(ComponentClass))
                {
                    return Components[i];
                }
            }
        }

        return nullptr;
    }
}

class UFishValidator : UEditorValidatorBase
{
	UPROPERTY(Category = "Validation")
	TArray<TSubclassOf<UObject>> ValidatedClasses;
	default ValidatedClasses.Empty();

	UPROPERTY(Category = "Validation")
	bool ValidateBlueprint = true;

	UPROPERTY(Category = "Validation", BlueprintReadOnly, Meta = (Multiline))
	FText ValidationMessage = FText::FromString("Please provide a validation message.");
    
	UFUNCTION(BlueprintOverride)
	bool CanValidate(EDataValidationUsecase InUsecase) const
	{
        return true;
	}
    
	UFUNCTION(BlueprintOverride)
	bool CanValidateAsset(UObject InAsset) const
	{
        auto Blueprint = Editor::GetBlueprintAsset(InAsset);
        bool IsBlueprint = Blueprint != nullptr;
        UClass GeneratedBlueprint = IsBlueprint ? Editor::GetBlueprintAsset(InAsset).GeneratedClass : nullptr;

        for (auto& ValidatedClass : ValidatedClasses)
        {
            if (InAsset.IsA(ValidatedClass) || (ValidateBlueprint && IsBlueprint && GeneratedBlueprint.IsChildOf(ValidatedClass)))
            {
                return true;
            }
        }
        return false;
	}
}

class UQuestValidator : UFishValidator
{
    default ValidatedClasses.Add(UQuest);

    UFUNCTION(BlueprintOverride)
    EDataValidationResult ValidateLoadedAsset(UObject InAsset)
    {
        auto Quest = Cast<UQuest>(InAsset);
        if (Quest.Objectives.Num() == 0)
        {
            AssetFails(InAsset, FText::FromString("Quest has no objectives!"));
            return EDataValidationResult::Invalid;
        }

        for (auto& Objective : Quest.Objectives)
        {
            if (Objective == nullptr)
            {
                AssetFails(InAsset, FText::FromString("Quest has a null objective!"));
                return EDataValidationResult::Invalid;
            }
        }

        return EDataValidationResult::Valid;
    }
}

class UAbilityTableValidator : UFishValidator
{
	default ValidatedClasses.Add(UDataTable);

    UFUNCTION(BlueprintOverride)
    bool CanValidate(EDataValidationUsecase InUsecase) const
    {
        return false;
    }

	UFUNCTION(BlueprintOverride)
	EDataValidationResult ValidateLoadedAsset(UObject InAsset)
	{
        auto DataTable = Cast<UDataTable>(InAsset);
        TArray<FAbilityUnlockInfo> Rows;
        DataTable.GetAllRows(Rows);
        for (auto& Row : Rows)
        {
            if (Row.Ability.IsNull())
            {
                AssetFails(InAsset, FText::FromString("\nAbilityUnlockTable has invalid AbilityData references in the AbilityHandlerComponent! \nDo NOT save the asset. If possible, undo your last changes, then right-click the asset and select 'Reload'."));
                return EDataValidationResult::Invalid;
            }
        }
        
        return EDataValidationResult::Valid;
	}
}

class UIDValidator : UFishValidator
{
    default ValidatedClasses.Add(UQuest);
	default ValidatedClasses.Add(UItem);
	default ValidatedClasses.Add(AFishNPC);

	UFUNCTION(BlueprintOverride)
	EDataValidationResult ValidateLoadedAsset(UObject InAsset)
	{
		bool IsBlueprint = Editor::GetBlueprintAsset(InAsset) != nullptr;

		if (InAsset.IsA(UQuest))
		{
			auto Quest = Cast<UQuest>(InAsset);
			if (Quest.QuestID.IsNone())
			{
				Quest.QuestID = GenerateID(Quest.QuestName);
				AssetWarning(InAsset, FText::FromString("Asset has an incorrect ID. An auto-generated one has been supplied in its place."));
				return EDataValidationResult::Invalid;
			}
		}

		if (InAsset.IsA(UItem))
		{
			auto Item = Cast<UItem>(InAsset);
			if (Item.GetID().IsNone())
			{
				Item.BaseData.ID = GenerateID(Item.GetItemName());
				AssetWarning(InAsset, FText::FromString("Asset has an incorrect ID. An auto-generated one has been supplied in its place."));
				return EDataValidationResult::Invalid;
			}
		}

		if (IsBlueprint)
		{
            auto BlueprintAsset = BlueprintValidation::GetBlueprint(InAsset);
			if (BlueprintAsset.IsA(AFishNPC))
			{
				auto NPC = Cast<AFishNPC>(BlueprintAsset);
				if (NPC.NPC_ID.IsNone() || NPC.NPC_ID != GenerateID(NPC.NPCName))
				{
					NPC.NPC_ID = GenerateID(NPC.NPCName);
					AssetWarning(InAsset, FText::FromString(f"Asset has an incorrect ID. An auto-generated one has been supplied in its place. (\"{NPC.NPC_ID.ToString()}\")"));
					return EDataValidationResult::Invalid;
				}
			}
		}

		return EDataValidationResult::Valid;
	}
}
#endif