; >>>> begin comments
;==========================================================================================
;
; >>>> McObject Class: sdi2k_math_zprof
;
; This file contains the McObject method code for sdi2k_math_zprof objects:
;
; Mark Conde Fairbanks, October 2000.
;
; >>>> end comments
; >>>> begin declarations
;         menu_name = 5577 Horizontal Wind Height Profiler
;        class_name = sdi2k_math_zprof
;       description = SDI Analysis - Fit and Plot Horizontal Wind Height Profiles
;           purpose = SDI analysis
;       idl_version = 5.2
;  operating_system = Windows NT4.0 terminal server
;            author = Mark Conde
; >>>> end declarations

@sdi2k_ncdf.pro

;==========================================================================================
; This is the (required) "new" method for this McObject:

pro sdi2k_math_zprof_new, instance, dynamic=dyn, creator=cmd
;---First, properties specific to this object:
    common zprof_resarr, resarr, smootharr, fitarr
    cmd = 'instance = {sdi2k_math_zprof, '
    cmd = cmd + 'specific_cleanup: ''sdi2k_math_zprof_specific_cleanup'', '
    zprof_behavior = {zprof_behavior, prompt_for_filename: 1, $
                          menu_configurable: 0, $
                              user_editable: [1]}
    zprof_scale = {zprof_scale, auto_scale: 0, $
                                      yrange: [110., 140.], $
                          wind_profile_scale: [-400, 150], $
                            wind_label_range: [-300, 150], $
                           menu_configurable: 1, $
                               user_editable: [0,1,2,3]}
    zprof_geom  = {zprof_geom, viewing_from_above: 0, $
                              radius_maps_to_distance: 0, $
                                       north_rotation: 0, $
                                    menu_configurable: 1, $
                                        user_editable: [0,1,2]}
    zprof_msis  = {zprof_msis,   plot_msis: 1, $
                                      f10pt7: 180., $
                                          ap: 15., $
                                 msis_height: [95.0, 300.0], $
                           menu_configurable: 1, $
                               user_editable: [0,1,2,3]}

    zprof_windfit = {zprof_windfit, height_range: [110., 140.], $
                                           order: 7, $
                           menu_configurable: 1, $
                               user_editable: [0,1]}
    rex = [0, n_elements(resarr)-1]
    smoothing = {zprof_smoothing,    temperature_time_smoothing: 0.7, $
                             temperature_spatial_smoothing: 0.03, $
                                menu_configurable: 1, $
                                    user_editable: [0,1]}

    cmd = cmd + 'behavior: zprof_behavior, '
    cmd = cmd + 'scale: zprof_scale, '
    cmd = cmd + 'smooth_settings: smoothing, '
    cmd = cmd + 'msis: zprof_msis, '
    cmd = cmd + 'map_view: zprof_geom, '
    cmd = cmd + 'wind_fit: zprof_windfit, '
    cmd = cmd + 'parameter: 8, '
    cmd = cmd + 'black_bgnd: 1, '
    cmd = cmd + 'plot_par_string: "null", '
    cmd = cmd + 'records: rex, '
;---Now add fields common to all SDI objects. These will be grouped as sub-structures:
    sdi2k_common_fields, cmd, automation=automation, geometry=geometry
;---Next, add the required fields, whose specifications are read from the 'declarations'
;   section of the comments at the top of this file:
    whoami, dir, file
    obj_reqfields, dir+file, cmd, dynamic=dyn
;---Now, create the instance:
    status = execute(cmd)
end

;==========================================================================================
; This is the event handler for events generated by the sdi2k_math_zprof object:
pro sdi2k_math_zprof_event, event
    common skymap_tlist, tlist, datestr
    common zprof_resarr, resarr, smootharr, fitarr
    widget_control, event.top, get_uvalue=info
    wid_pool, 'Settings: ' + info.wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=zprof_settings
    if widget_info(event.id, /valid_id) and zprof_settings.automation.show_on_refresh then widget_control, event.id, /show

;---Check for a timer tick:
    if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
       sdi2k_math_zprof_tik, info.wtitle
       if zprof_settings.automation.timer_ticking then widget_control, sidx, timer=zprof_settings.automation.timer_interval
       return
    endif

