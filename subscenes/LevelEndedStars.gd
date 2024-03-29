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

extends Node2D

var game_scene
var _todo_after_level
var _info_for_star_calc
var _unlocked_tile
var _need_remove_unlock_button = false
export var swipe_lose_delay = 0.05
export var gain_points_per_swipe = 1
export var points_per_tile = 25
export var pause_b4_show_stuff_s = 0.05
export var pause_af_show_stuff_s = 0.05
export var show_unlock_button_s = 2 * G.ofaster

#######################################################
#
#   So  when finished, we know who we're gonna call
func set_game_scene(my_game_scene):
    game_scene = my_game_scene

func _ready():
    # Called every time the node is added to the scene.
    _hide_everything()

func _hide_everything():
    print("Hiding everything")
    $UnlockedTileButton.hide()
    $LevelScore.hide()

func _hide_score_then_do_next():
    print("Hiding score")
    $LevelScore.hide()
    self._pause_after_show_stuff()  # simulate calling after animation complete

func _hide_level_and_star_reqs():
    print("Hiding swipes (just hide them sans ceremony because user failed)")
    game_scene.game_hud.remove_all_requirements()
    self._pause_after_show_stuff()  # simulate calling after animation complete

#######################################################
#
#  	Public so it can be called by Game.gd
func show_stuff_after_level(info_for_star_calculation):
    $LevelScore.show()
    self._info_for_star_calc = info_for_star_calculation
    self._decide_what_to_show()
    self._show_stuff_after_level()

#######################################################
#
#  	This will determine what to display, and in what order
func _decide_what_to_show():
    self._todo_after_level = []
    if self._info_for_star_calc['reason'] == G.LEVEL_WIN:
        self._PlanToDisplayBonus()		# put score on screen so we can edit it
        self._PlanToReduceSwipes()		# these three can be in any order
        self._PlanToReduceTiles()		# these three can be in any order (this one blacks out the tiles)
        self._PlanToAddTimeRemain()		# these three can be in any order
        self._PlanToDisplayStars()		# add stars below score (or above) or whatever, but should be last
        if self._info_for_star_calc['unlock_after_win'] != null:
            self._PlanToShowUnlockedTile(self._info_for_star_calc['unlock_after_win'])
    else:
        # this will black out the tiles, but *not* show score because score will not be there
        self._PlanToHideScore()
        self._PlanToHideRequirements()
        self._PlanToReduceTiles()

func _PlanToDisplayBonus():
    self._todo_after_level.push_back(G.STAR_DISPLAY_BONUS)

func _PlanToHideScore():
    ### this did  not exist but make it work by creating CONST or whatever
    ### will remove score after fail level
    self._todo_after_level.push_back(G.LEVEL_LOST_HIDE_SCORE)

func _PlanToHideRequirements():
    ### this was commented out but make it work by creating CONST or whatever
    ### will remove the swipe requirements after fail level
    self._todo_after_level.push_back(G.STAR_HIDE_REQUIREMENTS)

func _PlanToReduceSwipes():
    self._todo_after_level.push_back(G.STAR_REDUCE_SWIPES)

func _PlanToReduceTiles():
    self._todo_after_level.push_back(G.STAR_REDUCE_TILES)

func _PlanToAddTimeRemain():
    self._todo_after_level.push_back(G.STAR_ADD_TIME_REMAIN)

func _PlanToDisplayStars():
    self._todo_after_level.push_back(G.STAR_DISPLAY_STARS)

func _PlanToShowUnlockedTile(unlocked_tile):
    self._unlocked_tile = unlocked_tile     # string will find image filename
    self._todo_after_level.push_back(G.SHOW_UNLOCKED_TILE)

func _pause_before_show_stuff():
    var timer = $extra_pauser
    timer.connect("timeout",self,"_show_stuff_after_level")
    timer.set_wait_time(self.pause_b4_show_stuff_s)
    timer.start()

###  this is designed to slow the action so I can see what is happening
func _pause_after_show_stuff():
    print("PAUSE after show stuff")
    var timer = $extra_pauser
    timer.connect("timeout",self,"_show_stuff_after_level")
    timer.set_wait_time(pause_af_show_stuff_s)
    timer.start()

func _show_stuff_after_level():
    if not self._todo_after_level.size():
        self._on_last_star_displayed()	# fake emit
    else:
        var do_this_next = self._todo_after_level.pop_front()
        match do_this_next:
            G.STAR_HIDE_REQUIREMENTS:
                self._hide_level_and_star_reqs()    # Calls GameHUD to just reset all the requirements  (hopefully hides them all)
            G.LEVEL_LOST_HIDE_SCORE:
                self._hide_score_then_do_next()
            G.STAR_DISPLAY_BONUS:
                self._display_bonus()
            G.STAR_REDUCE_SWIPES:
                self._reduce_swipes()
            G.STAR_REDUCE_TILES:
                self._reduce_tiles()
            G.STAR_ADD_TIME_REMAIN:
                self._add_time_remain()
            G.STAR_DISPLAY_STARS:
                self._display_stars()
            G.SHOW_UNLOCKED_TILE:
                self._show_unlocked_overlay(self._unlocked_tile)  # send parameter in case _show_unlocked_overlay is moved to another object

