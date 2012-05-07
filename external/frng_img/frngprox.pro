;========================================================================
;
; This file contains various subroutines used to fit a model Fabry-Perot
; fringe pattern to a 2-dimensional fringe image recorded by a non-scanned
; imaging FPS.

;========================================================================
; This procedure creates a data structure (php) to contain the fringe fit
; parameters, and initializes its fields to nominal values:

pro frnginit, php, nx, ny, center=center, censtep=censtep, $
                           mag=mag,       mgstep=magstep, $
                           warp=warp,     wpstep=wpstep, $
                           phisq=phisq,   pstep=phistep, $
                           zerph=zerph,   zrstep=zerstep, $
                           ordwin=ordwin, R=R, lambda=lambda, $
                           xcpsave=xcpsave


if not(keyword_set(center))   then center   = [nx/2., ny/2.]
if not(keyword_set(censtep))  then censtep  = 0.01*center
if not(keyword_set(mag))      then mag      = [0.01, 0.01, 0.0001]
if not(keyword_set(magstep))  then magstep  = 0.01*mag
if not(keyword_set(warp))     then warp     = [0.0, 0.0]
if not(keyword_set(wpstep))   then wpstep   = [0.001, 0.001]
if not(keyword_set(phisq))    then phisq    = 0.0
if not(keyword_set(phstep))   then phstep   = 0.0001
if not(keyword_set(zerph))    then zerph    = 0.5
if not(keyword_set(zrstep))   then zrstep   = 0.01
if not(keyword_set(ordwin))   then ordwin   = [0.0, 5.1]
if not(keyword_set(lambda))   then lambda   = 630.03e-9
if not(keyword_set(R))        then R        = 0.7
if not(keyword_set(xcpsave))  then xcpsave  = 'NO'



  php = {s_php, xcen:     center(0),     $
                xcstp:    censtep(0),    $
                ycen:     center(1),     $
                ycstp:    censtep(1),    $
                xwarp:    warp(0),       $
                xwstp:    wpstep(0),     $
                ywarp:    warp(1),       $
                ywstp:    wpstep(1),     $
                nx:       nx,            $
                ny:       ny,            $
                xmag:     mag(0),        $
                xmstp:    magstep(0),    $
                ymag:     mag(1),        $
                ymstp:    magstep(1),    $
                xymag:    mag(2),        $
                xymstp:   magstep(2),    $
                phisq:    phisq,         $
                phistp:   phstep,        $
                zerph:    zerph,         $
                zerstp:   zrstep,        $
                resfac:   1.,            $
                xsize:    0.,            $
                ysize:    0.,            $
                delord:   ordwin(1) - ordwin(0),         $
                minord:   ordwin(0),     $
                fplot:    0,             $
                xcpsave:  xcpsave,       $
                lambda:   630.03,        $
                R:       R                }
   php.xsize = nx
   php.ysize = ny


 end


