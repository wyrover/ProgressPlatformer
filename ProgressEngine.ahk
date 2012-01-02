#NoEnv
;wip: error check the DllCall's
class ProgressEngine
{
    static ControlCounter := 0

    __New(hWindow)
    {
        this.Layers := []

        this.FrameRate := 30

        this.hWindow := hWindow
        this.hDC := DllCall("GetDC","UPtr",hWindow)
        If !this.hDC
            throw Exception("Could not obtain window device context.")

        this.hMemoryDC := DllCall("CreateCompatibleDC","UPtr",this.hDC)
        If !this.hMemoryDC
            throw Exception("Could not create memory device context.")

        If !DllCall("SetBkMode","UPtr",this.hMemoryDC,"Int",1) ;TRANSPARENT
            throw Exception("Could not set background mode.")
    }

    Start(DeltaLimit = 0.05)
    {
        ;calculate the amount of time each iteration should take
        If this.FrameRate != 0
            FrameDelay := 1000 / this.FrameRate

        TickFrequency := 0, PreviousTicks := 0, CurrentTicks := 0, ElapsedTime := 0
        If !DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
            throw Exception("Could not obtain performance counter frequency.")
        If !DllCall("QueryPerformanceCounter","Int64*",PreviousTicks) ;obtain the performance counter value
            throw Exception("Could not obtain performance counter value.")
        Loop
        {
            ;calculate the total time elapsed since the last iteration
            If !DllCall("QueryPerformanceCounter","Int64*",CurrentTicks)
                throw Exception("Could not obtain performance counter value.")
            Delta := (CurrentTicks - PreviousTicks) / TickFrequency
            PreviousTicks := CurrentTicks

            ;clamp delta to the upper limit
            If (Delta > DeltaLimit)
                Delta := DeltaLimit

            Result := this.Step(Delta)
            If Result
                Return, Result
            this.Update()

            ;calculate the time elapsed during stepping in milliseconds
            If !DllCall("QueryPerformanceCounter","Int64*",ElapsedTime)
                throw Exception("Could not obtain performance counter value.")
            ElapsedTime := ((ElapsedTime - CurrentTicks) / TickFrequency) * 1000

            ;sleep the amount of time required to limit the framerate to the desired value
            If (this.FrameRate != 0 && ElapsedTime < FrameDelay)
                Sleep, % Round(FrameDelay - ElapsedTime)
        }
    }

    Step(Delta)
    {
        For Index, Layer In this.Layers
        {
            For Key, Entity In Layer.Entities
            {
                Result := Entity.Step(Delta,Layer)
                If Result
                    Return, Result
            }
        }
        Return, 0
    }

    class Layer
    {
        __New()
        {
            this.Entities := []
            this.Visible := 1
            this.X := 0
            this.Y := 0
            this.W := 10
            this.H := 10
            this.ScaleX := 1
            this.ScaleY := 1
        }
    }

    Update()
    {
        global hBitmap
        static Width1 := -1, Height1 := -1
        ;obtain the dimensions of the client area
        VarSetCapacity(ClientRectangle,16)
        If !DllCall("GetClientRect","UPtr",this.hWindow,"UPtr",&ClientRectangle)
            throw Exception("Could not obtain client area dimensions.")
        Width := NumGet(ClientRectangle,8,"Int"), Height := NumGet(ClientRectangle,12,"Int")

        If (Width != Width1 || Height != Height1)
        {
            If this.hOriginalBitmap
            {
                If !DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr") ;deselect the bitmap
                    throw Exception("Could not select bitmap into the memory device context.")
            }
            this.hBitmap := DllCall("CreateCompatibleBitmap","UPtr",this.hDC,"Int",Width,"Int",Height,"UPtr") ;create a new bitmap
            this.hOriginalBitmap := DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hBitmap,"UPtr")
        }
        Width1 := Width, Height1 := Height

        For Index, Layer In this.Layers
        {
            If !Layer.Visible
                Continue
            ScaleX := (Width / Layer.W) * Layer.ScaleX
            ScaleY := (Height / Layer.H) * Layer.ScaleY
            For Key, Entity In Layer.Entities
            {
                ;get the screen coordinates of the rectangle
                CurrentX := Round((Layer.X + Entity.X) * ScaleX), CurrentY := Round((Layer.Y + Entity.Y) * ScaleY)
                CurrentW := Round(Entity.W * ScaleX), CurrentH := Round(Entity.H * ScaleY)

                Entity.Draw(this.hMemoryDC,CurrentX,CurrentY,CurrentW,CurrentH,Width,Height)
            }
        }
        DllCall("BitBlt","UPtr",this.hDC,"Int",0,"Int",0,"Int",Width,"Int",Height,"UPtr",this.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY
    }

