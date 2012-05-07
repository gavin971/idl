; >>>> begin comments
;==========================================================================================
;
; >>>> McObject Class: sdi2k_prog_chord
;
; This file contains the McObject method code for sdi2k_prog_chord objects:
;
; Mark Conde (Mc), Poker Flat, October 2000.
;
; >>>> end comments
; >>>> begin declarations
;         menu_name = Channels per Order
;        class_name = sdi2k_prog_chord
;       description = SDI Program - Channels/Order
;           purpose = SDI operation
;       idl_version = 5.2
;  operating_system = Windows NT4.0 terminal server 
;            author = Mark Conde
; >>>> end declarations


;==========================================================================================
; This is the (required) "new" method for this McObject:

pro sdi2k_prog_chord_new, instance, dynamic=dyn, creator=cmd
;---First, properties specific to this object:
    cmd = 'instance = {sdi2k_prog_chord, '
    cmd = cmd + 'specific_cleanup: ''sdi2k_prog_chord_specific_cleanup'', '    
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
; This is the event handler for events generated by the sdi2k_prog_chord object:
pro sdi2k_prog_chord_event, event
    widget_control, event.top, get_uvalue=info
    wid_pool, 'Settings: ' + info.wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=chord_settings
    if widget_info(event.id, /valid_id) and chord_settings.automation.show_on_refresh then widget_control, event.id, /show

;---Check for a timer tick:    
    if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
       sdi2k_prog_chord_tik, info.wtitle
       if chord_settings.automation.timer_ticking then widget_control, widx, timer=chord_settings.automation.timer_interval
       return
    endif
    
;---Check for a new frame event sent by the control module:
    nm      = 0
    matched = where(tag_names(event) eq 'NAME', nm)
    if nm gt 0 then begin
       if event.(matched(0)) eq 'NewFrame' then begin
          sdi2k_prog_chord_tik, info.wtitle
          return
       endif
       if event.(matched(0)) eq 'Integration Completed' then begin
          sdi2k_prog_chord_integration_done, info.wtitle
          return
       endif
    endif

;---Get the menu name for this event:
    widget_control, event.id, get_uvalue=menu_item
    if n_elements(menu_item) eq 0 then menu_item = 'Nothing valid was selected'
end

;==========================================================================================
; This is the routine that calculates and displays chord:
pro sdi2k_showchord, wtitle, redraw=redraw, _extra=_extra
@sdi2kinc.pro
    common chordstuff, chordvec, chordhist, refim, scanim, ref_flag, rsel
    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=pmap_settings
    if !d.name ne 'Z' and !d.name ne 'PS' then wset, info.wid
   
    erase
    !p.multi = [0,0,2,0,0]
;---Plot the cross-correlation vector and a polynomial fit to it:
    gapz = host.programs.chord.chord_search_logap + findgen(n_elements(chordvec))*host.programs.chord.stepsize
    nn   = indgen(n_elements(chordvec)-6)+3
    yy   = smooth(chordvec, 3)
    cfz  = svdfit(double(gapz(nn)), double(yy(nn)), host.programs.chord.fit_degree, yfit=chordfit)
    plot,  gapz(nn), chordvec(nn), xtitle='Channel Shift', ytitle='Cross Correlation', $
          /xstyle, /ystyle, color=host.colors.white, /nodata, $
           yrange=[min([chordvec(nn), chordfit]), max([chordvec(nn), chordfit])]
    oplot, gapz(nn), chordfit, color=host.colors.green
    oplot, gapz(nn), chordvec(nn), psym=1, symsize=0.5, color=host.colors.yellow
    
;---Get the chord value:
    dd   = findgen(host.programs.chord.fit_degree)
    dd   = dd(1:*)*cfz(1:*)
    dd   = float(fz_roots(dd))
    ddy  = poly(dd, cfz)
    best = where(ddy eq max(ddy))
    host.programs.chord.chord_val = dd(best(0))
    chordlab = 'Channels/Order = ' + strcompress(string(dd(best(0)), format='(f7.2)'))
    
