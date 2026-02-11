UFUNCTION(Category = "Utility")
mixin void BillboardToCamera(USceneComponent TargetComponent)
{
    if (TargetComponent == nullptr)
        return;

    auto PlayerCamera = Gameplay::GetPlayerCameraManager(0);
    if (PlayerCamera == nullptr)
        return;

    FRotator LookAtRotation = Math::FindLookAtRotation(TargetComponent.GetWorldLocation(), PlayerCamera.GetCameraLocation());
    TargetComponent.SetWorldRotation(LookAtRotation);
}

namespace Math
{
    /**
     * Isn't bound in c++ so here's an Angelscript version
     */
    FRotator FindLookAtRotation(FVector Start, FVector Target)
    {
        FVector Direction = (Target - Start).GetSafeNormal();
        FRotator LookAtRotation = Direction.Rotation();
        return LookAtRotation;
    }
}