comment "
A3_ZeusHelmetCamViewer

Arma 3 Steam Workshop
https://steamcommunity.com/sharedfiles/filedetails/?id=3045798946

MIT License
Copyright (c) 2023 M9-SD
https://github.com/M9-SD/A3_ZeusHelmetCamViewer/tree/main/LICENSE
";

comment "Determine if execution context is composition and delete the helipad.";

if ((!isNull (findDisplay 312)) && (!isNil 'this')) then {
	if (!isNull this) then {
		if (typeOf this == 'Land_HelipadEmpty_F') then {
			deleteVehicle this;
		};
	};
};

M9SD_fnc_zeusHelmetCamViewerModule_comp = {
	waitUntil {isNull findDisplay 49};;
	comment "Define some stuff";
	comment "Define Picture-in-Picture (PiP) RTT (or R2T, Render to Texture) source";
	M9_rttStr_zHcamPIP = "M9_rtt_zHcamPIP";
	uiNamespace setVariable ['M9_rttStr_zHcamPIP', M9_rttStr_zHcamPIP];
	M9_rttStr_zHcamPIPTextureStr = format ["#(argb,512,512,1)r2t(%1,1.0)", M9_rttStr_zHcamPIP];
	uiNamespace setVariable ['M9_rttStr_zHcamPIPTextureStr', M9_rttStr_zHcamPIPTextureStr];
	M9_zHCAM_unit = player;
	uiNamespace setVariable ['M9_zHCAM_unit', M9_zHCAM_unit];
	M9_zHcam_spawnPos = getPosATL M9_zHCAM_unit;
	uiNamespace setVariable ['M9_zHcam_spawnPos', M9_zHcam_spawnPos];
	comment "
	M9_zHcam_offset = [0.2625, -0.245, 0.155];

	M9_zHcam_offset = [0.18, -0.17, 0.18];

	M9_zHcam_offset = [0.22125, -0.2075, 0.1675];
	";
	M9_zHcam_offset = [0.19, -0.13, 0.1675];
	comment "check if zeus is open";
	if (isNull (findDisplay 312)) exitWith {systemChat 'need zeus interface'};
	comment "check if pip enabled";
	if (!isPiPEnabled) exitWith {systemChat 'PiP is not enabled in video options'};
	M9SD_fnc_zHCam_initCamera = {

		comment "Create the camera";

		if (isNil 'M9_zHcam_cameraObj') then {
			M9_zHcam_cameraObj = "camera" camCreate M9_zHcam_spawnPos;
		} else {
			if (!isNull M9_zHcam_cameraObj) then {
				if (!isNil 'M9_rttStr_zHcamPIP') then {
					M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
				};
				camDestroy M9_zHcam_cameraObj;
			};
		};
		M9_zHcam_cameraObj = "camera" camCreate M9_zHcam_spawnPos;
		comment "
		M9_zHcam_cameraObj camCommand 'manual off';
		";
		comment "adjust cam for realistic bodycam";
		M9_zHcam_cameraObj attachTo [uiNamespace getVariable 'M9_zHCAM_unit', M9_zHcam_offset, "head", true]; 
		comment "[M9_zHcam_cameraObj, [0,0,0]] call BIS_fnc_setObjectRotation;"; 
		comment "Apply camera's Field of View";
		'1.2';'1.15';

		M9_zHcam_cameraObj camsetFOV 1.21; comment " standard FOV is 0.7; lesser (e.g 0.5) is zoomed in, greater (e.g 0.9) is zoomed out";
		M9_zHcam_cameraObj camCommit 0; comment " 0 for immediate change, value in seconds for transition";
		comment "switchCamera _camera; ";
		cameraEffectEnableHUD true;
		private _zeusLogic = getAssignedCuratorLogic player;
		player remoteControl _zeusLogic;
		_zeusLogic spawn 
		{
			waitUntil {sleep 0.01; isNull (findDisplay 312)};
			objnull remoteControl _this;
		};
		comment "Enter the camera (+ create a PiP source)";
		comment "M9_zHcam_cameraObj cameraEffect ['terminate', 'back', M9_rttStr_zHcamPIP];";
		M9_zHcam_cameraObj cameraEffect ["internal", "FRONT", M9_rttStr_zHcamPIP]; comment "causes switch to player control - 
		- remoteControl above and switchcamera below fixes but now FOV is screwed and I change change it...";

		curatorcamera switchcamera "internal";
		comment "M9_rttStr_zHcamPIP setPiPEffect [1];";
		comment "Leave the camera";
		comment "
		M9_cam_testCam cameraEffect ['terminate', 'back'];
		";
		comment "Delete the camera";
		comment "
		camDestroy M9_cam_testCam;
		";
		with uiNamespace do {
			if (!isNil "M9_keybind_disableViewChangeZeus") then 
			{
				(findDisplay 312) displayRemoveEventHandler ["keyDown", M9_keybind_disableViewChangeZeus];
			};

			M9_keybind_disableViewChangeZeus = (findDisplay 312) displayAddEventHandler ["KeyDown", 
			{
				params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
				private _thirdPersonKeys = (actionKeys 'personView') + (actionKeys 'curatorPersonView');
				if (_key in _thirdPersonKeys) then 
				{
					true;
				} else 
				{
					false;
				};
			}];

			if (!isNil "M9_keybind_fixPlayerListGlitchZeus") then 
			{
				(findDisplay 312) displayRemoveEventHandler ["keyDown", M9_keybind_fixPlayerListGlitchZeus];
			};

			missionNamespace setVariable ['M9SD_fnc_altOpenPlayerListZeus', {
				if (isNull findDisplay 312) exitWith {systemChat 'need zeus'};
				if (focusedCtrl findDisplay 312 == findDisplay 312 displayCtrl 283) exitWith {systemChat 'typing...'}; 

				missionNamespace setVariable ['M9_zHCam_shouldOpenWithZeus', if (cbChecked (uiNamespace getVariable 'M9_uiCtrl_zeusHelmetCams_checkbox')) then {
				true} else {false}];
				waitUntil {isNull findDisplay 49};
				findDisplay 312 closeDisplay 0;
				waitUntil {isNull findDisplay 312};
				player linkItem "ItemGPS";
				openMap true;
				waitUntil {shownMap && visibleMap};
				player selectDiarySubject 'Players';
				comment "
				['Players'] call BIS_fnc_selectDiarySubject;
				drec = player createDiaryRecord ['Players', ['Test', 'Test']]; 
				dkink = createDiaryLink ['Players', drec, 'Test'];
				processDiaryLink dkink;
				";
				waitUntil {((!shownMap) or (!visibleMap) or (inputAction "networkPlayers" > 0) or (inputAction "diary" > 0))};
				if (isNull (getAssignedCuratorLogic player)) exitWith {};
				while {isNull findDisplay 312} do {openCuratorInterface};
				
					

				
				
			}];

			M9_keybind_fixPlayerListGlitchZeus = (findDisplay 312) displayAddEventHandler ["KeyDown", 
			{
				params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
				private _playerListKeys = (actionKeys 'networkPlayers'); 'diary';
				if ((_key in _playerListKeys) && (focusedCtrl findDisplay 312 != findDisplay 312 displayCtrl 283)) then 
				{
					[] spawn M9SD_fnc_altOpenPlayerListZeus;
					true;
				} else 
				{
					false;
				};
			}];
		};
	};

	M9SD_fnc_zHCam_initOverlay = {
		disableSerialization;
		with uiNamespace do {
			comment "check if zeus is open";
			if (isNull (findDisplay 312)) exitWith {systemChat 'need zeus interface';};
			private _display = findDisplay 312;
			private _ctrlA = _display displayCtrl 15513;
			private _ctrlPosA = ctrlPosition _ctrlA;
			private _ctrlPosB = [(_ctrlPosA # 0) - 0.33, (_ctrlPosA # 1) - 0.335, 0.5, 0.37];
			if (!isNil 'M9_uiCtrl_zeusHelmetCams_viewer') then 
			{ctrlDelete M9_uiCtrl_zeusHelmetCams_viewer};
			M9_uiCtrl_zeusHelmetCams_viewer = _display ctrlCreate ['RscPicture', -1];
			M9_uiCtrl_zeusHelmetCams_viewer ctrlSetPosition _ctrlPosB;
			M9_uiCtrl_zeusHelmetCams_viewer ctrlSetBackgroundColor [1,0,1,1];
			M9_uiCtrl_zeusHelmetCams_viewer ctrlSetText M9_rttStr_zHcamPIPTextureStr;
			M9_uiCtrl_zeusHelmetCams_viewer ctrlCommit 0;
			
			
			_ctrlPosC = [(_ctrlPosB # 0), (_ctrlPosB # 1) + 0.383, 0.05, 0.05];
			
			if (!isNil 'M9_uiCtrl_zeusHelmetCams_btnLeft') then 
			{
				ctrlDelete M9_uiCtrl_zeusHelmetCams_btnLeft;
			};
			
			M9_uiCtrl_zeusHelmetCams_btnLeft = _display ctrlCreate ['RscButtonMenu', -1];
			M9_uiCtrl_zeusHelmetCams_btnLeft ctrlSetPosition _ctrlPosC;
			M9_uiCtrl_zeusHelmetCams_btnLeft ctrlSetBackgroundColor [0,1,1,0];
			M9_uiCtrl_zeusHelmetCams_btnLeft ctrlSetStructuredText parseText format ["<t align='left' shadow='0' font='puristaSemiBold' color='#FFFFFF' size='%1'>%2</t>", missionNamespace getVariable ['M9_zHCAMuiBtnTxtSize', str ((safezoneh * 0.5) * 1.31)], "<img image='\A3\ui_f\data\gui\RscCommon\RscHTML\arrow_left_ca.paa'></img>"];
			
			M9_uiCtrl_zeusHelmetCams_btnLeft ctrladdEventHandler ["ButtonClick", 
			{
				with uiNamespace do 
				{
					if (isNil 'M9_zJCAM_plyrIdx') then 
					{
						M9_zJCAM_plyrIdx = 0;
					
					};
					
					private _allunits = allunits;
					
					private _playerCount = count _allunits;
					
					private _decrementedIdx = M9_zJCAM_plyrIdx - 1;
					
					M9_zJCAM_plyrIdx = if (_decrementedIdx <= 0) then 
					{
						(_playerCount - 1);
					} else 
					{
						_decrementedIdx;
					};
					
					missionNamespace setVariable ['M9_zJCAM_plyrIdx', M9_zJCAM_plyrIdx];
					uiNamespace setVariable ['M9_zJCAM_plyrIdx', M9_zJCAM_plyrIdx];
				
					M9_zHCAM_unit = _allunits # M9_zJCAM_plyrIdx;

					with missionNamespace do {
						M9_zHcam_cameraObj attachTo [uiNamespace getVariable 'M9_zHCAM_unit', M9_zHcam_offset, 'head', true];
					};
					
					M9_uiCtrl_zeusHelmetCams_unitName ctrlSetStructuredText parseText format ["<t align='center' shadow='0' font='puristaSemiBold' color='#FFFFFF' size='%1'>%2", str ((safezoneh * 0.5) * 1.1), if (isPlayer M9_zHCAM_unit) then {name M9_zHCAM_unit} else {format ["%1 (AI)", name M9_zHCAM_unit]}];
					M9_uiCtrl_zeusHelmetCams_unitName ctrlCommit 0;

					ctrlSetFocus M9_uiCtrl_zeusHelmetCams_checkbox;

				};
			}];
			
			
			M9_uiCtrl_zeusHelmetCams_btnLeft ctrlCommit 0;
			
			_ctrlPosD = [(_ctrlPosC # 0) + 0.45, (_ctrlPosC # 1), 0.05, 0.05];
			
			if (!isNil 'M9_uiCtrl_zeusHelmetCams_btnRight') then 
			{
				ctrlDelete M9_uiCtrl_zeusHelmetCams_btnRight;
			};
			
			M9_uiCtrl_zeusHelmetCams_btnRight = _display ctrlCreate ['RscButtonMenu', -1];
			M9_uiCtrl_zeusHelmetCams_btnRight ctrlSetPosition _ctrlPosD;
			M9_uiCtrl_zeusHelmetCams_btnRight ctrlSetBackgroundColor [0,1,1,0];
			M9_uiCtrl_zeusHelmetCams_btnRight ctrlSetStructuredText parseText format ["<t align='left' shadow='0' font='puristaSemiBold' color='#FFFFFF' size='%1'>%2</t>", missionNamespace getVariable ['M9_zHCAMuiBtnTxtSize', str ((safezoneh * 0.5) * 1.31)], "<img image='\A3\ui_f\data\gui\RscCommon\RscHTML\arrow_right_ca.paa'></img>"];
			
			M9_uiCtrl_zeusHelmetCams_btnRight ctrladdEventHandler ["ButtonClick", 
			{
				with uiNamespace do 
				{
					if (isNil 'M9_zJCAM_plyrIdx') then 
					{
						M9_zJCAM_plyrIdx = 0;
					
					};
					
					private _allunits = allunits;
					
					private _playerCount = count _allunits;
					
					private _incrementedIdx = M9_zJCAM_plyrIdx + 1;
					
					M9_zJCAM_plyrIdx = if (_incrementedIdx >= _playerCount) then 
					{
						0;
					} else 
					{
						_incrementedIdx;
					};
					
					missionNamespace setVariable ['M9_zJCAM_plyrIdx', M9_zJCAM_plyrIdx];
					uiNamespace setVariable ['M9_zJCAM_plyrIdx', M9_zJCAM_plyrIdx];
				
					M9_zHCAM_unit = _allunits # M9_zJCAM_plyrIdx;

					with missionNamespace do {
						M9_zHcam_cameraObj attachTo [uiNamespace getVariable 'M9_zHCAM_unit', M9_zHcam_offset, 'head', true];
					};

					M9_uiCtrl_zeusHelmetCams_unitName ctrlSetStructuredText parseText format ["<t align='center' shadow='0' font='puristaSemiBold' color='#FFFFFF' size='%1'>%2", str ((safezoneh * 0.5) * 1.1), if (isPlayer M9_zHCAM_unit) then {name M9_zHCAM_unit} else {format ["%1 (AI)", name M9_zHCAM_unit]}];
					M9_uiCtrl_zeusHelmetCams_unitName ctrlCommit 0;

					ctrlSetFocus M9_uiCtrl_zeusHelmetCams_checkbox;
				};
			}];
			
			M9_uiCtrl_zeusHelmetCams_btnRight ctrlCommit 0;
			
			
			_ctrlPosE = [(_ctrlPosD # 0) - 0.39, (_ctrlPosD # 1), 0.381, 0.05];
			
			if (!isNil 'M9_uiCtrl_zeusHelmetCams_unitName') then 
			{
				ctrlDelete M9_uiCtrl_zeusHelmetCams_unitName;
			};
			
			M9_uiCtrl_zeusHelmetCams_unitName = _display ctrlCreate ['RscStructuredText', -1];
			M9_uiCtrl_zeusHelmetCams_unitName ctrlSetPosition _ctrlPosE;
			M9_uiCtrl_zeusHelmetCams_unitName ctrlSetBackgroundColor [1,1,0,0];
			M9_uiCtrl_zeusHelmetCams_unitName ctrlSetStructuredText parseText format ["<t align='center' shadow='0' font='puristaSemiBold' color='#FFFFFF' size='%1'>%2", str ((safezoneh * 0.5) * 1.1), if (isPlayer M9_zHCAM_unit) then {name M9_zHCAM_unit} else {format ["%1 (AI)", name M9_zHCAM_unit]}];
			M9_uiCtrl_zeusHelmetCams_unitName ctrlCommit 0;
			
			_ctrlPosF = [(_ctrlPosC # 0) - 0.005, (_ctrlPosC # 1) - 0.389, 0.033, 0.04];
			
			if (!isNil 'M9_uiCtrl_zeusHelmetCams_checkbox') then 
			{
				ctrlDelete M9_uiCtrl_zeusHelmetCams_checkbox;
			};

			M9SD_fnc_zHCam_handleCheckbox1 = {

				with uiNamespace do 
				{
					switch (cbChecked M9_uiCtrl_zeusHelmetCams_checkbox) do 
					{
						case true: 
						{
							comment "show controls";
							M9_uiCtrl_zeusHelmetCams_viewer ctrlShow true;
							M9_uiCtrl_zeusHelmetCams_btnLeft ctrlShow true;
							M9_uiCtrl_zeusHelmetCams_btnRight ctrlShow true;
							M9_uiCtrl_zeusHelmetCams_unitName ctrlShow true;
							
							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltip 'Offline (Hide)';

							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorBox [1, 1, 1, 1];
							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorShade [0.1, 0.1, 0.1, 0.7];
							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorText [0.7, 0.7, 0.7, 1];

							M9_uiCtrl_zeusHelmetCams_checkbox ctrlCommit 0;
							
							M9_uiCtrl_zeusHelmetCams_status ctrlSetStructuredText parseText format ["<t align='left' shadow='1' font='puristaSemiBold' color='#ff0000' size='%1'>%2", str ((safezoneh * 0.5) * 1), "LIVE"];
							M9_uiCtrl_zeusHelmetCams_status ctrlCommit 0;

							with missionNamespace do {
									if (!isNil 'M9_zHcam_cameraObj') then {
										M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
										camDestroy M9_zHcam_cameraObj
									};
								};
							curatorCamera cameraEffect ['internal', 'back'];
							with missionNamespace do {call M9SD_fnc_zHCam_initCamera};


						};
						
						case false:
						{
							missionNamespace setVariable ['M9_zHCam_shouldOpenWithZeus', false];
							comment "hide controls";
							M9_uiCtrl_zeusHelmetCams_viewer ctrlShow false;
							M9_uiCtrl_zeusHelmetCams_btnLeft ctrlShow false;
							M9_uiCtrl_zeusHelmetCams_btnRight ctrlShow false;
							M9_uiCtrl_zeusHelmetCams_unitName ctrlShow false;
							
							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltip 'Live (Show)';

							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorBox [1, 1, 1, 1];
							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorShade [1, 0, 0, 0.7];
							M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorText [1, 1, 1, 1];

							M9_uiCtrl_zeusHelmetCams_checkbox ctrlCommit 0;
							
							M9_uiCtrl_zeusHelmetCams_status ctrlSetStructuredText parseText format ["<t align='left' shadow='2' font='puristaSemiBold' color='#a0a0a0' size='%1'>%2", str ((safezoneh * 0.5) * 1), "OFFLINE"];
							M9_uiCtrl_zeusHelmetCams_status ctrlCommit 0;

							with missionNamespace do {
								
																	if (!isNil 'M9_zHcam_cameraObj') then {
										M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
										camDestroy M9_zHcam_cameraObj
									};
								
								};
							
							curatorCamera cameraEffect ['internal', 'back'];
							comment "re-open zeus to fix player list glitch";
							[] spawn {
								findDisplay 312 closeDisplay 0;
								waitUntil {isNull findDisplay 312};
								if (isNull (getAssignedCuratorLogic player)) exitWith {};
								while {isNull findDisplay 312} do {openCuratorInterface};
								with missionNamespace do 
								
								{M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];camDestroy M9_zHcam_cameraObj;
								curatorCamera cameraEffect ['internal', 'back'];
								[] spawn M9SD_fnc_zHCam_initOverlay;
							};
							};
						};
					
					};
				};

			};
			
			_defaultOnline = missionNamespace getVariable ['M9_zHCam_shouldOpenWithZeus', false];

			if (_defaultOnline) then {
				missionNamespace setVariable ['M9_zHCam_shouldOpenWithZeus', false];

				M9_uiCtrl_zeusHelmetCams_viewer ctrlShow true;
				M9_uiCtrl_zeusHelmetCams_btnLeft ctrlShow true;
				M9_uiCtrl_zeusHelmetCams_btnRight ctrlShow true;
				M9_uiCtrl_zeusHelmetCams_unitName ctrlShow true;


				with missionNamespace do {
					
														if (!isNil 'M9_zHcam_cameraObj') then {
							M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
							camDestroy M9_zHcam_cameraObj
						};
					
					};


					
				curatorCamera cameraEffect ['internal', 'back'];
				with missionNamespace do {call M9SD_fnc_zHCam_initCamera};

				M9_uiCtrl_zeusHelmetCams_checkbox = _display ctrlCreate ['RscCheckbox', -1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetPosition _ctrlPosF;
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetBackgroundColor [1,0,0,1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTextColor [1,0,0,1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetText "";
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltip 'Offline (Hide)';

				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorBox [1, 1, 1, 1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorShade [0.1, 0.1, 0.1, 0.7];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorText [0.7, 0.7, 0.7, 1];

				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipMaxWidth (SafeZoneW / 2);

				M9_uiCtrl_zeusHelmetCams_checkbox ctrladdEventHandler ["ButtonClick", 
				{
					_this call (uiNamespace getVariable ['M9SD_fnc_zHCam_handleCheckbox1', {}]);
				}];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlCommit 0;
				M9_uiCtrl_zeusHelmetCams_checkbox cbSetChecked true;
			} else {

				comment "remove the keybind edits";
				with uiNamespace do {
					if (!isNil "M9_keybind_fixPlayerListGlitchZeus") then 
					{
						(findDisplay 312) displayRemoveEventHandler ["keyDown", M9_keybind_fixPlayerListGlitchZeus];
					};
					if (!isNil "M9_keybind_disableViewChangeZeus") then 
					{
						(findDisplay 312) displayRemoveEventHandler ["keyDown", M9_keybind_disableViewChangeZeus];
					};
				};

							with missionNamespace do {
								
																	if (!isNil 'M9_zHcam_cameraObj') then {
										M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
										camDestroy M9_zHcam_cameraObj
									};
								
								};	
				curatorCamera cameraEffect ['internal', 'back'];
				M9_uiCtrl_zeusHelmetCams_viewer ctrlShow false;
				M9_uiCtrl_zeusHelmetCams_btnLeft ctrlShow false;
				M9_uiCtrl_zeusHelmetCams_btnRight ctrlShow false;
				M9_uiCtrl_zeusHelmetCams_unitName ctrlShow false;

				M9_uiCtrl_zeusHelmetCams_checkbox = _display ctrlCreate ['RscCheckbox', -1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetPosition _ctrlPosF;
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetBackgroundColor [1,0,0,1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTextColor [1,0,0,1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetText "";
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltip 'Live (Show)';
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorBox [1, 0, 0, 1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorShade [0.1, 0.1, 0.1, 0.7];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipColorText [1, 1, 1, 1];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTooltipMaxWidth (SafeZoneW / 2);

				M9_uiCtrl_zeusHelmetCams_checkbox spawn {
					private _cb = _this;
					with uiNamespace do {
						for '_i' from 1 to 7 do {
							if !( cbChecked _cb ) then {
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetBackgroundColor [1,0.5,0,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTextColorSecondary [1,0.5,0,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTextColor [1,0.5,0,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetActiveColor [1,0.5,0,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlCommit 0;
							};
							sleep 0.1;
							if !( cbChecked _cb ) then {
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetBackgroundColor [1,1,1,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTextColorSecondary [1,1,1,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetTextColor [1,1,1,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlSetActiveColor [1,1,1,1];
								M9_uiCtrl_zeusHelmetCams_checkbox ctrlCommit 0;
							};
							sleep 0.1;
						};
					};
				};
				M9_uiCtrl_zeusHelmetCams_checkbox ctrladdEventHandler ["ButtonClick", 
				{_this call (uiNamespace getVariable ['M9SD_fnc_zHCam_handleCheckbox1', {}]);

				}];
				M9_uiCtrl_zeusHelmetCams_checkbox ctrlCommit 0;
				M9_uiCtrl_zeusHelmetCams_checkbox cbSetChecked false;
			};
			
			_ctrlPosG = [(_ctrlPosF # 0) + 0.03, (_ctrlPosF # 1) + 0.001, 0.133, 0.04];
			
			if (!isNil 'M9_uiCtrl_zeusHelmetCams_status') then 
			{
				ctrlDelete M9_uiCtrl_zeusHelmetCams_status;
			};


			
			M9_uiCtrl_zeusHelmetCams_status = _display ctrlCreate ['RscStructuredText', -1];
			M9_uiCtrl_zeusHelmetCams_status ctrlSetPosition _ctrlPosG;
			M9_uiCtrl_zeusHelmetCams_status ctrlSetBackgroundColor [0,1,0,0];
			if (_defaultOnline) then {
				M9_uiCtrl_zeusHelmetCams_status ctrlSetStructuredText parseText format ["<t align='left' shadow='1' font='puristaSemiBold' color='#ff0000' size='%1'>%2", str ((safezoneh * 0.5) * 1), "LIVE"];

			} else {
				M9_uiCtrl_zeusHelmetCams_status ctrlSetStructuredText parseText format ["<t align='left' shadow='2' font='puristaSemiBold' color='#a0a0a0' size='%1'>%2", str ((safezoneh * 0.5) * 1), "OFFLINE"];
				[] spawn {
					if (isNil 'M9_zHCam_blinkTextOnce') then {
						M9_zHCam_blinkTextOnce = 1;
						with uiNamespace do {  
							private _cb = _this;
							for '_i' from 1 to 4 do {
								if !( cbChecked M9_uiCtrl_zeusHelmetCams_checkbox ) then {
									M9_uiCtrl_zeusHelmetCams_status ctrlSetStructuredText parseText format ["<t align='left' shadow='1' font='puristaSemiBold' color='#ff0000' size='%1'>%2", str ((safezoneh * 0.5) * 1), "OFFLINE"];
									M9_uiCtrl_zeusHelmetCams_status ctrlCommit 0;
								};
								sleep 0.3;
								if !( cbChecked M9_uiCtrl_zeusHelmetCams_checkbox ) then {
									M9_uiCtrl_zeusHelmetCams_status ctrlSetStructuredText parseText format ["<t align='left' shadow='2' font='puristaSemiBold' color='#a0a0a0' size='%1'>%2", str ((safezoneh * 0.5) * 1), "OFFLINE"];
									M9_uiCtrl_zeusHelmetCams_status ctrlCommit 0;
								};
								sleep 0.3;
							};
						};
					};
				};
			};
			M9_uiCtrl_zeusHelmetCams_status ctrlCommit 0;

			






			comment "
			while {sleep 0.01; !isNull _display} do {
				with uiNamespace do {
					if (ctrlShown (M9_uiCtrl_zeusHelmetCams_viewer)) then {
						with missionNamespace do {
							M9_zHcam_cameraObj attachTo [uiNamespace getVariable 'M9_zHCAM_unit', M9_zHcam_offset, 'head', true];
						};
					};
				};
			};
			";
		};
	};

	M9SD_fnc_zHCam_toggleOverlay = {
		if (isNil 'M9_zHCam_overlayEnabled') then {
			M9_zHCam_overlayEnabled = false;
		};
		if (M9_zHCam_overlayEnabled) then {
			comment "disable it";
			M9_zHCam_overlayEnabled = false;
			comment "terminate and destroy camera";
			if (!isNil 'M9_zHcam_cameraObj') then {
				camDestroy M9_zHcam_cameraObj;
				if (!isNil 'M9_rttStr_zHcamPIP') then {
					M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
				};
			};
			missionNamespace setVariable ['M9_zHCam_shouldOpenWithZeus', false];
			comment "re-init curator camera";
			curatorCamera cameraEffect ['internal', 'back'];
			comment "delete the ui elements";
			isNil {
				disableSerialization;
				with uiNamespace do {
					if (!isNil 'M9_uiCtrl_zeusHelmetCams_viewer') then 
					{ctrlDelete M9_uiCtrl_zeusHelmetCams_viewer};
					if (!isNil 'M9_uiCtrl_zeusHelmetCams_btnLeft') then 
					{ctrlDelete M9_uiCtrl_zeusHelmetCams_btnLeft};
					if (!isNil 'M9_uiCtrl_zeusHelmetCams_btnRight') then 
					{ctrlDelete M9_uiCtrl_zeusHelmetCams_btnRight};
					if (!isNil 'M9_uiCtrl_zeusHelmetCams_unitName') then 
					{ctrlDelete M9_uiCtrl_zeusHelmetCams_unitName};
					if (!isNil 'M9_uiCtrl_zeusHelmetCams_checkbox') then 
					{ctrlDelete M9_uiCtrl_zeusHelmetCams_checkbox};
					if (!isNil 'M9_uiCtrl_zeusHelmetCams_status') then 
					{ctrlDelete M9_uiCtrl_zeusHelmetCams_status};
				};
			};
			comment "remove the keybind edits";
			with uiNamespace do {
				if (!isNil "M9_keybind_fixPlayerListGlitchZeus") then 
				{
					(findDisplay 312) displayRemoveEventHandler ["keyDown", M9_keybind_fixPlayerListGlitchZeus];
				};
				if (!isNil "M9_keybind_disableViewChangeZeus") then 
				{
					(findDisplay 312) displayRemoveEventHandler ["keyDown", M9_keybind_disableViewChangeZeus];
				};
			};
			comment "re-open zeus to fix player list glitch";
			[] spawn {
				findDisplay 312 closeDisplay 0;
				waitUntil {isNull findDisplay 312};
				if (isNull (getAssignedCuratorLogic player)) exitWith {};
				while {isNull findDisplay 312} do {openCuratorInterface};
			};
		} else {
			comment "enable it";
			M9_zHCam_overlayEnabled = true;
			while {M9_zHCam_overlayEnabled} do {
				waitUntil {sleep 0.01; ((!isNull findDisplay 312) or (!M9_zHCam_overlayEnabled))};
				if (!M9_zHCam_overlayEnabled) exitWith {systemChat 'loop exited';};
				comment "call M9SD_fnc_zHCam_initCamera;";
				[] spawn M9SD_fnc_zHCam_initOverlay;
				waitUntil {sleep 0.01; ((isNull findDisplay 312) or (!M9_zHCam_overlayEnabled))};
				if (!isNil 'M9_zHcam_cameraObj') then {
					camDestroy M9_zHcam_cameraObj;
					if (!isNil 'M9_rttStr_zHcamPIP') then {
						M9_zHcam_cameraObj cameraEffect ["terminate", "FRONT", M9_rttStr_zHcamPIP];
					};
				};
			};
			systemChat 'loop done';
		};
	};


	[] spawn M9SD_fnc_zHCam_toggleOverlay;




};

[] spawn M9SD_fnc_zeusHelmetCamViewerModule_comp;

comment "
A3_ZeusHelmetCamViewer

Arma 3 Steam Workshop
https://steamcommunity.com/sharedfiles/filedetails/?id=3045798946

MIT License
Copyright (c) 2023 M9-SD
https://github.com/M9-SD/A3_ZeusHelmetCamViewer/tree/main/LICENSE
";