event void FOnStoryBeginEvent(UStory Story);
event void FOnContinueEvent(UStory Story);
event void FOnMakeChoiceEvent(UStory Story, FChoice Choice);

class UStory : UPrimaryDataAsset
{
	UPROPERTY()
	TMap<FName, FEntry> Entries;
}

UCLASS(Meta = (DisplayName = "Story"))
class UStorySubsystem : UScriptGameInstanceSubsystem
{
    UPROPERTY()
    ADialogueRuntime DialogueRunner;
    
	UFUNCTION(BlueprintOverride)
	bool ShouldCreateSubsystem(UObject InOuter) const
	{
		return true;
	}

	UFUNCTION()
	ADialogueRuntime BeginStory(UStory Story)
	{
		DialogueRunner = SpawnActor(ADialogueRuntime);
		DialogueRunner.Story = Story;
		DialogueRunner.StoryIndex = 0;
		DialogueRunner.Initialized = true;

		return DialogueRunner;
	}
}

class ADialogueRuntime : AActor
{
	UPROPERTY(VisibleInstanceOnly)
	UStory Story;

	UPROPERTY(VisibleInstanceOnly)
	int StoryIndex;

	bool Initialized;

    UPROPERTY()
    FOnStoryBeginEvent StoryBegin;
    UPROPERTY()
    FOnContinueEvent StoryContinue;
    UPROPERTY()
    FOnMakeChoiceEvent StoryMakeChoice;

	bool GetCurrentEntry(FEntry&out Entry)
	{
		auto Entries = Story.Entries;

		TArray<FName> Keys;
		Entries.GetKeys(Keys);

		if (Keys.IsValidIndex(StoryIndex))
		{
			auto foo = Keys[StoryIndex];
			FEntry entry;
			auto found = Entries.Find(foo, entry);

			if (found)
			{
				Entry = entry;
				return true;
			}
			else
			{
				Entry = FEntry();
				return false;
			}
		}

        // Story finished
        Print("Story has ended.");

        StoryIndex = -1;

		Entry = FEntry();
		return false;
	}

	UFUNCTION()
	FText Continue()
	{
		if (!Initialized)
			PrintError("Story has not yet been initialized!");

		FEntry Entry;
		if (GetCurrentEntry(Entry))
		{
			StoryIndex++;
			return Entry.CurrentLine;
		}

		return FText();
	}

	UFUNCTION(Meta = (ReturnDisplayName = "Continued", DisplayName = "Continue if You Can"))
	bool ContinueIfYouCan(FText&out CurrentLine)
	{
		FEntry Entry;

		if (GetCurrentEntry(Entry))
		{
			if (Entry.HasChoices)
			{
				CurrentLine = Entry.CurrentLine;
				return false;
			}

			FText Text = Continue();
			CurrentLine = Text;
			return true;
		}

		return false;
	}

	UFUNCTION()
	void MakeChoice(int Choice, FText&out ChoiceText)
	{
		FEntry Entry;
		if (GetCurrentEntry(Entry))
		{
			if (!Entry.HasChoices)
			{
                PrintWarning("Can't make a choice on an entry with no choices!");
                return;
            }

			auto Options = Entry.Choices;
			ChoiceText = Options[Choice];
            StoryIndex++;
		}
	}

    UFUNCTION(BlueprintPure, Meta = (ReturnDisplayName = "Has Options"))
    bool GetCurrentChoices(TArray<FText>&out Choices)
    {
        FEntry Entry;
        if (GetCurrentEntry(Entry))
        {
            Choices = Entry.Choices;
            return Entry.HasChoices;
        }

        Choices = TArray<FText>();
        return false;
    }

    UFUNCTION(BlueprintPure)
    FText GetCurrentText()
    {
        FEntry Entry;
        if (GetCurrentEntry(Entry))
        {
            return Entry.CurrentLine;
        }

        return FText();
    }

    UFUNCTION(BlueprintPure)
    TArray<FText> GetAllText()
    {
        TArray<FText> AllText;
        
        for (auto Entry : Story.Entries)
        {
            AllText.Add(Entry.Value.CurrentLine);
        }

        return AllText;
    }
}

struct FChoice
{
	UPROPERTY()
	FText Text;
}

namespace Dialogue
{
	mixin FText GetText(FChoice Choice)
	{
		return Choice.Text;
	}
}

struct FEntry
{
	UPROPERTY()
	FText Speaker;

	UPROPERTY()
	FText CurrentLine;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool HasChoices;

	UPROPERTY(Meta = (EditCondition = "HasChoices"))
	TArray<FText> Choices;
}