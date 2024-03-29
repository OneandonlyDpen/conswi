#    Copyright (C) 2022  Rob Nugen
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#####################################################################################
#
#  Globals can be accessed with e.g. G.max_splash_screens, and are generally designed to hold constants
#
#####################################################################################

extends Node

const ofaster = 0.01    # multiply waits by G.ofaster

const finger_swipe_duration = 3 * ofaster		# how many seconds finger shows how to swipe
const shrink_reqd_duration = 0.9 * ofaster      # required shapes shrink to bottom of game screen
const shrink_shape_duration = 0.9 * ofaster     # swipes shrink to top of game screen
const random_flight_duration = 0.9 * ofaster    # spiraling into oblivions

#  How long does each splash screen last?   This array controls each one in sequence.
#  The zeroeth timeout is added to first time out in that the first image is changed after 0th + 1st timeouts finish
const splashscreen_timeouts = [2.18,2.18,3.18,2.18,2.18]		# how many seconds to wait on splash screen
const max_splash_screen_id  = 4		# there are several splash screens
var   current_screen = 0			# which screen to start

##  http://www.gamefromscratch.com/post/2015/02/23/Godot-Engine-Tutorial-Part-6-Multiple-Scenes-and-Global-Variables.aspx

func LeftSpace():
    return 20

func TopSpace():
    return 0

func SlotGapH():
    return 5

func SlotGapV():
    return 5

func GameGridSlotSize():
    return OneNthOfScreenWidth(Helpers.slots_across)

func OneNthOfScreenWidth(N):
    var os_window_width = OS.get_window_size().x
    var one_nth_of_screen = os_window_width / N
    return one_nth_of_screen

func Game_slot_size():
    return GameGridSlotSize()

func Game_left_space():
    return Game_slot_size() / 2

func Game_top_space():
    return Game_slot_size()


const MAX_STARS = 3				# per level, shown on level select screen; used by high score saver, Savior.gd

# arbitrarily ordered ways to win or lose a level
const LEVEL_WIN 		= 1
const LEVEL_NO_ROOM		= 2
const LEVEL_NO_TIME		= 3
const LEVEL_NO_TILES	= 4
const LEVEL_CANCELLED   = 5

# The order of these types must match items.png
const TYPE_PANDA		= 0
const TYPE_BEAR			= 1
const TYPE_COW			= 2
const TYPE_DOG			= 3
const TYPE_MONKEY		= 4
const TYPE_SHEEP		= 5
const TYPE_PIG			= 6
const TYPE_CAT			= 7
const TYPE_LION			= 8
const TYPE_RABBIT		= 9
const TYPE_TIGER		= 10
const TYPE_ZEBRA    = 11
const TYPE_LEOPARD  = 12
const TYPE_POLAR    = 13
const TYPE_SNAKE    = 14
const TYPE_HEART    = 15
const TYPE_GNU      = 16
const TYPE_APE      = 17
const TYPE_FOX      = 18
const TYPE_KIRIN    = 19
const TYPE_GOAT     = 20
const TYPE_KOALA    = 21
const TYPE_SAI      = 22
const TYPE_JOKER    = 23


const STAR_DISPLAY_BONUS = 0
const STAR_REDUCE_SWIPES = 1
const STAR_REDUCE_TILES = 2
const STAR_ADD_TIME_REMAIN = 3
const STAR_DISPLAY_STARS = 4
const STAR_HIDE_REQUIREMENTS = 7
const SHOW_UNLOCKED_TILE = 8
const LEVEL_LOST_HIDE_SCORE = 9

const Saved_Tiles_Anchor_Left = 0.9
const Saved_Tiles_Anchor_Top = 0.5

# Before each level, the required pieces are shown and then shrink as they move up to upper left.
# If the shrink location is 1, they will each take a single square worth of space
# At a shrink factor of 0.2, they fit within one space, but are too small for the player to see
# We probably need a whole better way to place them, but this works for now.
const REQ_SHAPE_SHRINK_FACTOR = 0.4			# required shapes become this big compared to normal
const REQ_SHAPE_SHRINK_LOCATION = 1.5		# required shapes display this many column widths apart
