class UFishWidgetComponent : UFishWidget
{
    default MuteWarnings = true;

    UPROPERTY(Category = "Widget | Customization", EditDefaultsOnly, BlueprintReadOnly)
    USoundBase ClickSound;

    protected void BindClickSound(UFishButton InButton)
    {
        InButton.Button.OnClicked.AddUFunction(this, n"PlayClickSound");
    }

    UFUNCTION(NotBlueprintCallable)
    private void PlayClickSound()
    {
        if (ClickSound != nullptr)
        {
            Gameplay::PlaySound2D(ClickSound, 1, Math::RandRange(1, 1.05f));
        }
    }
}