pro frng_fit, fringe_img, php, culz, skip_rough=skip_rough, progress=progress
;   First, do some fitting to a lower resolution version of the image.  This allows
;   the initial "rough searching" to proceed much faster:
    job0 = ['zerph', '20']
    job1 = ['zerph', '8']
    job1 = [[job1],  ['xcen',   '8']]
    job1 = [[job1],  ['ycen',   '8']]
    job1 = [[job1],  ['xmag',   '8']]
    job1 = [[job1],  ['ymag',   '8']]  ;######
    job1 = [[job1],  ['xymag',  '8']]
    job1 = [[job1],  ['xwarp',  '8']]
    job1 = [[job1],  ['ywarp',  '8']]
    job1 = [[job1],  ['phisq',  '8']]
    job2 = ['zerph', '8']
    job2 = [[job2],  ['xcen',   '6']]
    job2 = [[job2],  ['ycen',   '6']]
    job2 = [[job2],  ['xmag',   '6']]
    job2 = [[job2],  ['ymag',   '6']]   ;#########
    job2 = [[job2],  ['xymag',  '6']]
    job2 = [[job2],  ['xwarp',  '6']]
    job2 = [[job2],  ['ywarp',  '6']]
    job2 = [[job2],  ['phisq',  '6']]

    job3 = ['zerph', '8']

    if keyword_set(progress) then begin
       progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Fitting...')
       progressBar->Start
    endif

    pbase = 0
    pinc = 12.5

    if not(keyword_set(skip_rough)) then begin
       pbase = 42
       pinc  = 7.25
       frng_setres, fringe_img, img, php, 0.70
       if keyword_set(progress) then progressbar->update, 0
       imgfit, img, php, job0, culz
       if keyword_set(progress) then progressbar->update, 4
       imgfit, img, php, job1, culz
       if keyword_set(progress) then progressbar->update, 10
       imgfit, img, php, job2, culz
       frng_setres, fringe_img, img, php, 0.80
       if keyword_set(progress) then progressbar->update, 16
       imgfit, img, php, job1, culz
       if keyword_set(progress) then progressbar->update, 22
       imgfit, img, php, job2, culz
       if keyword_set(progress) then progressbar->update, 30
       imgfit, img, php, job1, culz
       frng_setres, fringe_img, img, php, 0.90
       if keyword_set(progress) then progressbar->update, 36
       imgfit, img, php, job1, culz
       if keyword_set(progress) then progressbar->update, 42
       imgfit, img, php, job2, culz
    endif

    frng_setres, fringe_img, img, php, 1.0
    if keyword_set(progress) then progressbar->update, pbase
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 1*pinc
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 2*pinc
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 3*pinc
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 4*pinc
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 5*pinc
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 6*pinc
    imgfit, img, php, job2, culz
    if keyword_set(progress) then progressbar->update, pbase + 7*pinc
    imgfit, img, php, job3, culz


    if keyword_set(progress) then begin
       progressBar->Destroy
       Obj_Destroy, progressBar
    endif

end

;========================================================================
; This procedure executes a series of fitting tasks, defined by the
; array "jobs".

pro imgfit, img, php, jobs, culz
for j = 0, n_elements(jobs(0, *)) - 1 do begin
    get_tagnum, php, jobs(0, j), znum ; Get the tag number of the j-th job parameter
    if php.(znum+1) gt 0 then begin   ; Only fit it if the stepsize is gt 0
       repeat begin
              parname  = jobs(0, j)
              parsteps = fix(jobs(1, j))
              frng_pft, img, php, parname, parsteps, culz, status
              get_tagnum, php, parname, znum
              stepsize   = php.(znum+1)
			  if status ge 0 then begin
                 php.(znum+1) = abs((0.5 + 1.0*status)*stepsize)
              endif else begin
                 php.(znum+1) = abs(1.7*stepsize)
              endelse
       endrep until status ge 0
    endif
endfor
end

;========================================================================
; This procedure finds the best choice for one parameter in the fringe
; model - within a search range defined by the "stepsize" and "nsteps"
; values passed in.

