#    Level 4
#    Copyright (C) 2020 Rob Nugen
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

extends "DogLevel.gd"

func _init():
# Level 4
# playable pieces: dog, cat
    gravity_timeout = 0.88
    max_tiles_avail = 50
    tiles = { "dog":18, "cat":10 }    # this helps the ratios match required tiles
    time_limit_in_sec = 120
    star_requirements = {
                           "vertical4":1,
                           "horizontal4":1,
                           "horizontal5":1,
                        }
    required_tiles = { "dog":18, "cat":10 }
