#    GameSwipeDetector.gd
#
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

extends Area2D

const SwipeShape = preload("res://subscenes/SwipeShape.tscn")
const SavedTileCounter = preload("res://helpers/SavedTileCounter.gd")

enum SwipeState {IDLE, SWIPE = 5, DRAG}		# how should _input_event respond
var clicked_this_piece_type = 0				# set when swipe is started
var swipe_mode= false						# if true, then we are swiping
var swipe_array = []						# the pieces in the swipe
var swipe_shape = null					# will animate shape user swiped
var saved_tiles          # show on screen
var correct_swipe_counter       # count toward stars
var saved_tile_counter          # count toward win
var Game									# will point to GameNode
var swipe_state = SwipeState.SWIPE
var dragging_piece = null					# when dragging a piece, this will refer to it
var no_swipe_die_bool = false   # if true, we check if swipes remain.  Set true by Game if no more pieces available

func _ready():
    # Called every time the node is added to the scene.
    # Initialization here
    pass

func startLevel(current_level):
    self.saved_tiles = 0	# increase saved_tiles to beat level
    self.correct_swipe_counter = 0  # compare to swipe requirements to determine number of stars (1-3)
    self.saved_tile_counter = self.SavedTileCounter.new()
    self.saved_tile_counter.assess_required_tiles(current_level)


# this handles dragging pieces and orphaned swipes
func _on_GameSwipeDetector_input_event( viewport, event, shape_idx ):
    match swipe_state:
        SwipeState.IDLE:
            pass
        SwipeState.SWIPE:
            _on_GSD_swipe_event(event)
        SwipeState.DRAG:
            _on_GSD_drag_event(event)

func _on_GSD_swipe_event(event):
    if event is InputEventMouseButton:
        if event.button_index == 1:
            if !event.pressed:
                piece_unclicked()

func _on_GSD_drag_event(event):
    # allows drag to happen quickly
    dragging_piece.position = get_viewport().get_mouse_position()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func piece_clicked(position, piece_type):
    if swipe_array.size() == 1:
        # probably a duplicate click
        return
    clicked_this_piece_type = piece_type
    VisibleSwipeOverlay.set_swipe_color(TileDatabase.tiles[piece_type].ITEM_COLOR)
    swipe_state = SwipeState.SWIPE
    swipe_array.append(position)
    Helpers.board[position].highlight()		# tell Piece to appear as if it is swiped

func piece_unclicked():
    # make sure the swipe is long enough to count (per level basis)
    if swipe_array.size() < Game.current_level.min_swipe_len:
        for pos in swipe_array:
            Helpers.board[pos].unhighlight()
    # the swipe is long enough
    else:
        if Helpers.debug_level > 0:
            ShapeShifter.givenSwipe_showArray(swipe_array)
        var swipe_name = ShapeShifter.givenSwipe_lookupName(swipe_array)

        var dimensions = ShapeShifter.getSwipeDimensions(swipe_array)
        # figure out if the swipe is required
        var swipe_was_required = Game.game_hud.star_reqs.swiped_piece(swipe_name)

        swipe_shape = SwipeShape.instance()
        swipe_shape.set_shape(ShapeShifter.getBitmapOfSwipeCoordinates(swipe_array),clicked_this_piece_type)
        swipe_shape.set_position(Helpers.slot_to_pixels(dimensions["topleft"]))
        swipe_shape.set_text_word(SwipeWords.random_word(swipe_array.size()))
        add_child(swipe_shape)
        if swipe_was_required:
            var swipe_length = swipe_array.size()
            if(swipe_length > 12):
                swipe_length = 12           # ain't no sound for > 12
            SoundManager.play_se("Swipe " + String(swipe_length))
            swipe_shape.connect("shrunk_shape",self,"shrank_required_shape")
            # after swipe, move shape to correct/required shape location
            swipe_shape.shrink_shape(Game.game_hud.star_reqs.required_swipe_location(swipe_name),G.shrink_shape_duration)
            self.correct_swipe_counter = self.correct_swipe_counter + 1
        else:
            swipe_shape.connect("flew_away", self, "inc_saved_tile_counter")
            swipe_shape.fly_away_randomly(G.random_flight_duration)

        self.saved_tiles = self.saved_tiles + swipe_array.size()  # eventually only use save_tile_counter
        # this line determines if we won, but only after shape shrinks and inc_saved_tile_counter() calls Game._on_LevelWon()
        self.saved_tile_counter.saved_n_tiles_of_type(swipe_array.size(), clicked_this_piece_type)
        # will update HUD after shape shrinks and inc_saved_tile_counter() calls Game.game_hud.clarify_requirements()
        Game.game_hud.saved_n_tiles_of_type(swipe_array.size(), clicked_this_piece_type)  # Update only HUD
        # TODO add animation swipe_shape.animate()
        for pos in swipe_array:
            if Helpers.board[pos] != null:
                Helpers.board[pos].unhighlight()  # restore color so the effect is pretty.  Only needed while the highlight is black
                Helpers.board[pos].remove_yourself()
    swipe_array.clear()
    swipe_state = SwipeState.IDLE
    Helpers.search_for_swipes()   # there might be a race condition re magnetism_called