pro frng_pft, img, php, parname, nsteps, culz, status
    wait, 0.0001
    wintit = "Par: " + parname + " (" + $
             strcompress(string(fix(100*php.resfac)), /remove_all) +  "%)"
    if php.fplot then window, 0, xsize=php.nx, ysize=php.ny, xpos=2, ypos=2, title=wintit
    get_tagnum, php, parname, znum

    stepsize   = php.(znum+1)
    phq        = php
    parbase    = phq.(znum) - stepsize*nsteps/2.
    crosscor   = fltarr(nsteps+1)
    corx       = fltarr(nsteps+1)

    for j = 0,nsteps do begin
        phq.(znum) = parbase + stepsize*float(j)
        get_xcorr, xcorr, img, phq, culz, area=area ;############
        crosscor(j) = xcorr/area  ;###########
        corx(j)     = phq.(znum)
    endfor
    ccr = crosscor
    bx = where(crosscor eq max(crosscor))
    bx = bx(0)

    if bx gt 0 and bx lt nsteps then begin
       bstep      = 0.5*(crosscor(bx-1) - crosscor(bx+1))/(crosscor(bx-1) - 2.*crosscor(bx) + crosscor(bx+1))
       php.(znum) = parbase + stepsize*(bx+bstep)
       status     = abs(bx - nsteps/2.)/(nsteps/2.)
    endif else begin
       php.(znum) = parbase + stepsize*bx
       status     = -1
    endelse

    ccr = ccr/max(ccr)
    if php.fplot eq 1 then begin
       if (php.xcpsave ne 'NO' and $
           parname     eq 'zerph' and $
           n_elements(ccr) gt 12) then begin
           window, 5, xsize=1100, ysize=800, xpos=100, ypos=50, title="Fit Diagnostic Plot"
           erase, color=culz.white
           xr = [0.1*fix(min(corx)/0.1), 0.1*fix(1+max(corx)/0.1)]
           plot, corx, ccr, $
                 xtitle='!6Fractional !8m!6!D0!N!3', ytitle='!6Normalized!C!6Cross-Correlation!3', $
                /xstyle, /ystyle, yminor=2, color=culz.black, $
                /noerase, xthick=3, ythick=3, thick=4, charthick=3, charsize=3.5, $
                xrange = xr, yrange=[0.6,1.1], ytickformat='(f3.1)'
           oplot, [php.(znum), php.(znum)], [0.6, 1.1], color=culz.black, thick=4, linestyle=2
           gif_this, file=php.xcpsave
           wait, 1
           wdelete, 5
       endif else begin
           window, 5, xsize=500, ysize=400, xpos=0, ypos=500, title="Fit Diagnostic Plot"
           if min(ccr) ne max(ccr) then begin
	      plot, corx, ccr, $
	            title="Cross Correlation: " + parname, xtitle=parname, ytitle='Normalized!CCross-Correlation', $
		   /xstyle, /ystyle, yminor=2, color=culz.white, $
		   /noerase, xthick=2, ythick=2, thick=2, charthick=2, charsize=1.2, $
		    xticks=4, ytickformat='(f3.1)', /nodata
	      oplot, corx, ccr, color=culz.yellow, thick=2
	      oplot, [php.(znum), php.(znum)], [min(ccr), max(ccr)], color=culz.red, thick=3, linestyle=2
           endif
       endelse
       empty
    endif
end



;========================================================================
; This procedure returns the tag number for the tag in structure "php"
; whose name matches that given by "key"

pro get_tagnum, php, key, nbr
    nbr   = -1
    namz  = strupcase(tag_names(php))
    for j = 0, n_elements(namz) -1 do begin
        if strpos(namz(j), strupcase(key)) eq 0 then nbr = j
    endfor
end


;========================================================================
; This function returns the nearest integer to "floatin".
function nint, floatin
   nint    = long(floatin)
   chopper = floatin - nint
   if chopper gt 0.5 then nint = nint+1
   if abs(nint) lt 32768l then nint = fix(nint)
   return, nint
end

;========================================================================
; This procedure is used to modify the resolution of the fit.

pro frng_setres, refim, img, php, resfac

  modfac     = resfac/php.resfac
  php.resfac = resfac

  get_tagnum, php, 'ycstp', znum
  for j = 0,znum do begin
     php.(j) = php.(j)*modfac
  endfor
  get_tagnum, php, 'ywstp', znum
  get_tagnum, php, 'xymstp', ynum
  for j = znum+1,ynum do begin
     php.(j) = php.(j)/(modfac^2)
  endfor

  fnx    = resfac*php.xsize
  fny    = resfac*php.ysize
  php.nx = nint(fnx)
  php.ny = nint(fny)

  img = congrid(refim, php.nx, php.ny, /interp)
end


;========================================================================
; This procedure generates a Fabry-Perot fringe pattern defined
; parameters in the structure "php".

pro fringemap, fringes, pmap, php, field_stop

;   Determine the range of orders to be used:
    nout       = 0
    if php.minord ge 0. then begin
       maxord  = php.minord+php.delord
    endif else begin
       maxord = php.delord
    endelse

