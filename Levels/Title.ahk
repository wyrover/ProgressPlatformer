#NoEnv

/*
Copyright 2011 Anthony Zhang <azhang9@gmail.com>

This file is part of ProgressPlatformer. Source code is available at <https://github.com/Uberi/ProgressPlatformer>.

ProgressPlatformer is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

Notes := new NotePlayer(9)

Notes.Repeat := 1

Notes.Note(40,1000,70).Note(48,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
Notes.Note(40,1000,70).Note(48,1000,70).Delay(2000)
Notes.Note(40,1000,70).Note(45,1000,70).Delay(1800)

Notes.Delay(300)

Notes.Note(41,1000,70).Note(48,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(48,1000,70).Delay(2000)
Notes.Note(41,1000,70).Note(45,1000,70).Delay(1800)

Notes.Delay(500)

Notes.Play()

Game.Layers[1] := new ProgressEngine.Layer
Game.Layers[2] := new ProgressEngine.Layer
Environment.Snow(Game.Layers[1])
Game.Layers[1].Entities.Insert(new TitleText("Achromatic"))
Game.Layers[1].Entities.Insert(new TitleMessage("Press Space to begin"))
Game.Start()
Game.Layers := []

Notes.Stop()