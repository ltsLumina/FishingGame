// @ltslumina on GitHub


#include "FloatingActor.h"
#include "Components/BillboardComponent.h"
#include "Components/SceneComponent.h"

// Sets default values
AFloatingActor::AFloatingActor()
{
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	
	RootSceneComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(RootSceneComponent);
	
	BillboardComponent = CreateDefaultSubobject<UBillboardComponent>(TEXT("Billboard"));
	BillboardComponent->SetupAttachment(RootComponent);
	
	StaticMeshComponent = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Static Mesh"));
	StaticMeshComponent->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void AFloatingActor::BeginPlay()
{
	Super::BeginPlay();
}

// Called every frame
void AFloatingActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

void AFloatingActor::AdvancedDisplay(int32 Integer, float AdvancedVariable)
{
}

FString AFloatingActor::WithoutCompactTitle(bool InBool)
{
	return "Hello World";
}

FString AFloatingActor::WithCompactTitle(bool InBool)
{
	return "Hello World";
}

void AFloatingActor::FunctionDisplayName()
{
}

bool AFloatingActor::TryPetDog(const FName Name)
{
	return true;
}

bool AFloatingActor::IsValidStaticMesh() const
{
	return true;
}

void AFloatingActor::SwitchAnimalByName(FString Name, EAnimalType& Animal)
{
}

bool AFloatingActor::ExpandBoolAsExecsFunction()
{
	return true;
}

void AFloatingActor::IsAboveFreezing(float Temperature, bool& bFreezing)
{
	
}

bool AFloatingActor::NativeEvent_Implementation()
{
	return true;
}




