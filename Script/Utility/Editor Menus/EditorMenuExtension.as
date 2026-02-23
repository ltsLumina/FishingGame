#if EDITOR

/**
 * Other editor menus can be extended with UScriptEditorMenuExtension.
 */
class UProjectEditorMenuExtension : UScriptEditorMenuExtension
{
	// This is the same extension point used by UToolMenus::ExtendMenu
	// In this example, we extend the top menu of the main window:
	default ExtensionPoint = n"LevelEditor.LevelEditorToolBar.User";

	UFUNCTION(CallInEditor, Category = "Utils", Meta = (EditorIcon = "GenericCommands.Paste"))
	void SetVersion(FString Version = "0.0.0")
	{
		Project::SetGameVersion(Version);
		LogInfo(f"[VERSION CHANGED] - New Version: {Version}");
	}

	UFUNCTION(CallInEditor, Category = "Utils", Meta = (EditorIcon = "Icons.Plus"))
	void UpgradeGame(EVersionUpgrade Type)
	{
		Project::UpgradeVersion(Type);
		LogInfo(f"[GAME UPGRADED] - New Version: {Project::GameVersion}");
	}

    //UFUNCTION(CallInEditor, DisplayName = "Extension", Meta = (EditorIcon = "Icons.Plus", EditorButtonStyle = "CalloutToolbar"))
};


#endif