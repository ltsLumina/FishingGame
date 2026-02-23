/**
 * Compares two UObject references for equality.
 * @param Result Optional output parameter that will contain the result of the comparison.
 * @return True if both references point to the same object, false otherwise.
 */
UFUNCTION(Meta = (ExpandBoolAsExecs = "ReturnValue", CompactNodeTitle = "=="))
bool Equals(UObject A, UObject B, bool&out Result)
{
	Result = A == B;
	return A == B;
}


UFUNCTION(BlueprintPure, Category = "Math", Meta = (CompactNodeTitle = "Round", Keywords = "round,decimal,places"))
float RoundTo(float Value, int DecimalPlaces)
{
	float Multiplier = Math::Pow(10.0f, DecimalPlaces);
	return Math::RoundToFloat(Value * Multiplier) / Multiplier;
}

/**
 * Whether the game is currently running in the editor.
 */
UFUNCTION(BlueprintPure, Category = "Editor", Meta = (CompactNodeTitle = "Editor", Keywords = "editor,pc,platform"))
bool IsEditor()
{
#if EDITOR
	return true;
#else
	return false;
#endif
}

UFUNCTION(Category = "Editor", Meta = (ExpandBoolAsExecs = "ReturnValue", Keywords = "editor,pc,platform"), DisplayName = "Is Editor")
bool IsEditor_Expanded()
{
#if EDITOR
	return true;
#else
	return false;
#endif
}

namespace Array
{
	const int INDEX_NONE = -1;
}

UFUNCTION(DisplayName = "Is A (soft)", Meta = (ExpandBoolAsExecs = "ReturnValue", WorldContext = "Object"))
mixin bool IsASoft_Branch(UObject Object, TSoftClassPtr<UObject> SoftClass)
{
	return Object.IsA(SoftClass.Get());
}

UFUNCTION(BlueprintPure, DisplayName = "Is A (soft)", Meta = (WorldContext = "Object"))
mixin bool IsASoft(UObject Object, TSoftClassPtr<UObject> SoftClass)
{
	return Object.IsA(SoftClass.Get());
}

namespace EditorAsset
{
#if EDITOR
	UObject GetEditorAsset(FString Path)
	{
		return LoadObject(nullptr, Path);
	}
#endif
}

namespace ProjectSettings
{
	UFUNCTION(BlueprintPure, Category = "Project Settings")
	UGeneralProjectSettings GetGeneralProjectSettings()
	{
		return UGeneralProjectSettings.GetDefaultObject();
	}
}

namespace Widget
{
	/**
	 * Returns the outermost userwidget of this widget.
	 */
	UFUNCTION(BlueprintPure, DisplayName = "Get Root Widget")
	UWidget BP_GetRootWidget(UUserWidget Widget)
	{
		return Cast<UWidget>(Widget.GetOuter().GetOuter());
	}
}

namespace Asserts
{
	/**
	 * Throw's a blueprint exception.
	 */
	UFUNCTION(Category = "Asserts", Meta = (CompactNodeTitle = "throw"))
	void Throw(FString Message)
	{
		Print(f"Blueprint Exception: {Message}\n{Exception::GetFormattedCallStack()}", 8.0f, FLinearColor::Red);
	}
}