func _display_bonus():
    print("Display Bonus")
    var points = get_node("LevelScore")
    var sound_duration = 4.0 # seconds
    var update_score_every = 0.05 # seconds
    var update_score_nan_kai = sound_duration / update_score_every
    SoundManager.play_se("Score count up")
    points.connect("qty_reached",self,"_pause_after_show_stuff")
    points.set_delay(update_score_every)
    var bonus_target = self._info_for_star_calc['num_tiles'] * self.points_per_tile
    points.set_target(bonus_target)	# tell spinner where to stop
    points.set_increment(ceil(bonus_target / update_score_nan_kai))	# take update_score_nan_kai steps to count
    points.start_tick_from(0)		# Start from 0 so null requirements level can be won.  Calls back to _displayed_quantity when finished

func _reduce_swipes():
    print("Reduce Swipes")
    var points = get_node("LevelScore")
    var bonus_reduction = self._info_for_star_calc['safe_tiles'] * self.gain_points_per_swipe
    print("win ", bonus_reduction, " points")
    points.set_delay(self.swipe_lose_delay)
    points.set_target_increase(bonus_reduction)
    points.set_increment(self.gain_points_per_swipe)

    var tiles_saved = game_scene.game_hud.saved_tiles
    tiles_saved.set_delay(self.swipe_lose_delay)
    tiles_saved.set_target(0)
    tiles_saved.set_increment(1)
    tiles_saved.start_tick()
    tiles_saved.hide()          # This is in top left corner, but looks bad so remove.  Fixes https://github.com/thunderrabbit/conswi/issues/89
    points.start_tick()

func _show_unlocked_overlay(local_unlocked_tile):
    print("YOU UNLOCKED ", local_unlocked_tile)
    $UnlockedTileButton.set_normal_texture(load("res://images/level_over/unlocked/unlocked_%s.png" % [local_unlocked_tile] ))
    $UnlockedTileButton.show()
    self._need_remove_unlock_button = true
    var timer = get_tree().create_timer(self.show_unlock_button_s)
    timer.connect("timeout",self,"_timeout_unlocked_button")

#####################################################
#
#  The plan is to always call this one, which will
#  display the score reduction due to remaining tiles and
#  have the bonus (spaghetti) side effect of telling
#  the tiles to remove themselves, one at a time.
#  If the score is not displayed, it will just remove tiles.
#
#  I am putting the code here to hopefully keep it simple
#  to keep the score reduction synced with tile removal
func _reduce_tiles():
    print("Reduce Tiles")
    var existing_sprites = get_tree().get_nodes_in_group("players")
    print("remaining pieces: ", existing_sprites.size())
    self._pause_after_show_stuff()  # simulate calling after animation complete

func _add_time_remain():
    print("Add Time Remain")
    self._pause_after_show_stuff()  # simulate calling after animation complete

###
# not really thought out, but this will be called if G.STAR_DISPLAY_STARS is in self._todo_after_level
func _display_stars():
    var num_stars = _calculate_stars_for_level()
    print("About to display this many stars: ", num_stars)
    for i in range(1,num_stars):
        print("placeholder create star ",i)
        # instantiate Tile of type TYPE
        # if this is last star, tell it to emit _on_last_star_displayed() callback when finished flying
        # fly it into place
        pass
    self._pause_after_show_stuff()  # simulate calling after animation complete

#######################################################
#
#  	This will be private to the GD star_display.gd
#   Swiping level-specific shapes will determine the number of stars.
func _calculate_stars_for_level():
    print(self._info_for_star_calc)
    var count_correct_swipes = 1.0 * self._info_for_star_calc['correct_swipes']  # as a float so the division creates a float
    var count_required_swipes = 1.0 * self._info_for_star_calc['required_swipe_count']
    var ratio_of_stars_collected = count_correct_swipes / count_required_swipes
    var num_stars = 0
    if(ratio_of_stars_collected >= 1.0/3.0):
        num_stars = 1
    if(ratio_of_stars_collected >= 2.0/3.0):
        num_stars = 2
    if(ratio_of_stars_collected >= 3.0/3.0):
        num_stars = 3
    print("ratio of stars collected = ", ratio_of_stars_collected)
    print("num_stars = ", num_stars)
    Savior.save_num_stars(G.TYPE_DOG, self._info_for_star_calc['level'], num_stars)
    return num_stars

func _on_last_star_displayed():
    self.game_scene._on_level_over_stars_displayed()		# fake signal emitted by star_display.gd

###  allow button to timeout, including code to prevent race conditions with click
func _timeout_unlocked_button():
    print("timed out button")
    if(self._need_remove_unlock_button == false):
        # button has already been pressed
        return
    self._need_remove_unlock_button = false
    $UnlockedTileButton.hide()
    print("_pause_after_show_stuff after timed out button")
    self._pause_after_show_stuff()  # simulate calling after animation complete

###  allow button to be clicked, including code to prevent race conditions with timeout
func _on_UnlockedTileButton_down():
    print("clicked button")
    if(self._need_remove_unlock_button == false):
        # button has already timed out
        return
    self._need_remove_unlock_button = false
    $UnlockedTileButton.hide()
    print("_pause_after_show_stuff after clicked button")
    self._pause_after_show_stuff()  # simulate calling after animation complete