;   Warping also shifts the apparent center of the fringes - make a crude correction
;   for that:
    shiftcoef = 0.5/sqrt(maxord/(0.5*php.xmag+0.5*php.ymag))
    shiftcoef = 0.

    xx   = transpose(lindgen(php.ny,php.nx)/php.ny) - (php.xcen - php.xwarp*shiftcoef)
    yy   = lindgen(php.nx,php.ny)/php.nx            - (php.ycen - php.ywarp*shiftcoef)
    xx   = xx + php.xwarp*abs(xx)
    yy   = yy + php.ywarp*abs(yy)

;    pmap = php.xmag*xx*xx + php.ymag*yy*yy + php.xymag*xx*yy
    pmap = php.xmag*xx*xx + php.ymag*yy*yy + php.xymag*xx*yy

    pmap = (pmap + php.phisq*pmap*pmap)
    if php.lambda ne 630.03 then pmap = pmap*(630.03/php.lambda)

;   Create a mask describing all points within the desired number of orders of the axis:
    field_stop = where(pmap lt maxord and pmap gt php.minord, nout)

    pmap    = (php.zerph - pmap)*!pi
    fringes = sin(pmap)
    fringes = 1./(1 + (4*php.R/(1. - php.r^2))*fringes*fringes)
    fringes = fringes - min(fringes)
    fringes = fringes/max(fringes)

end

;========================================================================
; This procedure returns the cross-correlation between "img" and a
; Fabry-Perot fringe pattern defined by parameters in the structure "php".

pro get_xcorr, xcorr, img, php, culz, power=power, area=ntop
    fringemap, fringes, pmap, php, field_stop
    if keyword_set(power) then fringes=(abs(fringes))^power
    cutoff = 0.5
    view  = culz.imgmin + bytscl(img, top=culz.imgmax-culz.imgmin)
    seen  = view(field_stop)
    used  = fringes(field_stop)
    ntop  = 0
    tops  = where(used gt cutoff, ntop)
    xcorr = total(    fringes(field_stop)*(img(field_stop) - min(img(field_stop))   ))
    if php.fplot eq 1 then begin
       seen(tops) = culz.greymin + (culz.greymax - culz.greymin)*(used(tops) - cutoff + 0.09)/(1.1 - cutoff)
       view(field_stop) = seen
       if strupcase(!d.name) ne 'Z' then begin
          wset, 0
          tv, view
          empty
       endif
    endif
end

; Now make spectrum spanning "nchan" channels using the fitted fringe pattern:

pro frng_spx, refim, img, php, nchan, ordwin, r, culz, spectrum, tstamp = tstamp, zerph=zerph, scan_range=scan_range
  if not(keyword_set(tstamp))    then tstamp = ' ' else tstamp = ': ' + tstamp
  if not keyword_set(scan_range) then scan_range = 1.
  if not(keyword_set(zerph))     then zerph = php.zerph

  phsave = php
  php.r = r
  php.minord = ordwin(0)
  php.delord = ordwin(1) - ordwin(0)
  frng_setres, refim, img, php, 1.0
  if strupcase(!d.name) ne 'Z' then window, 0, xsize=php.nx, ysize=php.ny, xpos=2, ypos=2, title="Scanning..."
  spectrum   = fltarr(scan_range*nchan)

  for j=0,scan_range*nchan-1 do begin
      zinc       = (float(j) - nchan/2.)/nchan
;      php.minord = php.minord + 1./float(nchan)
      php.zerph  = zerph + zinc
      get_xcorr, xcorr, img, php, culz, power=4, area=area
      spectrum(j) = xcorr/(float(area>1))
      wait, 0.0001
  endfor

  if strupcase(!d.name) ne 'Z' then begin
     window, 2, xsize=700, ysize=450, xpos=550, title='Spectrum Display'
     yrange = [max(spectrum) -  min(spectrum)]
     yrange = [min(spectrum), max(spectrum)] + [-0.05*yrange, .05*yrange]
     plot, spectrum, /xstyle, /ystyle, $
           thick=2, xthick=2, ythick=2, charthick=2, charsize=1.5, yrange=yrange, $
           title='Sampled 1-D Spectrum' + tstamp, xtitle='Channel Number', ytitle='Signal Counts', color=culz.white, /nodata
     oplot,spectrum, thick=2, color=culz.green
  endif
  php = phsave
  empty
end



