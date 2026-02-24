class UMinigameWidget : UFishWidget
{
	UPROPERTY(BindWidget)
	UImage Background;

	UPROPERTY(BindWidget)
	UImage FishImg;

	UPROPERTY(BindWidget)
	UProgressBar FishHealthBar;

	UPROPERTY(BindWidget)
	UProgressBar PlayerHealthBar;

	UPROPERTY(VisibleAnywhere)
	FMinigameData Data;

	UPROPERTY(VisibleAnywhere)
	TArray<FVector2D> Points;

	UPROPERTY(BlueprintReadOnly)
	UMinigameComponent MinigameComponent;

	FVector2D TargetPos;
	float InterpSpeed;

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		Widget::DrawLines(Context, Points, FLinearColor::LucBlue, true, 10.0f);
	}

	float MaxHP;
	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, AFishController InController) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InController);

		MinigameComponent = UMinigameComponent::Get(InController);

		TargetPos = GetRandomPos();

		MaxHP = MinigameComponent.FishHealth;

		InterpSpeed = Data.FishItem.FishData.Behaviour.InterpSpeed;

		Data.FishItem.FishData.Behaviour.Execute();
	}

	FVector2D GetRandomPos()
	{
		auto Size = GetDesiredSize().X / 2;
		return FVector2D(Math::RandRange(-Size, Size), Math::RandRange(-Size, Size));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Super::Tick(MyGeometry, InDeltaTime);

		FishHealthBar.SetPercent(Math::NormalizeToRange(MinigameComponent.FishHealth, 0, MaxHP));
		PlayerHealthBar.SetPercent(Math::NormalizeToRange(MinigameComponent.PlayerHealth, 0, 3));

		Move(InDeltaTime);

		bool IsDrawing = GetFishControllerBase().IsDrawing;
		if (!IsDrawing)
		{
			ClearLine();
			return;
		}

		float32 MouseX = 0;
		float32 MouseY = 0;
		Gameplay::GetPlayerController(0).GetMousePosition(MouseX, MouseY);
		FVector2D ScreenPos = FVector2D(MouseX, MouseY);

		FVector2D Point;
		Slate::ScreenToWidgetLocal(MyGeometry, ScreenPos, Point);
		if (!Line::IsPointTouchingImage(Point, FishImg, MyGeometry) && !Line::IsLineTouchingImage(Points, FishImg, MyGeometry))
		{
			Points.Add(Point);

			if (Line::IsPointTouchingImage(Point, Background, MyGeometry))
			{
				MinigameComponent.HasDamageImmunity = false;

				FVector2D IntersectPoint;
				if (Line::DoesPolylineSelfIntersect(Points, IntersectPoint))
				{
					if (Line::IsImageInLasso(Points, FishImg, MyGeometry))
					{
						ClearLine();
						MinigameComponent.DealDamage(1);
					}
				}
			}
			else
			{
				ClearLine();
			}
		}
		else
		{
			TakeDamage(1);
		}
	}

	void Move(float DeltaSeconds)
	{
		auto PanelSlot = Cast<UCanvasPanelSlot>(FishImg.Slot);
		FVector2D Pos = PanelSlot.GetPosition();

		FVector2D Result = Math::Vector2DInterpConstantTo(Pos, TargetPos, DeltaSeconds, InterpSpeed);
		PanelSlot.SetPosition(Result);

		if (Pos.Equals(TargetPos, 25.0f))
		{
			TargetPos = GetRandomPos();
		}
	}

	UFUNCTION()
	void TakeDamage(int Damage = 1)
	{
		ClearLine();

		MinigameComponent.TakeDamage(Damage);
	}

	UFUNCTION()
	void ClearLine()
	{
		Points.Empty();
	}
}

namespace Line
{
	float Orientation(const FVector2D& A, const FVector2D& B, const FVector2D& C)
	{
		return (B.X - A.X) * (C.Y - A.Y) -
			   (B.Y - A.Y) * (C.X - A.X);
	}

