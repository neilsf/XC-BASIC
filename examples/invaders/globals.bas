const VIC_MEMSETUP = 53272
const SCREEN = 1024
const COLOR = 55296
const BORDER = 53280
const BACKGR = 53281
const RASTER_POS = $d012
const SPR_CNTRL = $d015
const VIC2_CNTR2 = $d016
const ENEMY_CHAR_START! = 96

const SPRITE0_SHAPE = 2040
const SPRITE1_SHAPE = 2041
const SPRITE2_SHAPE = 2042
const SPRITE3_SHAPE = 2043
const SPRITE4_SHAPE = 2044
const SPRITE5_SHAPE = 2045
const SPRITE6_SHAPE = 2046

const SPRITE1_X = $d000
const SPRITE1_Y = $d001

const SPRITE6_X = $d00c
const SPRITE6_Y = $d00d

const SPRITE6_COLOR = $d02d

const SPR_SPR_COLL = $d01e

const SID_FREQ1 = $d400
const SID_FREQ2 = $d407
const SID_FREQ3 = $d40e

const SID_PULSE1 = $d402
const SID_PULSE2 = $d409
const SID_PULSE3 = $d410

const SID_CNTRL1 = $d404
const SID_CNTRL2 = $d40b
const SID_CNTRL3 = $d412

const SID_AD1 = $d405
const SID_SR1 = $d406

const SID_AD2 = $d40c
const SID_SR2 = $d40d

const SID_AD3 = $d413
const SID_SR3 = $d414

const SID_VOLUME = $d418

dim enemy_map![60]
dim enemy_bullet_on![3]
dim enemy_bullet_posx[3]
dim enemy_bullet_posy![3]

scroll! = 0
enemy_posx! = 8
enemy_posy! = 0
bottom_row! = 13
enemy_dir! = 1

ship_pos = 176
bullet_on! = 0
bullet_posx = 0
bullet_posy! = 0

last_killed_enemy = 0
score = 0
addscore = 0
lives! = 3
level! = 1
speed! = 20
game_speed! = 20

enemies_alive! = 60
scroll_bottom_limit! = 202
enemy_map_length = 340

spos = 0

ufo_on! = 0
ufo_pos = 370
ufo_hit! = 0
framecount_ufo = 0

dim bottom_row_cached!
dim sound_phase!

data notes[] = 902, 955, 1012, 1072