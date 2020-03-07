'N104
'20190925
Function main
	Integer StepCount
	Integer AIndex, BIndex
	Integer NowSpace
	Integer PickFailCount
	Boolean Ahave, Bhave


	Trap Emergency Xqt EmgAction
	Motor Off
	Motor On
	Power High
	Speed 50
	Accel 50, 50
	OutW 0, 0
	Out 65, 0
	Out 66, 0
	Jump HomePoint
	NowSpace = 0
	PickFailCount = 0 '0:Home/1:Pick/2:Release
	
	AIndex = 1
	BIndex = 1
	Ahave = False
	Bhave = False
	StepCount = 0
	Do
		Select StepCount
			Case 0 '取料或样本选择
				On SafePlace
				Wait Sw(RawTrayReady) = 1 Or Sw(SampleMode) = 1 Or Sw(ExitSingle) = 1
				If Sw(ExitSingle) = 1 Then '正在排料
					Wait Sw(ExitSingle) = 0
				ElseIf Sw(SampleMode) = 1 Then '样本模式
					Print "开始样本取料"
					Call SampleTest
					On 524
			  	    Print "等待样本测试结束"
			  	    Wait Sw(SampleMode) = 0
			  	    Off 524
			  	    Wait 10
				Else
					StepCount = 1
					Off SafePlace
				EndIf
			Case 1
				If NowSpace <> 1 Then
					NowSpace = 1
					Pass Traygobyoutz
				EndIf
				Pallet 1, TrayA1_Z, TrayA16_Z, TrayA1_Z, 16, 1
				Pallet 2, TrayA1_F, TrayA16_F, TrayA1_F, 16, 1
				Pallet 3, TrayB1_Z, TrayB16_Z, TrayB1_Z, 16, 1
				Pallet 4, TrayB1_F, TrayB16_F, TrayB1_F, 16, 1
				If AIndex > 32 Then
					StepCount = 3
				Else
					StepCount = 2
				EndIf
			Case 2 '吸嘴A吸取
				On LeftCylinder
				Off LeftBlow1
				On LeftSuck1
				If AIndex <= 16 Then
					Go Pallet(1, AIndex) +Z(10)
				Else
					Go Pallet(2, AIndex - 16) +Z(10)
				EndIf
				Go Here +Z(-10)
				Wait 0.5
				Go Here +Z(5)
mainlabel1:
				Wait 1
				If Sw(LeftSensor1) = 0 Then
					If PickFailCount < 2 Then
						PickFailCount = PickFailCount + 1
						Go Here +Z(-5)
						Wait 0.5
						Go Here +Z(5)
						GoTo mainlabel1
					Else
						PickFailCount = 0
						AIndex = AIndex + 1
						Off LeftCylinder
						Off LeftSuck1
						Wait 0.5
						StepCount = 1
					EndIf
				Else
					Ahave = True
					PickFailCount = 0
					AIndex = AIndex + 1
					Off LeftCylinder
					Wait 0.5
					StepCount = 3
				EndIf
			Case 3
				If BIndex > 32 Then
					StepCount = 5
				Else
					StepCount = 4
				EndIf
			Case 4 '吸嘴B吸取
				On RightCylinder
				Off RightBlow1
				On RightSuck1
				If BIndex <= 16 Then
					Go Pallet(3, BIndex) +Z(10)
				Else
					Go Pallet(4, BIndex - 16) +Z(10)
				EndIf
				Go Here +Z(-10)
				Wait 0.5
				Go Here +Z(5)