	bool OnSegment(const FVector2D& A, const FVector2D& B, const FVector2D& P)
	{
		return P.X >= Math::Min(A.X, B.X) &&
			   P.X <= Math::Max(A.X, B.X) &&
			   P.Y >= Math::Min(A.Y, B.Y) &&
			   P.Y <= Math::Max(A.Y, B.Y);
	}

	bool PointsEqual(const FVector2D& A, const FVector2D& B)
	{
		return A.Equals(B, KINDA_SMALL_NUMBER);
	}

	bool DoSegmentsIntersect(
		const FVector2D& A, const FVector2D& B, const FVector2D& C, const FVector2D& D)
	{
		float O1 = Orientation(A, B, C);
		float O2 = Orientation(A, B, D);
		float O3 = Orientation(C, D, A);
		float O4 = Orientation(C, D, B);

		// General proper intersection (crossing)
		if (O1 * O2 < 0.f && O3 * O4 < 0.f)
			return true;

		// Ignore pure endpoint touching
		if (PointsEqual(A, C) || PointsEqual(A, D) ||
			PointsEqual(B, C) || PointsEqual(B, D))
		{
			return false;
		}

		// Collinear overlapping (but not just touching endpoints)
		if (Math::IsNearlyZero(O1) && OnSegment(A, B, C))
			return true;
		if (Math::IsNearlyZero(O2) && OnSegment(A, B, D))
			return true;
		if (Math::IsNearlyZero(O3) && OnSegment(C, D, A))
			return true;
		if (Math::IsNearlyZero(O4) && OnSegment(C, D, B))
			return true;

		return false;
	}

	// Standard line-line intersection formula
	bool GetIntersectionPoint(
		const FVector2D& A, const FVector2D& B, const FVector2D& C, const FVector2D& D, FVector2D& OutPoint)
	{
		float Det = (B.X - A.X) * (D.Y - C.Y) - (B.Y - A.Y) * (D.X - C.X);
		if (Math::IsNearlyZero(Det))
			return false;

		float T = ((C.X - A.X) * (D.Y - C.Y) - (C.Y - A.Y) * (D.X - C.X)) / Det;
		float U = ((C.X - A.X) * (B.Y - A.Y) - (C.Y - A.Y) * (B.X - A.X)) / Det;

		// Check if intersection is strictly within segments
		if (T >= 0.f && T <= 1.f && U >= 0.f && U <= 1.f)
		{
			OutPoint = A + (B - A) * T;
			return true;
		}
		return false;
	}

	// Simple intersection check
	bool Intersect(const FVector2D& A, const FVector2D& B, const FVector2D& C, const FVector2D& D, FVector2D& Out)
	{
		float Det = (B.X - A.X) * (D.Y - C.Y) - (B.Y - A.Y) * (D.X - C.X);
		if (Math::IsNearlyZero(Det))
			return false;
		float T = ((C.X - A.X) * (D.Y - C.Y) - (C.Y - A.Y) * (D.X - C.X)) / Det;
		float U = ((C.X - A.X) * (B.Y - A.Y) - (C.Y - A.Y) * (B.X - A.X)) / Det;
		if (T >= 0.f && T <= 1.f && U >= 0.f && U <= 1.f)
		{
			Out = A + (B - A) * T;
			return true;
		}
		return false;
	}

	TArray<FVector2D> Normalize(const TArray<FVector2D>& Points)
	{
		if (Points.Num() == 0)
			return Points;

		FVector2D Min = Points[0], Max = Points[0];
		for (const FVector2D& P : Points)
		{
			Min.X = Math::Min(Min.X, P.X);
			Min.Y = Math::Min(Min.Y, P.Y);
			Max.X = Math::Max(Max.X, P.X);
			Max.Y = Math::Max(Max.Y, P.Y);
		}

		FVector2D Size = Max - Min;
		float Scale = Math::Max(Size.X, Size.Y);
		if (Scale < 1.f)
			Scale = 1.f;

		TArray<FVector2D> Normalized;
		for (const FVector2D& P : Points)
		{
			Normalized.Add((P - Min) / Scale);
		}
		return Normalized;
	}

