
@dcai_script_utilities

;\\ Turn a 16-bit unsigned (0-4095) integer into a 3-character HEX string
function DCAI_Drivers_Etalon_MakeHEX, i

	;\\ 16-bit integer number, force into range without wrapping
	if i lt 0 then i = 0
	if i gt 65535 then i = 65535

	hex_string = string(i, f='(z04)')
	return, hex_string
end



pro DCAI_Drivers, command

	COMMON DCAI_Control, dcai_global


	case command.device of

		'init': begin
			DCAI_Drivers, {device:'comms_init'}
			DCAI_Drivers, {device:'filter_init'}
			DCAI_Drivers, {device:'calibration_init'}
			DCAI_Drivers, {device:'camera_init', settings:dcai_global.info.camera_profile}
			DCAI_Drivers, {device:'etalon_init'}
		end

		'finish': begin
			DCAI_Drivers, {device:'comms_finish'}
		end

		'comms_init':begin

			;\\ Set up the com ports
			dll = dcai_global.settings.external_dll
			comms_wrapper, dcai_global.settings.filter.port, dll, type = 'moxa', /open, errcode=errcode, moxa_setbaud=12
			dcai_global.settings.filter.open = errcode
			DCAI_Log, 'Open Filter Source Port: ' + string(errcode, f='(i0)')
			comms_wrapper, dcai_global.settings.mirror.port, dll, type = 'moxa', /open, errcode=errcode, moxa_setbaud=12
			dcai_global.settings.mirror.open = errcode
			DCAI_Log, 'Open Mirror Port: ' + string(errcode, f='(i0)')
			comms_wrapper, dcai_global.settings.calibration.port, dll, type = 'moxa', /open, errcode=errcode, moxa_setbaud=12
			dcai_global.settings.calibration.open = errcode
			DCAI_Log, 'Open Calibration Port: ' + string(errcode, f='(i0)')
		end

		'comms_finish':begin

			;\\ Set up the com ports
			dll = dcai_global.settings.external_dll
			comms_wrapper, dcai_global.settings.filter.port, dll, type = 'moxa', /close, errcode=errcode
			DCAI_Log, 'Close Filter Source Port: ' + string(errcode, f='(i0)')
			comms_wrapper, dcai_global.settings.mirror.port, dll, type = 'moxa', /close, errcode=errcode
			DCAI_Log, 'Close Mirror Port: ' + string(errcode, f='(i0)')
			comms_wrapper, dcai_global.settings.calibration.port, dll, type = 'moxa', /close, errcode=errcode
			DCAI_Log, 'CLose Calibration Port: ' + string(errcode, f='(i0)')
		end


		'etalon_setlegs':begin

			tx = string(13B)
			voltage = command.voltage > 0
			voltage = voltage < 65535
			hex_string = string(voltage, f='(z04)')
			vol_string = strjoin(hex_string)

			cmd_string = 'u' + string(command.number + 1, f='(i1)') + vol_string + tx

			comms_wrapper, dcai_global.settings.etalon[command.number].port, dcai_global.settings.external_dll, $
				   		   type='moxa', /write, data=cmd_string
			wait, 0.02
			comms_wrapper, dcai_global.settings.etalon[command.number].port, dcai_global.settings.external_dll, $
				   		   type='moxa', /read, data=read_in

		end


		'etalon_init':begin

			dcai_log, 'Initialising Etalons'
			return

			for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
				comms_wrapper, dcai_global.settings.etalon[k].port, dcai_global.settings.external_dll, $
					   		   	   type='moxa', /open, err=err, moxa_setbaud=15
				dcai_log, 'Open Port: ' + string(dcai_global.settings.etalon[k].port, f='(i0)') + ' ' + string(err, f='(i0)')
			endfor


			tx = string(13B)
			cmds = ['E1R1CC150', 'E1R1CF128', 'E1R1RC231', 'E1R1RF150', $
					'E1R2CC150', 'E1R2CF128', 'E1R2RC231', 'E1R2RF150', $
					'E1R3CC150', 'E1R3CF128', 'E1R3RC231', 'E1R3RF150', $

					'E1L1CC092', 'E1L1CF128', 'E1L1RC232', 'E1L1RF080', $
					'E1L2CC085', 'E1L2CF129', 'E1L2RC230', 'E1L2RF154', $
					'E1L3CC095', 'E1L3CF132', 'E1L3RC231', 'E1L3RF060', $

					'E1L1DD246', 'E1L1DG60000', $
					'E1L2DD246', 'E1L2DG60000', $
					'E1L3DD246', 'E1L3DG60000'  ]


			comms_wrapper, dcai_global.settings.etalon[0].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
			wait, .1
			for i = 0, n_elements(cmds) - 1 do begin
				comms_wrapper, dcai_global.settings.etalon[0].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /write, data=cmds[i] + tx
				wait, 0.2
				comms_wrapper, dcai_global.settings.etalon[0].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
				dcai_log, cmds[i] + ': ' + read_in
			endfor

			cmds = ['E2R1CC150', 'E2R1CF128', 'E2R1RC231', 'E2R1RF150', $
					'E2R2CC150', 'E2R2CF128', 'E2R2RC231', 'E2R2RF150', $
					'E2R3CC150', 'E2R3CF128', 'E2R3RC231', 'E2R3RF150', $

					'E2L1CC095', 'E2L1CF132', 'E2L1RC231', 'E2L1RF091', $
					'E2L2CC101', 'E2L2CF110', 'E2L2RC229', 'E2L2RF162', $
					'E2L3CC100', 'E2L3CF131', 'E2L3RC228', 'E2L3RF065', $

					'E2L1DD244', 'E2L1DG60000', $
					'E2L2DD244', 'E2L2DG60000', $
					'E2L3DD245', 'E2L3DG60000'  ]

			wait, .1
			comms_wrapper, dcai_global.settings.etalon[1].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
			wait, .1
			for i = 0, n_elements(cmds) - 1 do begin
				comms_wrapper, dcai_global.settings.etalon[1].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /write, data=cmds[i] + tx
				wait, 0.2
				comms_wrapper, dcai_global.settings.etalon[1].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
				dcai_log, cmds[i] + ': ' + read_in
			endfor

		end


		'filter_init':begin

			if (dcai_global.settings.filter.open ne 0) then begin
				DCAI_Log, 'Filter port not open - skip homing'
				return
			endif

			;\\ Filter Wheel Init
				tx = string(13B)
				fport = dcai_global.settings.filter.port
				dll = dcai_global.settings.external_dll
				comms_wrapper, fport, dll, type='moxa', /write, data = 'EN' + tx
				comms_wrapper, fport, dll, type='moxa', /write, data = 'LPC1000' + tx
				comms_wrapper, fport, dll, type='moxa', /write, data = 'LCC1500' + tx
				comms_wrapper, fport, dll, type='moxa', /write, data = 'SP15000' + tx
				comms_wrapper, fport, dll, type='moxa', /write, data = 'HOSP-10000' + tx

			;\\ Home to the limit switch
				res = drive_motor(fport, dll, /goix, timeout=30)
		end


		;\\ command = {device:'filter_select', filter:0 (int)}
		'filter_select':begin

			if (dcai_global.settings.filter.open ne 0) then begin
				DCAI_Log, 'Filter port not open - skip filter select'
				return
			endif

			if HasField(command, 'filter') ne 1 then begin
				DCAI_Log, 'Filter_Select called without filter number'
				return
			endif

			fport = dcai_global.settings.filter.port
			dll = dcai_global.settings.external_dll
			inc = 801000L
			abs_pos = inc*(command.filter)
			comms_wrapper, fport, dll, /write, type='moxa', data = 'LA' + string(abs_pos, f='(i0)') + string(13B)
			comms_wrapper, fport, dll, /write, type='moxa', data = 'NP' + string(13B)
			comms_wrapper, fport, dll, /write, type='moxa', data = 'M' + string(13B)
			drive_motor_wait_for_position, fport, dll, 'moxa', max_wait_time=60, errcode=errcode
		end


		;\\ Home the calibration selector motor
		'calibration_init':begin

			if (dcai_global.settings.calibration.open ne 0) then begin
				DCAI_Log, 'Calibration port not open - skip homing'
				return
			endif

			info_string = 'Homing Calibration Source'

			base = widget_base(col=1, group=dcai_global.gui.base, /floating)
			info = widget_label(base, value=info_string, font='Ariel*20*Bold', xs=400)
			widget_control, /realize, base

			;\\ Set the current limits
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LCC150'  + tx
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LPC200'  + tx

			;\\ Enable the motor
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'EN'  + tx
			;\\ Call current position 0
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'HO'  + tx
			;\\ Set a low speed, 5 RPM
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'SP5'  + tx
			;\\ Drive two full revolutions, so we have to hit the stop at some point
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LA6000'  + tx

			;\\ Note the current time
				home_start_time = systime(/sec)
			;\\ Initiate the motion
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'M'  + tx

			;\\ Wait 10 seconds
				while (systime(/sec) - home_start_time) lt 10 do begin
					wait, 0.5
					widget_control, set_value ='Homing Calibration Source ' + $
							string(10 - (systime(/sec) - home_start_time), f='(f0.1)'), info
				endwhile

			;\\ Call the home position 0
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'HO'  + tx
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'SP50'  + tx
			;\\ Drive a little bit away from it
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LA-10'  + tx
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'M'  + tx
				wait, 2.

				print, 'Cal Source Homed'
				comms_wrapper, port, dll_name, type = 'moxa', /write, data = 'DI'+tx

			;\\ Close notification window
				if widget_info(base, /valid) eq 1 then widget_control, base, /destroy
		end


		;\\ command = {device:'calibration_select', source:0 (int)}
		'calibration_select':begin

			if (dcai_global.settings.filter.open ne 0) then begin
				DCAI_Log, 'Calibration port not open - skip calibration select'
				return
			endif

			if HasField(command, 'source') ne 1 then begin
				DCAI_Log, 'Calibration_Select called without source number'
				return
			endif

			case command.source of
				0: motor_pos = -150
				1: motor_pos = -850
				2: motor_pos = -1650
				3: motor_pos = -2400
				else:
			endcase

			port = dcai_global.settings.calibration.port
			dll = dcai_global.settings.external_dll
			tx = string(13B)

			;\\ Notification window
				info_string = 'Driving to Calibration Source ' + string(source, f='(i01)') + $
					 ' at Pos: ' + string(motor_pos, f='(i0)')

				base = widget_base(col=1, group=dcai_global.gui.base, /floating)
				info = widget_label(base, value=info_string, font='Ariel*20*Bold', xs=400)
				widget_control, /realize, base

			;\\ Set the current limits
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LCC150'  + tx
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LPC200'  + tx

				comms_wrapper, port, dll_name, type = 'moxa', /write, data = 'EN'+tx
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'LA' + string(motor_pos, f='(i0)') + tx
				comms_wrapper, port, dll_name, type='moxa', /write, data = 'M' + tx
				wait, 6.
				comms_wrapper, port, dll_name, type = 'moxa', /write, data = 'DI'+tx

			;\\ Close notification window
				if widget_info(base, /valid) eq 1 then widget_control, base, /destroy

		end


		'camera_init':begin

			;\\ TEST TO SEE IF WE CAN TALK TO THE CAMERA
				Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGetStatus', 0, out, res
				DCAI_Log, 'Cam Status: ' + res

				if res eq 'DRV_NOT_INITIALIZED' then $
					Andor_Camera_Driver, dcai_global.settings.external_dll, 'uInitialize', '', out, res

				Andor_Camera_Driver, dcai_global.settings.external_dll, 'uAbortAcquisition', '', out, res
				did_we_init = 0
				if res eq 'DRV_ERROR_ACK' then begin
					dcai_global.info.camera_settings.initialized = 0
					DCAI_Log, 'Camera acknowledge...False - PROBLEM!'
				endif else begin
					dcai_global.info.camera_settings.initialized = 1
					did_we_init = 1
					DCAI_Log, 'Camera acknowledge...True'
				endelse

				DCAI_Log, 'Cam Init: ' + res

			;\\ QUERY THE CAMERA TO FIND OUT ITS CAPABILITIES
				Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGetCapabilities', 0, caps, res, /auto_acq
				*dcai_global.info.camera_caps = caps

			;\\ LOAD THE INITIAL CAMERA SETTINGS
				have_settings = (HasField(command, 'settings') eq 1)
				if (have_settings eq 1) then have_settings = (command.settings ne '')

				if have_settings eq 0 then begin
					DCAI_Log, 'Camera Init: No camera settings file provided, attempting default settings'

					Andor_Camera_Driver, dcai_global.settings.external_dll, 'uSetDefaults', $
										 {settings:dcai_global.info.camera_settings, capabilities:caps}, sets, res, /auto_acq

					;\\ Upload the settings to the camera
						Andor_Camera_Driver, dcai_global.settings.external_dll, 'uApplySettingsStructure', sets, outs, result, /auto_acq
						dcai_global.info.camera_settings = sets

					;\\ Update any values that may need to be read back from the camera
						DCAI_LoadCameraSetting_Readback, /hsSpeed, /vsSpeed, /exposureTime, $
														 /readMode, /acqMode, /triggerMode, $
														 /emGain
				endif else begin
					if command.settings ne '' then begin
						DCAI_LoadCameraSetting, dcai_global.settings.external_dll, $
												settings_script = dcai_global.info.camera_profile, $
											    debug_ress = dbg_results
			      		dcai_global.info.camera_settings.initialized = did_we_init
						for i = 0, n_elements(dbg_results) - 1 do DCAI_Log, dbg_results[i]
					endif
				endelse

			;\\ WE ALSO NEED TO GRAB A DUMMY CAMERA IMAGE, SO THAT WE KNOW WHAT THE IMAGE DIMENSIONS ARE
				imageMode = dcai_global.info.camera_settings.imageMode
				Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGrabFrame', {mode:-1, imageMode:imageMode}, out, res
				*dcai_global.info.image = out.image
				*dcai_global.info.raw_image = out.image


		end


		'camera_flush':begin
			Andor_Camera_Driver, dcai_global.settings.external_dll, 'uFreeInternalMemory', 0, out, res, /auto_acq
		end




		else:begin

		end


	endcase

end