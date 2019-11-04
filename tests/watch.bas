const RASTER = $d012
const RST8   = $d011
const BG     = $d020

loop:
    watch RASTER, 0
    if peek(RST8) >= 128 then goto loop
    poke BG, 2
    watch RASTER, 104 
    poke BG, 1
    watch RASTER, 208
    poke BG, 5
    goto loop