	bool DoesPolylineSelfIntersect(const TArray<FVector2D>& Points, FVector2D&out OutIntersectionPoint)
	{
		const int32 NumPoints = Points.Num();
		if (NumPoints < 4)
			return false;

		const int32 SegmentCount = NumPoints - 1;

		for (int32 i = 0; i < SegmentCount; ++i)
		{
			const FVector2D& A1 = Points[i];
			const FVector2D& A2 = Points[i + 1];

			for (int32 j = i + 2; j < SegmentCount; ++j)
			{
				// Skip adjacent segments
				if (j == i + 1)
					continue;

				const FVector2D& B1 = Points[j];
				const FVector2D& B2 = Points[j + 1];

				if (Line::GetIntersectionPoint(A1, A2, B1, B2, OutIntersectionPoint))
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsPointInPolygon(const FVector2D& Point, const TArray<FVector2D>& Polygon)
	{
		bool bInside = false;
		const int32 Count = Polygon.Num();

		for (int32 i = 0, j = Count - 1; i < Count; ++i)
		{
			const FVector2D& A = Polygon[i];
			const FVector2D& B = Polygon[j];

			if (((A.Y > Point.Y) != (B.Y > Point.Y)) &&
				(Point.X < (B.X - A.X) * (Point.Y - A.Y) /
								   (B.Y - A.Y + KINDA_SMALL_NUMBER) +
							   A.X))
			{
				bInside = !bInside;
			}

			j = i;
		}

		return bInside;
	}

	UFUNCTION(BlueprintPure)
	bool GetLassoPolygon(const TArray<FVector2D>& Points, TArray<FVector2D>& OutPolygon)
	{
		const int32 Num = Points.Num();
		if (Num < 4)
			return false;

		// Iterate backwards to find the LATEST self-intersection (the loop just closed)
		// We compare the very last segment (Num-2 to Num-1) against all previous segments
		const FVector2D& HeadA = Points[Num - 2];
		const FVector2D& HeadB = Points[Num - 1];

		for (int32 i = 0; i < Num - 3; ++i)
		{
			const FVector2D& TailA = Points[i];
			const FVector2D& TailB = Points[i + 1];

			FVector2D HitPoint;
			if (Line::GetIntersectionPoint(HeadA, HeadB, TailA, TailB, HitPoint))
			{
				// Intersection found! Reconstruct the loop.
				// 1. Start with the intersection point
				OutPolygon.Reset();
				OutPolygon.Add(HitPoint);

				// 2. Add all points between the intersection indices (i+1 to Num-2)
				for (int32 k = i + 1; k < Num - 1; ++k)
				{
					OutPolygon.Add(Points[k]);
				}

				// 3. Close the loop back to the intersection (implicit in IsPointInPolygon, but good for debug drawing)
				OutPolygon.Add(HitPoint);
				return true;
			}
		}

		// Fallback: If no intersection, use the whole shape implicitly closed
		OutPolygon = Points;
		return false; // Return false to indicate "No lasso loop found", but OutPoly is populated
	}

	UFUNCTION(BlueprintPure)
	bool IsImageInLasso(const TArray<FVector2D>& DrawnPoints, UWidget TargetImage, const FGeometry& MyGeometry)
	{
		if (!IsValid(TargetImage) || DrawnPoints.Num() < 4)
			return false;

		// 1. Get the geometry
		FGeometry Geo = TargetImage.GetCachedGeometry();

		// 2. Calculate Local Center (Width/2, Height/2)
		FVector2D LocalSize = Geo.GetLocalSize();
		FVector2D LocalCenter = LocalSize * 0.5f;

		// 3. Convert Local Center to Absolute Space manually
		FVector2D AbsoluteCenter = Geo.LocalToAbsolute(LocalCenter);

		FVector2D LocalPoint = MyGeometry.AbsoluteToLocal(AbsoluteCenter);

		// 2. Extract Loop
		const int32 Num = DrawnPoints.Num();
		for (int32 i = 0; i < Num - 3; ++i)
		{
			FVector2D Intersect;
			if (Line::GetIntersectionPoint(DrawnPoints[Num - 2], DrawnPoints[Num - 1], DrawnPoints[i], DrawnPoints[i + 1], Intersect))
			{
				TArray<FVector2D> Loop;
				Loop.Add(Intersect);
				for (int32 k = i + 1; k < Num - 1; ++k)
					Loop.Add(DrawnPoints[k]);

				return IsPointInPolygon(LocalPoint, Loop);
			}
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsLineTouchingImage(const TArray<FVector2D>& DrawnPoints, UWidget Target, const FGeometry& MyGeo)
	{
		if (!IsValid(Target) || DrawnPoints.Num() == 0)
			return false;

		FGeometry TGeo = Target.GetCachedGeometry();
		FVector2D ImageSize = TGeo.GetLocalSize();

		for (const FVector2D& PaintPoint : DrawnPoints)
		{
			// Convert the point you are drawing into the Image's local space
			FVector2D AbsPos = MyGeo.LocalToAbsolute(PaintPoint);
			FVector2D LocalToImage = TGeo.AbsoluteToLocal(AbsPos);

			// If the point is within 0 and Width/Height of the image, it's a touch!
			if (LocalToImage.X >= 0 && LocalToImage.X <= ImageSize.X &&
				LocalToImage.Y >= 0 && LocalToImage.Y <= ImageSize.Y)
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsPointTouchingImage(FVector2D PaintPoint, UWidget Target, FGeometry MyGeo)
	{
		if (!IsValid(Target))
			return false;

		FGeometry TGeo = Target.GetCachedGeometry();
		FVector2D ImageSize = TGeo.GetLocalSize();

		// Convert the point you are drawing into the Image's local space
		FVector2D AbsPos = MyGeo.LocalToAbsolute(PaintPoint);
		FVector2D LocalToImage = TGeo.AbsoluteToLocal(AbsPos);

		// If the point is within 0 and Width/Height of the image, it's a touch!
		if (LocalToImage.X >= 0 && LocalToImage.X <= ImageSize.X &&
			LocalToImage.Y >= 0 && LocalToImage.Y <= ImageSize.Y)
		{
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsMatch(const TArray<FVector2D>& Drawn, const TArray<FVector2D>& Template, float Tolerance = 0.2f)
	{
		if (Drawn.Num() < 2 || Template.Num() < 2)
			return false;

		TArray<FVector2D> NormDrawn = Line::Normalize(Drawn);
		TArray<FVector2D> NormTemp = Line::Normalize(Template);

		float TotalDistance = 0.0f;
		const int32 Samples = 10;

		for (int32 i = 0; i < Samples; ++i)
		{
			// Get point at % of the way through the list
			float DrawnIdx = (i * (NormDrawn.Num() - 1.0f)) / (Samples - 1.0f);
			float TempIdx = (i * (NormTemp.Num() - 1.0f)) / (Samples - 1.0f);

			TotalDistance += NormDrawn[int32(DrawnIdx)].Distance(NormTemp[int32(TempIdx)]);
		}

		// Average error: 0.0 is a perfect match, > 0.5 is very different
		float AverageError = TotalDistance / Samples;
		return AverageError < Tolerance;
	}

	UFUNCTION()
	void SaveVectorArrayToText(TArray<FVector2D> VectorArray, FString FileName)
	{
		FString CombinedString = "";

		for (const FVector2D& Vec : VectorArray)
		{
			// Converts vector to "(X=, Y=, Z=)" format and adds a newline
			CombinedString += Vec.ToString() + "\r\n";
		}

		FString SavePath = f"{FPaths::ProjectSavedDir()}/{FileName}";
		FFileHelper::SaveStringToFile(CombinedString, SavePath);
	}

	UFUNCTION()
	void LoadVectorArrayManual(FString FileName, TArray<FVector2D> &out OutVectorArray)
	{
		FString FullFilePath = f"{FPaths::ProjectSavedDir()}/{FileName}";
		FString FileContent;

		if (FFileHelper::LoadFileToString(FileContent, FullFilePath))
		{
			TArray<FString> Lines;
			// Splits the string at every newline; 'true' ignores empty entries
			FileContent.ParseIntoArray(Lines, "\r\n", true);

			for (const FString& Line : Lines)
			{
				FVector2D LoadedVector;
				if (LoadedVector.InitFromString(Line))
				{
					OutVectorArray.Add(LoadedVector);
				}
			}
		}
	}
}