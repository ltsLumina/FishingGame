class UFishButton : UFishWidgetComponent
{
    UPROPERTY(Category ="Content")
    protected FText Text = FText::FromString("Button");

    UPROPERTY(Category ="Content")
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
}

class UFishComboButton : UFishWidgetComponent
{
    UPROPERTY(Category ="Content")
    protected FText Text = FText::FromString("Button");

    UPROPERTY(Category ="Content")
    protected int FontSize = 24;

    UPROPERTY(Category ="Content")
    protected TArray<FString> Options;
    default Options.Add("None");
    default Options.Add("Alpha");
    default Options.Add("Bravo");
    default Options.Add("Charlie");

    UPROPERTY(Category ="Content")
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

        if (!IsDesignTime)
        {
            Button.Button.OnClicked.AddUFunction(this, n"OnClick");
        }
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
    int GetSelectedIndex() const
    {
        return Options.FindIndex(SelectedOption);
    }
}

class UFishToggle : UFishWidgetComponent
{
    UPROPERTY(Category ="Content")
    protected FText Text = FText::FromString("Toggle");

    UPROPERTY(Category ="Content")
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
}

class UFishComboBox : UFishWidgetComponent
{
    UPROPERTY(Category ="Content")
    protected TArray<FString> Options;

    UPROPERTY(Category ="Content")
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
        
        ComboBox.SetSelectedOption(Options.Num() > 0 ? Options[0] : "No Options");
    }
}

class UFishEditableText : UFishWidgetComponent
{
    UPROPERTY(Category ="Content")
    protected FText Text;

    UPROPERTY(Category ="Content")
    protected FText HintText = FText::FromString("Search...");

    UPROPERTY(Category ="Content")
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
}