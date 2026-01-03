// @ltslumina on GitHub
#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"

#include "DEPRECATED_UTitles.generated.h"

// USTRUCT(BlueprintType)
// struct FTitleEntry
// {
// 	GENERATED_BODY()
// 	
// 	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Title Entry")
// 	FText TitleName;
// 		
// 	UPROPERTY(EditAnywhere, meta=(FunctionReference, PrototypeFunction="/Script/FishingGame.Titles.UnlockConditionSignature", DefaultBindingName="Unlock Condition"))
// 	FMemberReference UnlockCondition;
// };

/**
 * 
 */
UCLASS(NotBlueprintable, NotBlueprintType, Deprecated)
class FISHINGGAME_API UDEPRECATED_UTitles : public UPrimaryDataAsset
{
	GENERATED_BODY()
	
public:
	// UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Titles")
	// TArray<FTitleEntry> Titles;
	//
	// UFUNCTION(BlueprintCallable, DisplayName="Unlock Condition")
	// bool UnlockConditionSignature();
	//
	// UFUNCTION(meta=(DeprecatedFunction, DeprecationMessage="This is only here for example/archival purposes."))
	// void ExampleCall();
};