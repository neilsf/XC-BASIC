rem ** put some code at address $c000 that ends with an rts **
rem ** prior to running this program **

const TESTADDR = 49152
sys TESTADDR
print "ml routine finished"