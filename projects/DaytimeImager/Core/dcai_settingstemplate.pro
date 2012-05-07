
function DCAI_SettingsTemplate

	etalon = {port:0, $
			  gap_mm:0.0, $
			  refractive_index:1.0, $
			  steps_per_order:0.0, $
			  scan_voltage:0L, $
			  reference_voltage:0L, $
			  parallel_offset:[0l,0l,0l], $
			  leg_gain:[0.0, 0.0, 0.0], $
			  leg_voltage:[0l,0l,0l], $
			  wedge_voltage:[0L,0L,0L], $
			  voltage_range:[0l,0l]}

	filter = {port:0, $
			  name:['one','two','three','four','five','six'], $
			  current:0 }

	paths = {log:'C:\Cal\IdlSource\DaytimeImager\Logs\', $
			 persistent:'C:\Cal\IdlSource\DaytimeImager\Persistent\', $
			 plugin_base:'C:\Cal\IdlSource\DaytimeImager\Plugins\', $
			 plugin_settings:'C:\Cal\IdlSource\DaytimeImager\Plugins\Plugin_Settings\', $
			 screen_capture:'C:\Cal\IdlSource\DaytimeImager\Plugins\ScreenCaps\', $
			 zonemaps:'C:\Cal\IdlSource\DaytimeImager\Scripts\Zonemap\'}

	site = {name:'', $
			code:'', $
			geo_lat:0.0, $
			geo_lon:0.0 }

	settings = {etalon:[etalon, etalon], $
				filter:filter, $
				paths:paths, $
				site:site, $
				external_dll:'SDI_External.dll' }


	return, settings

end


