/**
 * Objective that requires the player to speak with a specific NPC.
 */
UCLASS(Abstract)
class USpeakWithNPCObjective : UQuestObjective
{
    UPROPERTY()
    TSoftObjectPtr<AFishNPC> NPC;

    UFUNCTION(BlueprintOverride)
	bool IsSatisfied(AFishCharacter User)
	{
		auto PlayerController = Cast<AFishController>(User.GetController());
        if (PlayerController == nullptr) return false;

        if (NPC.IsNull()) PrintError("USpeakToNPC: NPC is null!");
        return PlayerController.SelectedNPC == NPC.Get();
	}
}