;---Get the menu name for this event:
    widget_control, event.id, get_uvalue=menu_item

    if menu_item eq 'Actions|Time Chooser' then begin
       mcchoice, 'Start time:', tlist, choice
       zprof_settings.records(0) = choice.index
       mcchoice, 'End time:', tlist, choice
       zprof_settings.records(1) = choice.index
       widget_control, sidx, set_uvalue=zprof_settings
    endif

    if menu_item eq 'Actions|Smooth Temperatures' then begin
       wot = resarr(zprof_settings.records(0):zprof_settings.records(1)).temperature
       print, 'Smoothing Temperatures in Time...'
       sdi2k_timesmooth_fits, wot, zprof_settings.smooth_settings.temperature_time_smoothing, /progress
       print, 'Smoothing Temperatures in Space...'
       sdi2k_spacesmooth_fits, wot, zprof_settings.smooth_settings.temperature_spatial_smoothing, /progress
       smootharr(zprof_settings.records(0):zprof_settings.records(1)).temperature = wot
    endif

    if menu_item eq 'Actions|Toggle Background Color' then begin
       zprof_settings.black_bgnd = 1 - zprof_settings.black_bgnd
       widget_control, sidx, set_uvalue=zprof_settings
    endif

    if menu_item eq 'Actions|Fit Winds' then sdi2k_zprof_windfit, info.wtitle
    if menu_item eq 'Actions|Skymap Parameter' then sdi2k_zprof_getpar, info.wtitle


    sdi2k_math_zprof_plot, info.wtitle
    if n_elements(menu_item) eq 0 then menu_item = 'Nothing valid was selected'
end

pro sdi2k_zprof_getpar, wtitle
@sdi2kinc.pro
    common zprof_resarr, resarr, smootharr

    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=zprof_settings


    mcchoice, 'Select a parameter:', ['Doppler Temperature', 'MSIS_Height', 'Characteristic Energy', 'Observed LOS Wind', 'Fitted LOS Winds', 'Residual Winds'], choice
    zprof_settings.parameter = choice.index + 8
    case choice.index of
       0:    begin
             zprof_settings.scale.auto_scale = 0
             zprof_settings.scale.yrange = [250., 700.]
             zprof_settings.parameter = 5
             end
       1:    begin
             zprof_settings.scale.auto_scale = 0
             zprof_settings.scale.yrange = [110., 140.]
             zprof_settings.parameter = 8
             end
       2:    begin
             zprof_settings.scale.auto_scale = 0
             zprof_settings.scale.yrange = [0., 3.]
             zprof_settings.parameter = 9
             end
       3:    begin
             zprof_settings.scale.auto_scale = 0
             zprof_settings.scale.yrange = [-200., 200.]
             zprof_settings.parameter = 4
             end
       4:    begin
             zprof_settings.scale.auto_scale = 0
             zprof_settings.scale.yrange = [-200., 200.]
             zprof_settings.parameter = 4
             end
       5:    begin
             zprof_settings.scale.auto_scale = 0
             zprof_settings.scale.yrange = [-200., 200.]
             zprof_settings.parameter = 4
             end
        else: begin
             zprof_settings.scale.auto_scale = 1
             end
    endcase
    zprof_settings.plot_par_string = choice.name
    widget_control, sidx, set_uvalue=zprof_settings
end

function sdi2k_zprof_windpoly, x, order
    common zprof_svdpars, fitx, fitaz, fitzen

    bases = fltarr(order)
    bases(0) = sin(fitaz(x))*sin(fitzen(x))
    bases(1) = cos(fitaz(x))*sin(fitzen(x))

    for j=1,order/2-1 do begin
        bases(2*j)   = sin(fitaz(x))*sin(fitzen(x))*fitx(x)^j
        bases(2*j+1) = cos(fitaz(x))*sin(fitzen(x))*fitx(x)^j
    endfor
    return, bases
end

pro sdi2k_zprof_windfit, wtitle
@sdi2kinc.pro
    common zprof_resarr, resarr, smootharr, fitarr
    common zprof_warr, windfit
    common zprof_svdpars, fitx, fitaz, fitzen

    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=zprof_settings

    fitaz  = fltarr(n_elements(windfit.azimuths), 1 + zprof_settings.records(1) - zprof_settings.records(0))
    fitzen = fitaz
    for j=0,zprof_settings.records(1) - zprof_settings.records(0) do begin
        fitaz(*,j)  = windfit.azimuths
        fitzen(*,j) = windfit.zeniths
    endfor

    fitarr = smootharr

