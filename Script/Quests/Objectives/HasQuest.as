
/**
 * Objective that requires the player to have another quest, optionally completed.
 */
UCLASS(Abstract)
class UHasQuestObjective : UQuestObjective
{
    UPROPERTY(Category = "Other Quest")
    UQuest Quest;

    UPROPERTY(Category = "Other Quest")
    bool MustBeCompleted = true;

    UFUNCTION(BlueprintOverride)
    bool IsSatisfied(AFishCharacter User)
    {
        FQuestEntry FoundEntry;
        if (User.FishState.QuestComponent.HasQuestOut(Quest, FoundEntry))
        {
            if (MustBeCompleted)
            {
                return FoundEntry.IsCompleted;
            }
            return true;
        }
        
        return false;
    }
}