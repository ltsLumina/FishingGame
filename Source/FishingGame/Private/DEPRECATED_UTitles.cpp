// @ltslumina on GitHub

#include "DEPRECATED_UTitles.h"

// bool UTitles::UnlockConditionSignature()
// {
// 	return true;
// }
//
// void UTitles::ExampleCall()
// {
// 	auto Title = Titles[0];
// 	
// 	if (UFunction* Func = Title.UnlockCondition.ResolveMember<UFunction>(GetClass()))
// 	{
// 		const int32 TheDiceValueWeWantToUse = FMath::RandRange(1, 6);
// 			
// 		// ProcessEvent deals with raw memory, so let's set up some memory to be used
// 		// This is just an anonymous struct, the syntax looks kind of funky though
// 		struct {
// 			int32 DiceValue;
// 			bool bResult;
// 		} Args = { TheDiceValueWeWantToUse, false };
//
// 		// This will collect our results
// 		FStructOnScope FuncParam(Func);
// 		
// 		// Call our function with our parameters
// 		this->ProcessEvent(Func, &Args);
// 		const FString TrueFalse = Args.bResult ? "True" : "False";
// 		UE_LOG(LogTemp, Display, TEXT("Called function '%s' with '%d' was '%s'"), *Func->GetDisplayNameText().ToString(), TheDiceValueWeWantToUse, *TrueFalse);
// 	}
// }