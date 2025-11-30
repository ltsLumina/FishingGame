#pragma once

#include "CoreMinimal.h"

#include "ProjectVersionGetter.generated.h"

UCLASS()
class FISHINGGAME_API UProjectVersionGetter : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintPure, Category="Project")
	static FString GetGameVersion();
};
