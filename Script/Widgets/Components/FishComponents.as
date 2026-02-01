class UFishButton : UFishWidgetComponent
{
	UPROPERTY(Category = "Content")
	protected FText Text = FText::FromString("Button");

	UPROPERTY(Category = "Content")
	protected int FontSize = 24;

	UPROPERTY(BindWidget)
	UButton Button;

	UPROPERTY(BindWidget)
	USizeBox SizeBox;

	UPROPERTY(BindWidget)
	UTextBlock Label;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		Label.SetText(!Text.IsEmpty() ? Text : FText::FromString("Button"));
		FSlateFontInfo Font = Label.Font;
		Font.Size = FontSize;
		Label.SetFont(Font);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();
		
		BindClickSound(this);
	}

	UFUNCTION()
	void SetText(FText InText)
	{
		Label.SetText(InText);
	}
}

class UFishComboButton : UFishWidgetComponent
{
	UPROPERTY(Category = "Content")
	protected FText Text = FText::FromString("Button");

	UPROPERTY(Category = "Content")
	protected int FontSize = 24;

	UPROPERTY(Category = "Content")
	protected TArray<FString> Options;
	default Options.Add("None");
	default Options.Add("Alpha");
	default Options.Add("Bravo");
	default Options.Add("Charlie");

	UPROPERTY(Category = "Content")
	protected FString SelectedOption = "None";

	UPROPERTY(BindWidget)
	UFishButton Button;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		auto Label = Button.Label;

		Label.SetText(!Text.IsEmpty() ? Text : FText::FromString("Button"));
		FSlateFontInfo Font = Label.Font;
		Font.Size = FontSize;
		Label.SetFont(Font);

		Label.SetText(FText::FromString(SelectedOption));
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();
		
		Button.Button.OnClicked.AddUFunction(this, n"OnClick");
		BindClickSound(Button);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnClick()
	{
		auto Label = Button.Label;

		int CurrentIndex = Options.FindIndex(SelectedOption);
		int NextIndex = (CurrentIndex + 1) % Options.Num();
		SelectedOption = Options[NextIndex];
		Label.SetText(FText::FromString(SelectedOption));
	}

	UFUNCTION(BlueprintPure)
	FString GetSelectedOption() const
	{
		return SelectedOption;
	}

	UFUNCTION(BlueprintPure)
	int GetSelectedIndex() const
	{
		return Options.FindIndex(SelectedOption);
	}
}

class UFishToggle : UFishWidgetComponent
{
	UPROPERTY(Category = "Content")
	protected FText Text = FText::FromString("Toggle");

	UPROPERTY(Category = "Content")
	protected int FontSize = 24;

	UPROPERTY(BindWidget)
	UFishButton Button;

	UPROPERTY(BindWidget)
	UCheckBox Toggle;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		auto Label = Button.Label;

		Label.SetText(!Text.IsEmpty() ? Text : FText::FromString("Toggle"));
		FSlateFontInfo Font = Label.Font;
		Font.Size = FontSize;
		Label.SetFont(Font);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();

		BindClickSound(Button);
		Toggle.OnCheckStateChanged.AddUFunction(this, n"OnToggleChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnToggleChanged(bool bIsChecked)
	{
		
	}

	UFUNCTION(BlueprintPure)
	bool IsChecked() const
	{
		return Toggle.IsChecked();
	}
}

class UFishComboBox : UFishWidgetComponent
{
	UPROPERTY(Category = "Content")
	protected TArray<FString> Options;

	UPROPERTY(Category = "Content")
	protected FString SelectedOption;

	UPROPERTY(Category = "Content")
	protected int FontSize = 24;

	UPROPERTY(BindWidget)
	UComboBoxString ComboBox;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		ComboBox.ClearOptions();
		for (FString OptionText : Options)
		{
			ComboBox.AddOption(OptionText);
		}

		ComboBox.SetSelectedOption(SelectedOption);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();

