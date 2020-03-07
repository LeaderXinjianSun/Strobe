'D43D42
'20190926
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
			  	Pallet 1, TrayA1_Z1, TrayA5_Z1, TrayA1_Z1, 5, 1
			  	Pallet 2, TrayA1_Z2, TrayA5_Z2, TrayA1_Z2, 5, 1
			  	Pallet 3, TrayA1_Z3, TrayA5_Z3, TrayA1_Z3, 5, 1
			  	
			  	Pallet 4, TrayB1_F1, TrayB5_F1, TrayB1_F1, 5, 1
				Pallet 5, TrayB1_F2, TrayB5_F2, TrayB1_F2, 5, 1
				Pallet 6, TrayB1_F3, TrayB5_F3, TrayB1_F3, 5, 1

				If AIndex > 15 Then
					StepCount = 3
				Else
					StepCount = 2
				EndIf
			Case 2 '吸嘴A吸取
				On LeftCylinder
				Off LeftBlow1
				On LeftSuck1
				If AIndex <= 5 Then
					Go Pallet(1, AIndex) +Z(10)
				ElseIf AIndex <= 10 Then
					Go Pallet(2, AIndex - 5) +Z(10)
				Else
					Go Pallet(3, AIndex - 10) +Z(10)
				EndIf
				Go Here +Z(-10)
				Wait 0.5
				Go Here +Z(5)
mainlabel1:
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
				If BIndex > 15 Then
					StepCount = 5
				Else
					StepCount = 4
				EndIf
			Case 4 '吸嘴B吸取
				On RightCylinder
				Off RightBlow1
				On RightSuck1
				If BIndex <= 5 Then
					Go Pallet(4, BIndex) +Z(10)
				ElseIf BIndex <= 10 Then
					Go Pallet(5, BIndex - 5) +Z(10)
				Else
					Go Pallet(6, BIndex - 10) +Z(10)
				EndIf
				Go Here +Z(-10)
				Wait 0.5
				Go Here +Z(5)
mainlabel2:
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
				If AIndex > 15 And BIndex > 15 Then
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
				'Go HomePoint
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
	Pallet 10, P300, P301, P302, 2, 3
	Pallet 11, P303, P304, P305, 2, 3
	Integer Suckfailtimes
	Integer ii
	Suckfailtimes = 0
	Boolean A_Have, B_Have
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