    class Blocks
    {
        class Default
        {
            __New()
            {
                ObjInsert(this,"",Object())
                this.X := 0
                this.Y := 0
                this.W := 10
                this.H := 10
                this.hPen := 0
                this.hBrush := 0
                this.Visible := 1
                this.Color := 0xFFFFFF
                this.Physical := 0
            }

            Step(Delta,Layer)
            {
                
            }

            NearestEntities(Layer)
            {
                ;wip
            }

            Draw(hDC,PositionX,PositionY,Width,Height,ViewportWidth,ViewportHeight)
            {
                ;check for entity moving out of bounds
                If (PositionX + Width) < 0 || PositionX > ViewportWidth
                    || (PositionY + Height) < 0 || PositionY > ViewportHeight
                    Return

                ;update the color if it has changed
                If this.ColorModified
                {
                    If this.hPen
                        DllCall("DeleteObject","UPtr",this.hPen)
                    If this.hBrush
                        DllCall("DeleteObject","UPtr",this.hBrush)
                    this.hPen := DllCall("CreatePen","Int",0,"Int",0,"UInt",this.Color,"UPtr") ;PS_SOLID
                    this.hBrush := DllCall("CreateSolidBrush","UInt",this.Color,"UPtr")
                    this.ColorModified := 0
                }

                hOriginalPen := DllCall("SelectObject","UInt",hDC,"UPtr",this.hPen,"UPtr") ;select the pen
                hOriginalBrush := DllCall("SelectObject","UInt",hDC,"UPtr",this.hBrush,"UPtr") ;select the brush

                If this.Visible
                    DllCall("Rectangle","UPtr",hDC,"Int",PositionX,"Int",PositionY,"Int",PositionX + Width,"Int",PositionY + Height)

                DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",hOriginalPen,"UPtr") ;deselect the pen
                DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",hOriginalBrush,"UPtr") ;deselect the brush
            }

            MouseHovering(PositionX,PositionY,Width,Height) ;wip
            {
                CoordMode, Mouse, Client
                MouseGetPos, MouseX, MouseY
                If (MouseX >= PositionX && MouseX <= (PositionX + Width)
                    && MouseY >= PositionY && MouseY <= (PositionY + Height))
                    Return, 1
                Return, 0
            }

            Collide(Rectangle,ByRef IntersectX,ByRef IntersectY)
            {
                Left1 := this.X, Left2 := Rectangle.X
                Right1 := Left1 + this.W, Right2 := Left2 + Rectangle.W
                Top1 := this.Y, Top2 := Rectangle.Y
                Bottom1 := Top1 + this.H, Bottom2 := Top2 + Rectangle.H

                ;check for collision
                If (Right1 < Left2 || Right2 < Left1 || Bottom1 < Top2 || Bottom2 < Top1)
                {
                    IntersectX := 0, IntersectY := 0
                    Return, 0 ;no collision occurred
                }

                ;find width of intersection
                If (Left1 < Left2)
                    IntersectX := ((Right1 < Right2) ? Right1 : Right2) - Left2
                Else
                    IntersectX := Left1 - ((Right1 < Right2) ? Right1 : Right2)

                ;find height of intersection
                If (Top1 < Top2)
                    IntersectY := ((Bottom1 < Bottom2) ? Bottom1 : Bottom2) - Top2
                Else
                    IntersectY := Top1 - ((Bottom1 < Bottom2) ? Bottom1 : Bottom2)
                Return, 1 ;collision occurred
            }

            Inside(Rectangle)
            {
                Return, this.X >= Rectangle.X
                        && (this.X + this.W) <= (Rectangle.X + Rectangle.W)
                        && this.Y >= Rectangle.Y
                        && (this.Y + this.H) <= (Rectangle.Y + Rectangle.H)
            }

            __Get(Key)
            {
                If (Key != "")
                    Return, this[""][Key]
            }

            __Set(Key,Value)
            {
                If (Key = "Color")
                    this.ColorModified := 1
                ObjInsert(this[""],Key,Value)
                Return, this
            }
        }

        class Static extends ProgressEngine.Blocks.Default
        {
            __New()
            {
                base.__New()
                this.Physical := 1
            }
        }