;---Build and plot the chord history:
    if n_elements(chordhist) eq 0 then begin
       chordhist = host.programs.chord.chord_val
    endif else begin
       chordhist = [chordhist, host.programs.chord.chord_val]
       plot,  chordhist, xtitle='Scan Number', ytitle='Channels/Order', $
             /xstyle, /ystyle, color=host.colors.white, /nodata, title=chordlab
       oplot, chordhist, color=host.colors.cyan
    endelse
    
end


;==========================================================================================
; This is the routine that updates the chord accumulations:
pro sdi2k_prog_chord_tik, wtitle, redraw=redraw, _extra=_extra
@sdi2kinc.pro
    common chordstuff, chordvec, chordhist, refim, scanim, ref_flag, rsel

;---Get settings information for this instance of the output xwindow and this instance of 
;   the plot program itself:
    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=chord_settings
    
    if !d.name ne 'Z' and !d.name ne 'PS' then begin
       wset, info.wid
       host.programs.chord.frame_count = host.programs.chord.frame_count + 1
       if host.programs.chord.ref_flag then begin
          refim = refim + view
          if host.programs.chord.frame_count ge host.programs.chord.reference_frames then begin
             host.programs.chord.ref_flag = 0
             refim = float(refim - total(refim(rsel))/n_elements(refim(rsel)))
             refim = refim/max(refim)
             host.programs.chord.frame_count = 0
             host.hardware.etalon.current_spacing = host.programs.chord.chord_search_logap
             erase
          endif
       endif else begin
          scanim = scanim + view
          if host.programs.chord.frame_count ge host.programs.chord.frames_per_step then begin
             host.programs.chord.frame_count = 0
             step   = (host.hardware.etalon.current_spacing - host.programs.chord.chord_search_logap)/host.programs.chord.stepsize
             scanim = float(scanim - total(scanim(rsel))/n_elements(scanim(rsel)))
             chordvec(step) = chordvec(step) + total(scanim(rsel)*refim(rsel))
             scanim = uintarr(n_elements(view(*,0)), n_elements(view(0,*)))
             host.hardware.etalon.current_spacing = host.hardware.etalon.current_spacing + host.programs.chord.stepsize
             sdi2k_etalon_gap

             if host.hardware.etalon.current_spacing gt host.programs.chord.chord_search_higap then begin
                host.hardware.etalon.current_spacing = host.programs.chord.chord_search_logap
                sdi2k_etalon_gap
                sdi2k_showchord, wtitle
                sdi2k_plugin_gif, info, /now
             endif          
          endif
       endelse
    endif else begin
          sdi2k_showchord, wtitle
    endelse
  
    if dt_tm_tojs(systime()) - host.programs.chord.start_time gt $
       host.programs.chord.integration_seconds then begin
       wid_pool, 'sdi2k_top', tidx, /get
       widget_control, sidx, send_event={id: tidx, $
                                        top: tidx, $
                                    handler: sidx, $
                                       name: 'Integration Completed'}
    endif


;---Finally, update the exposure meter, if it exists:
    wid_pool, 'SDI program - Exposure: Chord', eidx, /get
    wid_pool, 'chord_exposure_slider', slid, /get

    if not(widget_info(eidx, /valid_id)) then return
    delsecs = dt_tm_tojs(systime()) - host.programs.chord.start_time
    pcnt    = 100.*delsecs/host.programs.chord.integration_seconds
    widget_control, slid, get_value=opc
    if pcnt - opc gt 2 then widget_control, slid, set_value=pcnt
end

;==========================================================================================
;   End of chord integration: save the chord value, and exit:
pro sdi2k_prog_chord_integration_done, wtitle
@sdi2kinc.pro
    sdi2k_user_message, 'Final channels/order estimate was: ' + $
                         strcompress(string(host.programs.chord.chord_val, format='(f9.2)'))
    if host.programs.chord.apply_results then $
       host.hardware.etalon.nm_per_step = (host.operation.calibration.cal_wavelength/2.)/host.programs.chord.chord_val
    wid_pool, wtitle, widx, /destroy