		ComboBox.OnSelectionChanged.AddUFunction(this, n"OnSelectionChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSelectionChanged(FString SelectedItem, ESelectInfo SelectionType)
	{
		SelectedOption = SelectedItem;

		if (ClickSound != nullptr)
        {
            Gameplay::PlaySound2D(ClickSound, 1, Math::RandRange(1, 1.05f));
        }
	}

	UFUNCTION(BlueprintPure)
	FString GetSelectedOption() const
	{
		return ComboBox.GetSelectedOption();
	}

	UFUNCTION(BlueprintPure)
	int GetSelectedIndex() const
	{
		return ComboBox.GetSelectedIndex();
	}

	UFUNCTION(BlueprintPure)
	TArray<FString> GetOptions() const
	{
		return Options;
	}
}

class UFishEditableText : UFishWidgetComponent
{
	UPROPERTY(Category = "Content")
	protected FText Text;

	UPROPERTY(Category = "Content")
	protected FText HintText = FText::FromString("Search...");

	UPROPERTY(Category = "Content")
	protected int FontSize = 24;

	UPROPERTY(BindWidget)
	UEditableText EditableText;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		EditableText.SetText(!Text.IsEmpty() ? Text : FText::FromString(""));
		EditableText.SetHintText(!HintText.IsEmpty() ? HintText : FText::FromString("Search..."));

		FSlateFontInfo Font = EditableText.Font;
		Font.Size = FontSize;
		EditableText.SetFont(Font);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();

		// TODO: play typing sound
		EditableText.OnTextChanged.AddUFunction(this, n"OnTextChanged_Internal");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTextChanged_Internal(const FText&in InText)
	{
		Text = InText;
	}

	UFUNCTION(BlueprintPure)
	FText GetText() const
	{
		return EditableText.GetText();
	}

	UFUNCTION(BlueprintPure)
	FText GetHintText() const
	{
		return EditableText.GetHintText();
	}

	UFUNCTION()
	void SetText(FText InText)
	{
		EditableText.SetText(InText);
	}

	UFUNCTION()
	void SetHintText(FText InHintText)
	{
		EditableText.SetHintText(InHintText);
	}
}

class UFishExitButton : UFishWidgetComponent
{
	/**
	 * The widget to hide when the button is clicked.
	 */
	UPROPERTY(Category = "Content", Meta = (EditCondition = "ExitRootWidget == false", EditCondition = "!CustomImplemnentation"))
	UFishWidget ExitWidget;

	/**
	 * If true, the button will hide the root widget when clicked.
	 */
	UPROPERTY(Category = "Content", Meta = (EditCondition = "ExitWidget == nullptr", EditCondition = "!CustomImplemnentation"))
	bool ExitRootWidget = false;

	UPROPERTY(Category = "Content")
	bool CustomImplemnentation = false;

	/**
	 * Optional new widget to open when exiting.
	 * If set, this widget will be shown when the exit button is clicked.
	 */
	UPROPERTY(Category = "Content")
	UFishWidget EntryWidget;

	UPROPERTY(BindWidget)
	UFishButton Button;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();

		BindClickSound(Button);
		Button.Button.OnClicked.AddUFunction(this, n"OnClick");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnClick()
	{
		if (CustomImplemnentation) return;

		if (ExitWidget != nullptr)
		{
			ExitWidget.Hide();
		}
		else if (ExitRootWidget)
		{
			if (LocalRootWidget != nullptr)
			{
				auto AsFishWidget = Cast<UFishWidget>(LocalRootWidget);
				if (AsFishWidget != nullptr)
				{
					AsFishWidget.Hide();
				}
				else
				{
					throw("LocalRootWidget is not a UFishWidget. Cannot perform exit action.");
				}
			}
		}
		else
		{
			throw("No ExitWidget assigned and ExitRootWidget is false. Cannot perform exit action.");
		}
	}

	UFishWidget GetLocalRootWidget() property
	{
		return Cast<UFishWidget>(GetOuter().GetOuter());
	}
}

UFUNCTION(BlueprintPure)
FString GetServerTags(TArray<FString> InTags)
{
	FString TagsString;
	for (FString Tag : InTags)
	{
		if (Tag.IsEmpty() || Tag == "None " || Tag == "None")
		{
			continue;
		}

		if (!TagsString.IsEmpty())
		{
			TagsString += ", ";
		}
		TagsString += Tag;
	}

	return TagsString;
}