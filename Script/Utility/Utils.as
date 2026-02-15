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

namespace Array
{
	const int INDEX_NONE = -1;
}

UFUNCTION(DisplayName="Is A (soft)", Meta=(ExpandBoolAsExecs="ReturnValue", WorldContext="Object"))
mixin bool IsASoft_Branch(UObject Object, TSoftClassPtr<UObject> SoftClass)
{
	return Object.IsA(SoftClass.Get());
}

UFUNCTION(BlueprintPure, DisplayName="Is A (soft)", Meta=(WorldContext="Object"))
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
	UFUNCTION(BlueprintPure, Category="Project Settings")
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
	UFUNCTION(Category = "Asserts", Meta=(CompactNodeTitle="throw"))
	void Throw(FString Message)
	{
		Print(f"Blueprint Exception: {Message}\n{Exception::GetFormattedCallStack()}", 8.0f, FLinearColor::Red);
	}
}