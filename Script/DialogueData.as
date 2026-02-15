event void FOnStoryBeginEvent(UStory Story);
event void FOnContinueEvent(UStory Story);
event void FOnMakeChoiceEvent(UStory Story, FChoice Choice);
event void FOnStoryEndEvent(UStory Story);

class UStory : UPrimaryDataAsset
{
	UPROPERTY()
	TMap<FName, FEntry> Entries;
}

UCLASS(Meta = (DisplayName = "Story"))
class UStorySubsystem : UScriptGameInstanceSubsystem
{
	UPROPERTY()
	AStoryRuntime Runtime;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		Runtime = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Deinitialize()
	{
		if (IsValid(Runtime))
		{
			Runtime.DestroyActor();
			Runtime = nullptr;
		}
	}

	UFUNCTION()
	AStoryRuntime BeginStory(UStory Story)
	{
		if (IsValid(Runtime) && Runtime.IsInitialized)
		{
			PrintWarning("A story is already running! Ending it and starting the new one.");
			Runtime.StoryEnd.Broadcast(Runtime.Story);
		}

		if (IsValid(Runtime))
			Runtime.DestroyActor();
		Runtime = SpawnActor(AStoryRuntime);
		Runtime.Story = Story;
		Runtime.StoryIndex = 0;
		Runtime.IsInitialized = true;
		Runtime.StoryBegin.Broadcast(Story);

		System::SetTimer(this, n"OnStoryBegin", 0.1f, false);

		return Runtime;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnStoryBegin()
	{
		Runtime.StoryBegin.Broadcast(Runtime.Story);
	}
}

class AStoryRuntime : AActor
{
	UPROPERTY(VisibleInstanceOnly)
	UStory Story;

	UPROPERTY(VisibleInstanceOnly)
	int StoryIndex;

	bool IsInitialized;

	UPROPERTY()
	FOnStoryBeginEvent StoryBegin;
	UPROPERTY()
	FOnContinueEvent StoryContinue;
	UPROPERTY()
	FOnMakeChoiceEvent StoryMakeChoice;
	UPROPERTY()
	FOnStoryEndEvent StoryEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StoryEnd.AddUFunction(this, n"OnStoryEnd");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsInitialized)
			return;
		Print(f"storyindex: {StoryIndex}", 0);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnStoryEnd(UStory InStory)
	{
		//Story = nullptr;
		StoryIndex = -1;
		IsInitialized = false;
	}

	bool GetCurrentEntry(FEntry&out Entry)
	{
		if (!IsInitialized)
		{
			PrintError("Story has not yet been initialized!");
			Entry = FEntry();
			return false;
		}

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
		else
		{
			StoryEnd.Broadcast(Story);
		}

		Entry = FEntry();
		return false;
	}

	bool StoryOver;

	UFUNCTION()
	FText Continue()
	{
		if (StoryOver)
		{
			StoryEnd.Broadcast(Story);
			return FText();
		}

		FEntry Entry;
		if (GetCurrentEntry(Entry))
		{
			if (Entry.NextStory != nullptr)
			{
				Story = Entry.NextStory;
				StoryIndex = 0;
				return GetCurrentText();
			}
			
			if (Entry.IsEnd)
			{
				StoryOver = true;
				StoryContinue.Broadcast(Story);
				return Entry.CurrentLine;
			}

			StoryIndex++;

			StoryContinue.Broadcast(Story);
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

		return true; // if the story is over, we can consider it "continued"
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
			ChoiceText = Options[Choice].Text;

			auto JumpTo = Entry.Choices[Choice].JumpTo;
			Jump(JumpTo);

			StoryMakeChoice.Broadcast(Story, FChoice(ChoiceText));
		}
	}

	UFUNCTION()
	void Jump(FName EntryName)
	{
		TArray<FName> Keys;
		Story.Entries.GetKeys(Keys);
		for (int i = 0; i < Keys.Num(); i++)
		{
			if (Keys[i] == EntryName)
			{
				StoryIndex = i;
				return;
			}
		}

		PrintWarning("Couldn't find entry with name " + EntryName.ToString());
	}

	UFUNCTION(BlueprintPure, Meta = (ReturnDisplayName = "Has Choices"))
	bool GetCurrentChoices(TArray<FText>&out Choices)
	{
		if (!IsInitialized)
		{
			Choices = TArray<FText>();
			return false;
		}

		FEntry Entry;
		if (GetCurrentEntry(Entry))
		{
			Choices = TArray<FText>();
			for (auto& Choice : Entry.Choices)
			{
				Choices.Add(Choice.Text);
			}
			return Entry.HasChoices;
		}

		Choices = TArray<FText>();
		return false;
	}

	UFUNCTION(BlueprintPure)
	FText GetCurrentText()
	{
		if (!IsInitialized)
			return FText();

		FEntry Entry;
		if (GetCurrentEntry(Entry))
		{
			return Entry.CurrentLine;
		}

		return FText();
	}
}


namespace Story
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

	UPROPERTY(Meta = (Multiline))
	FText CurrentLine;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool HasChoices;

	UPROPERTY(Meta = (EditCondition = "HasChoices", TitleProperty = "Text"))
	TArray<FChoice> Choices;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool HasNextStory;

	UPROPERTY(Meta=(EditCondition = "HasNextStory", DisplayThumbnail="false"))
	UStory NextStory;

	UPROPERTY()
	bool IsEnd;
}

struct FChoice
{
	UPROPERTY()
	FText Text;

	UPROPERTY()
	FName JumpTo;

	FChoice(FText InText = FText(), FName InJumpTo = NAME_None)
	{
		Text = InText;
		JumpTo = InJumpTo;
	}
}