end

;==========================================================================================
;   Cleanup jobs:
pro sdi2k_prog_chord_specific_cleanup, widid
@sdi2kinc.pro
    host.controller.scheduler.job_semaphore = 'No scheduled job'
    sdi2k_set_shutters, camera='closed', laser='closed'
end

pro sdi2k_prog_chord_end_expmeter
@sdi2kinc.pro
    wid_pool, 'SDI Program -  Exposure: Chord', /destroy
end


;==========================================================================================
; This is the (required) "autorun" method for this McObject. If no autorun action is 
; needed, then this routine should simply exit with no action:

pro sdi2k_prog_chord_autorun, instance
@sdi2kinc.pro
    common chordstuff, chordvec, chordhist, refim, scanim, ref_flag, rsel
    wid_pool, 'SDI program - Phase Map', /destroy
    host.programs.phase_map.angle_coefficient = 2.*!pi*host.hardware.etalon.nm_per_step * $
                                                host.hardware.etalon.gap_refractive_index / $
                                               (host.operation.calibration.cal_wavelength/2.)
    instance.geometry.xsize = 800
    instance.geometry.ysize = 700
    instance.automation.timer_interval = 1.
    instance.automation.timer_ticking = 0
    instance.automation.auto_gif_interval = 9999999l

    sdi2k_set_shutters, camera='open', laser='closed'
    sdi2k_etalon_scan, /reset
    host.controller.scheduler.job_semaphore = 'Measuring Channels per Order'
    host.programs.chord.start_time = dt_tm_tojs(systime())
    host.programs.chord.ref_flag = 1
    host.programs.chord.frame_count = 0
    host.hardware.etalon.current_spacing = 0
    host.hardware.etalon.current_channel = 0
    sdi2k_etalon_gap
    refim  = uintarr(n_elements(view(*,0)), n_elements(view(0,*)))
    scanim = uintarr(n_elements(view(*,0)), n_elements(view(0,*)))
    chordvec = fltarr((host.programs.chord.chord_search_higap - host.programs.chord.chord_search_logap) / $
                       host.programs.chord.stepsize + 1)
    if n_elements(chordhist) gt 0 then undefine, chordhist
;---Make an image array whose elements represent the distance from the nominal fringe center:
    nx   = n_elements(view(*,0))
    ny   = n_elements(view(0,*))
    xx   = transpose(lindgen(ny,nx)/ny) - host.operation.zones.x_center
    yy   = lindgen(nx,ny)/nx            - host.operation.zones.y_center
    dst  = sqrt(xx*xx + yy*yy)
;---Select pixels within 70% of the approximate image radius:
    rsel = where(dst lt 0.35*(nx < ny))

    mnu_xwindow_autorun, instance, topname='sdi2k_top'
    
;---Return if we already have an instance running:
    wid_pool, 'SDI program - Exposure: Chord', widx, /get
    if widget_info(widx, /valid_id) then begin
       return
    endif

;---Create the exposure meter:
    wtitle = 'SDI Program - Exposure: Chord'
    wid_pool, 'sdi2k_top', widx, /get
    wid_pool, instance.description, sidx, /get
    top = WIDGET_BASE(title=wtitle, /column, group=sidx)
    expmet = widget_slider(top, xsize=280, title="Exposure Percent")
;---Register the plot xwindow name and top-level widget index with "wid_pool":
    wid_pool, 'chord_exposure_slider', expmet, /add
    wid_pool, 'SDI Program - Exposure: Chord', top, /add
    widget_control, top, /realize
    widget_control, top, set_uvalue={s_expm, wtitle: wtitle}
end

;==========================================================================================
; This is the (required) class method for creating a new instance of the sdi2k_prog_chord object. It
; would normally be an empty procedure.  Nevertheless, it MUST be present, as the last procedure in 
; the methods file, and it MUST have the same name as the methods file.  By calling this
; procedure, the caller forces all preceeding routines in the methods file to be compiled, 
; and so become available for subsequent use:

pro sdi2k_prog_chord
end