;---Remove LOS component of vertical wind from LOS winds:    
    for j=0,zprof_settings.records(1) - zprof_settings.records(0) do begin
        fitarr(j).velocity  = fitarr(j).velocity - fitarr(j).velocity(0)*cos(fitzen(*,j)*!dtor)
    endfor
        
    fitx   = reform(fitarr(zprof_settings.records(0):zprof_settings.records(1)).msis_height, n_elements(fitarr(zprof_settings.records(0):zprof_settings.records(1)).msis_height))
    fity   = reform(fitarr(zprof_settings.records(0):zprof_settings.records(1)).velocity,    n_elements(fitarr(zprof_settings.records(0):zprof_settings.records(1)).velocity))

    ysave  = fity

    fitaz = reform(fitaz,  n_elements(fitaz))
    fitzen= reform(fitzen, n_elements(fitzen))

    zkeep = where(fitx ge zprof_settings.wind_fit.height_range(0) and fitx le zprof_settings.wind_fit.height_range(1) and fitzen gt 5.)

    fitaz  = fitaz - 28.5
    fitx   = fitx(zkeep)
    fity   = fity(zkeep)
    fitaz  = fitaz(zkeep)*!dtor
    fitzen = fitzen(zkeep)*!dtor


;---Compute an effective error, to use to weight the SVD fit:
    frcsigtmp = smootharr(zprof_settings.records(0):zprof_settings.records(1)).sigma_temperature/smootharr(zprof_settings.records(0):zprof_settings.records(1)).temperature
    frcsigvel = smootharr(zprof_settings.records(0):zprof_settings.records(1)).sigma_velocity/smootharr(zprof_settings.records(0):zprof_settings.records(1)).velocity
    frcsig    = sqrt(0.001*frcsigtmp^2 + frcsigvel^2)
    velsig    = frcsig*smootharr(zprof_settings.records(0):zprof_settings.records(1)).velocity
    velsig    = reform(velsig, n_elements(velsig))
    velsig    = velsig(zkeep)

    hbinsize=(zprof_settings.wind_fit.height_range(1) - zprof_settings.wind_fit.height_range(0))/25
    zhist  = histogram(fitx, binsize=hbinsize, min=zprof_settings.wind_fit.height_range(0), max=zprof_settings.wind_fit.height_range(1))



    window, 4, xsize=800, ysize=800, title='Target Location Map'
    erase, color=host.colors.white
    plot, [-400, 400], [-400, 400], /nodata, $
              xtitle='Zonal Distance [km]', ytitle='Meridional Distance [km]', color=host.colors.black, $
              charsize=1.5, xthick=3, ythick=3, thick=3, charthick=2, /noerase, /iso, /xstyle, /ystyle
    for j=0,n_elements(fitx)-1 do begin
        hdist = fitx(j)*tan(fitzen(j))
        xdist = hdist*sin(fitaz(j))
        ydist = hdist*cos(fitaz(j))
        pclr  = host.colors.imgmin  + (fitx(j) - zprof_settings.wind_fit.height_range(0))*(host.colors.imgmax - host.colors.imgmin)/(zprof_settings.wind_fit.height_range(1)- zprof_settings.wind_fit.height_range(0))
        plots, xdist, ydist, thick=1, psym=2, symsize=0.7, color=pclr
    endfor

    mccolbar, [0.35, 0.89, 0.75, 0.92], host.colors.imgmin, host.colors.imgmax, $
               zprof_settings.wind_fit.height_range(0), zprof_settings.wind_fit.height_range(1), $
              parname='Altitude ', units=' km', $
              color=host.colors.black, thick=2, charsize=1.5, format='(i3)', $
              /horizontal, /both
              
    empty
    wshow, 4
    fname = next_fname(path='d:\users\conde\main\idl\sdi2000\', namepart='sdi2k_math_zprof_target_map', extn='png')
    gif_this, file=fname, /png


;    windpoly = svdfit(findgen(n_elements(fitx)), fity, 2*(zprof_settings.wind_fit.order+1), $
;                      function_name='sdi2k_zprof_windpoly', measure_errors=velsig, yfit=losfit, sigma=fitsig)
    windpoly = svdfit(findgen(n_elements(fitx)), fity, 2*(zprof_settings.wind_fit.order+1), $
                      function_name='sdi2k_zprof_windpoly', weight=1./velsig, yfit=losfit, sigma=fitsig)
                      
    ix = indgen(n_elements(windpoly)/2)
    print, 'Zonal coefficients are: ', string(windpoly(2*ix),   format='(g10.2)')
    print, 'Meridional coefficient are: ', string(windpoly(1+2*ix), format='(g10.2)')
    print, 'Mean residual is: ', total(abs(fity - losfit))/n_elements(fity)

    zzz = zprof_settings.wind_fit.height_range(0) + findgen(20)*(zprof_settings.wind_fit.height_range(1) - zprof_settings.wind_fit.height_range(0))/20.
    zon = windpoly(0)
    mer = windpoly(1)
    for j=1, zprof_settings.wind_fit.order do begin
        zon = zon + windpoly(j*2)*zzz^j
        mer = mer + windpoly(j*2 + 1)*zzz^j
    endfor

;---Copy the fitted LOS wind values back into fitarr.velocity:
    ysave(zkeep) = losfit
    ysave = reform(ysave, n_elements(windfit.azimuths), 1 + zprof_settings.records(1) - zprof_settings.records(0))
    fitarr(zprof_settings.records(0):zprof_settings.records(1)).velocity = ysave

;---Set plotting ranges:
    wlimz  = [min([zon, mer]), max([zon, mer])]
    wrange = wlimz(1) - wlimz(0)
    wlimz  = wlimz + 0.1*[-wrange, wrange]

;---Force a manual scaling: ##############
    wlimz  = zprof_settings.scale.wind_profile_scale

    hlimz  = [zprof_settings.wind_fit.height_range(0), zprof_settings.wind_fit.height_range(1)]
    hrange = hlimz(1) - hlimz(0)
    hlimz  = hlimz + 0.1*[-hrange, hrange]

    window, 3, xsize=800, ysize=900, title='Wind Component Height Profiles'
    erase, color=host.colors.white
    deg_tik, zprof_settings.scale.wind_label_range, ttvals, nttix, minor, minimum=3
    plot, zon, zzz, xrange=wlimz, yrange=hlimz, $
          xtitle='Velocity [m/s]', ytitle='Altitude [km]', color=host.colors.black, $
          charsize=2, xthick=3, ythick=3, thick=3, charthick=2, $
          /noerase, /ystyle, xstyle=8, ymargin=[4,4], $
           xminor=5, xticks=nttix, xtickv=ttvals

    oplot, mer, zzz, color=host.colors.black, thick=3, linestyle=2
    oplot, [0,0], [hlimz(0), hlimz(1)], thick=1, color=host.colors.black, linestyle=1

    xyouts, mer(0), (hlimz(0) + 2*min(zzz))/3, 'Meridional', color=host.colors.black, align=0.5, charthick=2, charsize=1.8
    xyouts, zon(n_elements(mer)-1), (hlimz(1) + 3*max(zzz))/4, 'Zonal',      color=host.colors.black, align=0.5, charthick=2, charsize=1.8

    deg_tik, [0, 1.5*max(zhist)], ttvals, nttix, minor, minimum=3
    axis, xaxis=1, xrange=[0, 4*max(zhist)], xtitle='Number of data points', $
          charsize=1.5, charthick=2, xthick=3, color=host.colors.black, /save, $
          xminor=2, xticks=nttix, xtickv=ttvals
    plots, 0., zprof_settings.wind_fit.height_range(0)

    for j=0,n_elements(zhist)-1 do begin
        plots, zhist(j),zprof_settings.wind_fit.height_range(0) + j*hbinsize,     color=host.colors.black, thick=2, /continue
        plots, zhist(j),zprof_settings.wind_fit.height_range(0) + (j+1)*hbinsize, color=host.colors.black, thick=2, /continue
    endfor
    plots, 0., zprof_settings.wind_fit.height_range(1), color=host.colors.black, thick=2, /continue
    
    empty
    wshow, 3
    
    fname = next_fname(path='d:\users\conde\main\idl\sdi2000\', namepart='sdi2k_math_zprof_wind_profile', extn='png')
    gif_this, file=fname, /png


    widget_control, sidx, set_uvalue=zprof_settings
end

;==========================================================================================
; This is the routine that handles timer ticks:
pro sdi2k_math_zprof_tik, wtitle, redraw=redraw, _extra=_extra
    sdi2k_math_zprof_plot, wtitle
@sdi2kinc.pro
end

;===========================================================================================
;
;   This does the actual plotting:

pro sdi2k_math_zprof_plot, wtitle
@sdi2kinc.pro
    common zprof_resarr, resarr, smootharr, fitarr
    common skymap_tlist,  tlist, datestr
;---Get settings information for this instance of the output xwindow and this instance of
;   the plot program itself:
    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=zprof_settings

    if n_elements(zone_canvas) eq 0 then return

       msis_dll  = 'd:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'c:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'e:\users\conde\main\idl\msis\idlmsis.dll'
    if not(file_test(msis_dll)) then msis_dll = 'c:\users\conde\main\idl\msis\idlmsis.dll'
    lat   = float(host.operation.header.latitude)
    lon   = float(host.operation.header.longitude)
    if lon lt 0 then lon = lon+360.
    f107  = float(zprof_settings.msis.f10pt7)
    f107a = f107
    ap    = fltarr(7)
    mass  = 48L
    t     = fltarr(2)
    d     = fltarr(8)
    delz  = 10. ; model profile height increment in km

    lumm_height = 100. + findgen(11)*10.
    lumm_charen = [6.3, 2.5, 1.7, 0.96, 0.76, 0.52, 0.4, 0.3, 0.22, 0.18, 0.11]
    
;    nrg_in_kev   = [0.100000, 0.200000, 0.400000, 0.700000, 1.00000, 2.00000, 4.00000, 7.00000, 10.0000]
;    lumtemp5577  = [1098.71,  1025.73,  866.188,  645.408,  494.475, 298.237, 221.709, 201.032, 196.207]
 
    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    for j=0,n_elements(smootharr)-1 do begin
        tcen = (smootharr(j).start_time + smootharr(j).end_time)/2.
      	         yyddd  = long(dt_tm_mk(js2jd(0d)+1, tcen, format='doy$'))
      	         js2ymds, tcen, yy, mm, dd, ss
      	         ss     = float(ss)
      	         lst    = ss/3600. + lon/15.
      	         if lst lt 0  then lst = lst + 24.
      	         if lst gt 24 then lst = lst - 24.
      	         ap(0)  = zprof_settings.msis.ap
    ; 	          print, yyddd, ss, lat, lon, lst, f107a, f107, ap, mass
                 for alt = zprof_settings.msis.msis_height(0),zprof_settings.msis.msis_height(1),delz do begin
       	             result = call_external(msis_dll,'msis90', $
      	                                    yyddd, ss, alt, lat, lon, lst, f107a, f107, ap, mass, d, t)
      	             if alt eq zprof_settings.msis.msis_height(0) then msis_vals = t(1) else msis_vals = [msis_vals, t(1)]
      	         endfor
      	         nc = 0
		 for zidx=0,nz-1 do begin
		     smootharr(j).msis_height(zidx) = zprof_settings.msis.msis_height(0)
		     colder = where(msis_vals lt smootharr(j).temperature(zidx), nc)
		     if nc gt 0 then begin
		        loidx = colder(n_elements(colder)-1)
		        hiidx = loidx + 1
		        smootharr(j).msis_height(zidx) = zprof_settings.msis.msis_height(1)
		        if hiidx le n_elements(msis_vals) - 1 then begin
		           hlo = zprof_settings.msis.msis_height(0) + loidx*delz
		           hhi = hlo + delz
		           hgt = hlo + delz*(smootharr(j).temperature(zidx) - msis_vals(loidx))/(msis_vals(hiidx) - msis_vals(loidx))
 		           smootharr(j).msis_height(zidx) = hgt

 		           lower = where(lumm_height lt hgt, nc)
 		           smootharr(j).characteristic_energy(zidx) = lumm_charen(0)
 		           if nc gt 0 then begin
		              loidx = lower(n_elements(lower)-1)
		              hiidx = loidx + 1
		              smootharr(j).characteristic_energy(zidx) = lumm_charen(n_elements(lumm_charen)-1)
		              if hiidx le n_elements(lumm_charen) - 1 then begin
		                 elo = lumm_charen(loidx)
		                 ehi = lumm_charen(hiidx)
		                 nrg = elo + (ehi - elo)*(hgt - lumm_height(loidx))/(lumm_height(hiidx) - lumm_height(loidx))
		                 smootharr(j).characteristic_energy(zidx) = nrg
		              endif
 		           endif
 		        endif
		     endif
		 endfor

    endfor

    if !d.name ne 'Z' and !d.name ne 'PS' then wset, info.wid

    plotarr = smootharr
    if zprof_settings.plot_par_string eq 'Fitted LOS Winds' then plotarr = fitarr
    if zprof_settings.plot_par_string eq 'Residual Winds'   then plotarr.velocity = smootharr.velocity - fitarr.velocity

    sdi2k_sky_mapper, tlist, tcen, datestr, plotarr, zprof_settings, $
                      map_view=zprof_settings.map_view.viewing_from_above, $
                      azimuth_rotation=zprof_settings.map_view.north_rotation, palette=palette

                      
;---Check if we need to make a GIF file:
    ;sdi2k_plugin_gif, info, js_time=timlimz(1)
end

;==========================================================================================
;   Cleanup jobs:
pro sdi2k_math_zprof_specific_cleanup, widid
@sdi2kinc.pro
    close, /all
;    ncdf_close, host.netcdf(0).ncid
;    host.netcdf(0).ncid = -1
end

;==========================================================================================
; This is the (required) "autorun" method for this McObject. If no autorun action is
; needed, then this routine should simply exit with no action:

pro sdi2k_math_zprof_autorun, instance
@sdi2kinc.pro
    common zprof_resarr, resarr, smootharr, fitarr
    common zprof_warr, windfit
    common skymap_tlist, tlist, datestr
    device, get_screen_size=box
    instance.geometry.xsize = 0.9*box(0)
    instance.geometry.ysize = 0.85*min(box) + 100
    instance.automation.timer_interval = 1.
    instance.automation.timer_ticking = 0
    if instance.behavior.prompt_for_filename then begin
       spekfile = dialog_pickfile(file=skyfile, $
                                 filter='*.' + host.operation.header.site_code, $
                                 group=widx, title='Select a file of sky spectra: ', $
                                 path=host.operation.logging.log_directory)
    endif

    sdi2k_ncopen, spekfile, ncid, 0
    if n_elements(resarr) gt 0 then undefine, resarr
    sdi2k_build_fitres, ncid, resarr
    sdi2k_build_windres, ncid, windfit
    sdi2k_remove_radial_residual, resarr, parname='TEMPERATURE'
    sdi2k_physical_units, resarr
    smootharr = resarr
;    if n_elements(zone_map) lt 1 then sdi2k_build_zone_map, canvas_size = [0.95*min(box), 0.95*min(box)], /map_project
    sdi2k_build_zone_map, canvas_size = [0.95*min(box), 0.95*min(box)]
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    record = 0
    tlist = strarr(maxrec)
    for rec=record,maxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        tcen = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
        hhmm = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')
        tlist(rec) =  hhmm
    endfor
    sdi2k_read_exposure, host.netcdf(0).ncid, 0
    ctime = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
    datestr = dt_tm_mk(js2jd(0d)+1, ctime, format='0d$ n$ Y$')

    ncdf_close, host.netcdf(0).ncid
    host.netcdf(0).ncid = -1
    instance.records = [0, n_elements(tlist)-1]

    mc_menu, extra_menu, 'Actions',                 1, event_handler='sdi2k_math_zprof_event', /new
    mc_menu, extra_menu, 'Fit Winds',               0, event_handler='sdi2k_math_zprof_event'
    mc_menu, extra_menu, 'Time Chooser',            0, event_handler='sdi2k_math_zprof_event'
    mc_menu, extra_menu, 'Skymap Parameter',        0, event_handler='sdi2k_math_zprof_event'
    mc_menu, extra_menu, 'Smooth Temperatures',     0, event_handler='sdi2k_math_zprof_event'
    mc_menu, extra_menu, 'Toggle Background Color', 0, event_handler='sdi2k_math_zprof_event'
    mc_menu, extra_menu, 'Redraw',         2, event_handler='sdi2k_math_zprof_event'
    mnu_xwindow_autorun, instance, topname='sdi2ka_top', extra_menu=extra_menu

    print, 'WARNING: Maps hard-wired to sky_projected!'

    sdi2k_math_zprof_plot, instance.description
end

;==========================================================================================
; This is the (required) class method for creating a new instance of the sdi2k_math_zprof object. It
; would normally be an empty procedure.  Nevertheless, it MUST be present, as the last procedure in
; the methods file, and it MUST have the same name as the methods file.  By calling this
; procedure, the caller forces all preceeding routines in the methods file to be compiled,
; and so become available for subsequent use:

pro sdi2k_math_zprof
end