mainlabel2:
				Wait 1
				If Sw(RightSensor1) = 0 Then
					If PickFailCount < 2 Then
						PickFailCount = PickFailCount + 1
						Go Here +Z(-5)
						Wait 0.5
						Go Here +Z(5)
						GoTo mainlabel2
					Else
						PickFailCount = 0
						BIndex = BIndex + 1
						Off RightCylinder
						Off RightSuck1
						Wait 0.5
						StepCount = 3
					EndIf
				Else
					Bhave = True
					PickFailCount = 0
					BIndex = BIndex + 1
					Off RightCylinder
					Wait 0.5
					StepCount = 5
				EndIf
			Case 5 '返回初始位置
				Pass Traygobyoutf
				Go WaitReleasePointZ
				NowSpace = 0
				On SafePlace
				If AIndex > 32 And BIndex > 32 Then
					AIndex = 1
					BIndex = 1
					On RawTrayOver
					Print "等待空盘被取"
					Wait Sw(RawTrayReady) = 0
					Off RawTrayOver
				EndIf
				If (Ahave And Sw(LeftSensor1) = 0) Or (Bhave And Sw(RightSensor1) = 0) Then
					Off SafePlace
					If Ahave And Sw(LeftSensor1) = 0 Then
						On 526
					EndIf
					If Bhave And Sw(RightSensor1) = 0 Then
						On 527
					EndIf
					Go FakePoint
				EndIf
				If Ahave And Sw(LeftSensor1) = 0 Then
					Off LeftSuck1
					On LeftBlow1
					Wait 0.2
					Off LeftBlow1
					Ahave = False
				EndIf
				If Bhave And Sw(RightSensor1) = 0 Then
					Off RightSuck1
					On RightBlow1
					Wait 0.2
					Off RightBlow1
					Bhave = False
				EndIf
				Go WaitReleasePointZ
				Off 526
				Off 527
				If Not Ahave And Not Bhave Then
					StepCount = 0
				Else
					On SafePlace
					StepCount = 6
				EndIf
			Case 6
				Wait Sw(AdjustTrayReady) = 1
				Go AdjustReleasePoint
				On LeftCylinder
				On RightCylinder
				Wait 0.5
				Off LeftSuck1
				Off RightSuck1
				On LeftBlow1
				On RightBlow1
				Wait 0.2
				Off LeftBlow1
				Off RightBlow1
				If Ahave Then
					On 520
				EndIf
				If Bhave Then
					On 521
				EndIf
				Off LeftCylinder
				Off RightCylinder
				Wait 0.5
				Go WaitReleasePointZ
				On AdjustTrayDone
				Wait Sw(AdjustTrayReady) = 0
				Off 520
				Off 521
				Off AdjustTrayDone
				Ahave = False
				Bhave = False
				StepCount = 0
			Default
				Wait 0.1
		Send
	Loop
	
Fend
Function SampleTest
	Pallet 10, P300, P301, P302, 1, 5
	Pallet 11, P303, P304, P305, 1, 5
	Integer Suckfailtimes
	Integer ii
	Boolean A_Have, B_Have
	Suckfailtimes = 0
	For ii = 1 To 5
SampleLabel1:
		Go Pallet(10, ii)
		On LeftCylinder
		Off LeftBlow1
		On LeftSuck1
		Wait 0.8
		Off LeftCylinder
		Wait 0.8
		If Sw(LeftSensor1) = 0 Then
			Suckfailtimes = Suckfailtimes + 1
			If Suckfailtimes < 3 Then
				GoTo SampleLabel1
			Else
				Go HomePoint
				Off LeftSuck1
'				Print "样本吸取失败"
'				On 523
'				Wait Sw(512) = 1
'				Off 523
				Suckfailtimes = 0
'				GoTo SampleLabel1
				A_Have = False
			EndIf
		Else
			Suckfailtimes = 0
			A_Have = True
		EndIf
		
SampleLabel2:
		Go Pallet(11, ii)
		On RightCylinder
		Off RightBlow1
		On RightSuck1
		Wait 0.8
		Off RightCylinder
		Wait 0.8
		If Sw(RightSensor1) = 0 Then
			Suckfailtimes = Suckfailtimes + 1
			If Suckfailtimes < 3 Then
				GoTo SampleLabel2
			Else
				Go HomePoint
				Off RightSuck1
'				Print "样本吸取失败"
'				On 523
'				Wait Sw(512) = 1
'				Off 523
				Suckfailtimes = 0
'				GoTo SampleLabel2
				B_Have = False
			EndIf
		Else
			Suckfailtimes = 0
			B_Have = True
		EndIf
		
		If A_Have Or B_Have Then
			
			Go WaitReleasePointZ
			Wait Sw(AdjustTrayReady) = 1
			Go AdjustReleasePoint
			On LeftCylinder
			On RightCylinder
			Wait 0.5
			Off LeftSuck1
			Off RightSuck1
			On LeftBlow1
			On RightBlow1
			Wait 0.2
			Off LeftBlow1
			Off RightBlow1
				If A_Have Then
					On 520
				EndIf
				If B_Have Then
					On 521
				EndIf
			Off LeftCylinder
			Off RightCylinder
			Wait 0.5
			Go WaitReleasePointZ
			On AdjustTrayDone
			Wait Sw(AdjustTrayReady) = 0
			Off 520
			Off 521
			Off AdjustTrayDone
		EndIf
		
		
	Next
	Go HomePoint
Fend
Function EmgAction
	OutW 0, 0, Forced
	Out 65, 0, Forced
	Out 66, 0, Forced
Fend




