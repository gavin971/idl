;*****************************************************************************
pro closeall,dum
for i=100,128 do free_lun,i
return
end