        class Dynamic extends ProgressEngine.Blocks.Static
        {
            Step(Delta,Layer)
            {
                ;wip: use spatial acceleration structure
                ;set physical constants
                Friction := 0.01
                Restitution := 0.6

                this.X += this.SpeedX * Delta, this.Y -= this.SpeedY * Delta ;process momentum

                CollisionX := 0, CollisionY := 0, TotalIntersectX := 0, TotalIntersectY := 0
                For Index, Entity In Layer.Entities
                {
                    If (&Entity = &this || !Entity.Physical) ;entity is the same as the current entity or is not physical
                        Continue
                    If !this.Collide(Entity,IntersectX,IntersectY) ;entity did not collide with the rectangle
                        Continue
                    If (Abs(IntersectX) >= Abs(IntersectY)) ;collision along top or bottom side
                    {
                        CollisionY := 1
                        this.Y -= IntersectY ;move the entity out of the intersection area
                        this.SpeedY *= -Restitution ;reflect the speed and apply damping
                        TotalIntersectY += Abs(IntersectY)
                    }
                    Else ;collision along left or right side
                    {
                        CollisionX := 1
                        this.X -= IntersectX ;move the entity out of the intersection area
                        this.SpeedX *= -Restitution ;reflect the speed and apply damping
                        TotalIntersectX += Abs(IntersectX)
                    }
                }
                this.IntersectX := TotalIntersectX, this.IntersectY := TotalIntersectY
                If CollisionY
                    this.SpeedX *= (Friction * TotalIntersectY) ** Delta ;apply friction
                If CollisionX
                    this.SpeedY *= (Friction * TotalIntersectX) ** Delta ;apply friction
            }
        }
        
        class Text extends ProgressEngine.Blocks.Default
        {
            __New()
            {
                base.__New()
                this.hFont := 0
                this.PreviousViewportWidth := -1
                this.Align := "Center"
                this.Size := 5
                this.Weight := 500
                this.Italic := 0
                this.Underline := 0
                this.Strikeout := 0
                this.Typeface := "Verdana"
                this.Text := "Text"
            }
    
            Draw(hDC,PositionX,PositionY,Width,Height,ViewportWidth,ViewportHeight)
            {
                ;check for entity moving out of bounds
                If (PositionX + Width) < 0 || PositionX > ViewportWidth
                    || (PositionY + Height) < 0 || PositionY > ViewportHeight
                    Return

                If (this.Align = "Left")
                    DllCall("SetTextAlign","UPtr",hDC,"UInt",24) ;TA_LEFT | TA_BASELINE: align text to the left and the baseline
                Else If (this.Align = "Center")
                    DllCall("SetTextAlign","UPtr",hDC,"UInt",30) ;TA_CENTER | TA_BASELINE: align text to the center and the baseline
                Else If (this.Align = "Right")
                    DllCall("SetTextAlign","UPtr",hDC,"UInt",26) ;TA_RIGHT | TA_BASELINE: align text to the right and the baseline
    
                ;update the font if it has changed or if the viewport size has changed
                If this.FontModified || ViewportWidth != this.PreviousViewportWidth
                {
                    If this.hFont
                            DllCall("DeleteObject","UPtr",this.hFont)
                    this.hFont := DllCall("CreateFont","Int",Round(this.Size * (ViewportWidth / 100)),"Int",0,"Int",0,"Int",0,"Int",this.Weight,"UInt",this.Italic,"UInt",this.Underline,"UInt",this.Strikeout,"UInt",1,"UInt",0,"UInt",0,"UInt",4,"UInt",0,"Str",this.Typeface,"UPtr") ;DEFAULT_CHARSET, ANTIALIASED_QUALITY
                    this.FontModified := 0
                }
                this.PreviousViewportWidth := ViewportWidth
    
                DllCall("SetTextColor","UPtr",hDC,"UInt",this.Color)
    
                hOriginalFont := DllCall("SelectObject","UInt",hDC,"UPtr",this.hFont,"UPtr") ;select the font
    
                If this.Visible
                    DllCall("TextOut","UPtr",hDC,"Int",PositionX,"Int",PositionY,"Str",this.Text,"Int",StrLen(this.Text))
    
                DllCall("SelectObject","UInt",hDC,"UPtr",hOriginalFont,"UPtr") ;deselect the font
            }
            
            __Set(Key,Value)
            {
                If (Key = "Size" || Key = "Weight" || Key = "Italic" || Key = "Underline" || Key = "Strikeout" || Key = "Typeface")
                    this.FontModified := 1
                ObjInsert(this[""],Key,Value)
                Return, this
            }
        }
    }

    __Delete()
    {
        For Index, Layer In this.Layers
        {
            For Key, Entity In Layer.Entities
            {
                If Entity.hPen
                    DllCall("DeleteObject","UPtr",Entity.hPen)
                If Entity.hBrush
                    DllCall("DeleteObject","UPtr",Entity.hBrush)
            }
        }
        DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr") ;deselect the bitmap from the device context
        DllCall("DeleteObject","UPtr",this.hBitmap) ;delete the bitmap
        DllCall("DeleteObject","UPtr",this.hMemoryDC) ;delete the memory device context
        DllCall("ReleaseDC","UPtr",this.hWindow,"UPtr",this.hDC) ;release the window device context
    }
}