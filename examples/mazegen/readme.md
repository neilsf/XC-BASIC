# Mazegenerator

This XC-BASIC sample generates a fully solvable maze based on the
depth-first search algorhythm.

The original code was published in the book 
**Programming the Commodore 64 - The Definitive Guide**
written by Raeto Collin West (ISBN 0-942386-50-7).

This code was originally written by Oliver Hermanni on April, 1st 2019 (no joke).
You can find him on Twitter here: https://twitter.com/hamrath

### Speed comparision 
Here are a few results from different BASIC V2 compilers:

```
BASIC V2:           ~40sec
BASIC BOSS:         ~13.25sec
MOspeed:            ~12sec
Original XC-BASIC:  ~5.5sec
Optimized XC-BASIC: ~4.5sec
``` 

The difference between original and optimized XC-BASIC
are roughly 7 lines of code. The original code was an early
draft I won't release because of shame. ;)

BASIC BOSS is a 2-pass BASIC compiler from 1988.  

MOspeed is a new BASIC compiler from EgonOlsen71 written in Java.
You can find it here https://github.com/EgonOlsen71/basicv2.