######################################
#
#  Called when user starts dragging a piece.
func piece_being_dragged(piece):
    dragging_piece = piece
    swipe_state = SwipeState.DRAG

# not sure if this should put the piece in the slot or Game.  At this point Game does it though
func piece_done_dragged(slot):
    print("piece done dragged to ", slot)
    swipe_state = SwipeState.IDLE
    dragging_piece = null

func inc_saved_tile_counter():
    print("inc_saved_tile_counter is kinda mis-named as the counts are decreased on Game HUD")
    print("Have game hud clarifying requirements now that shape swipe motion is complete")
    Game.game_hud.clarify_requirements()
    if self.saved_tile_counter.saved_enough_tiles_bool():
        print("sweet as we won the game by saving tiles")
        Game._on_LevelWon()   ## TODO use signal instead of call private function in Game
    else:
        # didnt win; see if we can lose
        see_if_swipes_remain()

func no_more_pieces_available():
    print("Now swipe detector will kill level unless a swipe exists")
    no_swipe_die_bool = true

func see_if_swipes_remain():
    if(no_swipe_die_bool):
      print("Game Swipe Detector checking if swipes remain")
      Game.die_unless_swipe_exists()  ## TODO use signal instead of call private function in Game?

func piece_entered(position, piece_type):
    if swipe_state != SwipeState.SWIPE:
        return
    if clicked_this_piece_type != piece_type:
        return
    # ensure the position is adjacent to the last item in the array
    if not adjacent(swipe_array.back(), position):
        return
    if position == swipe_array[swipe_array.size()-2]:
        # we back tracked
        var old_last = swipe_array.back()
        swipe_array.pop_back()
        Helpers.board[old_last].unhighlight()
    else:
        swipe_array.append(position)
        Helpers.board[position].highlight()		# tell Piece to appear as if it is swiped
    VisibleSwipeOverlay.draw_this_swipe(swipe_array,TileDatabase.tiles[piece_type].ITEM_COLOR)

func adjacent(pos1, pos2):
    # https://www.gamedev.net/forums/topic/516685-best-algorithm-to-find-adjacent-tiles/?tab=comments#comment-4359055
    var xOffsets = [ 0, 1, 0, -1]
    var yOffsets = [-1, 0, 1,  0]

    var i = 0
    var offset_pos2 = Vector2(-99,-99)
    while i < xOffsets.size():
        offset_pos2 = Vector2(pos2.x + xOffsets[i], pos2.y + yOffsets[i])
        if pos1 == offset_pos2:
            return true
        i = i + 1
    return false

func piece_exited(position, piece_type):
    # mouse moved out of a tile
    # but we only care if it moved into a tile
    pass

func shrank_required_shape():
    swipe_shape.queue_free()
    inc_saved_tile_counter()    # count required swipes toward total tiles collected
