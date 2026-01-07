struct FDialogueEntry
{
    UPROPERTY()
    FText SpeakerName = FText::FromString("Speaker");
    
    UPROPERTY(Meta=(MultiLine))
    FText DialogueText;
}