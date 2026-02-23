#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "ProjectFunctionLibrary.generated.h"

UENUM()
enum EVersionUpgrade
{
	Patch,
	Minor,
	Major,
};

UCLASS()
class FISHINGGAME_API UProjectFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, BlueprintPure, Category="Project")
	static FString GetGameVersion();
	
	UFUNCTION(ScriptCallable, Category="Project")
	static void SetGameVersion(const FString& NewVersion);
	
	UFUNCTION(ScriptCallable, Category = "Project")
	static void UpgradeVersion(EVersionUpgrade VersionUpgrade);
};
