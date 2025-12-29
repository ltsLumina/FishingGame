// @ltslumina on GitHub

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "FloatingActor.generated.h"

class USceneComponent;
class UBillboardComponent;
class UStaticMeshComponent;

UENUM()
enum class EAnimalType : uint8
{
	Cat,
	Dog,
	Rooster
};

UCLASS()
class FISHINGGAME_API AFloatingActor : public AActor
{
	GENERATED_BODY()

public:
	// Sets default values for this actor's properties
	AFloatingActor();
	
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Floating Actor")
	float Speed = 20.0f;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;
	
	UFUNCTION(BlueprintCallable, meta=(AdvancedDisplay="AdvancedVariable"))
	void AdvancedDisplay(int32 Integer, float AdvancedVariable);
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	FString WithoutCompactTitle(bool InBool);

	UFUNCTION(BlueprintCallable, BlueprintPure, meta=(CompactNodeTitle = ":)"))
	FString WithCompactTitle(bool InBool);
	
	UFUNCTION(BlueprintCallable, meta=(DisplayName="abc"))
	void FunctionDisplayName();
	
	UFUNCTION(BlueprintCallable, meta=(ReturnDisplayName = "Success"))
	bool TryPetDog(const FName Name);
	
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent)
	void ImplementableEvent();
	
	UFUNCTION(BlueprintCallable, BlueprintNativeEvent)
	bool NativeEvent();

	UFUNCTION(BlueprintCallable, BlueprintPure)
	bool IsValidStaticMesh() const;

	UFUNCTION(BlueprintCallable, meta=(ExpandEnumAsExecs="Animal"))
	void SwitchAnimalByName(FString Name, EAnimalType& Animal);
	
	UFUNCTION(BlueprintCallable, meta=(ExpandBoolAsExecs="ReturnValue"))
	bool ExpandBoolAsExecsFunction();
	
	UFUNCTION(BlueprintCallable, meta=(ExpandBoolAsExecs="bFreezing"))
	void IsAboveFreezing(float Temperature, bool& bFreezing);
	
	

protected:
	
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
	USceneComponent* RootSceneComponent;
	
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
	UBillboardComponent* BillboardComponent;
	
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
	UStaticMeshComponent* StaticMeshComponent;
};
