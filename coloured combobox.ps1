$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(450, 180)	
$form.StartPosition = "CenterScreen"
 
$combobox = New-Object System.Windows.Forms.ComboBox
$combobox.Location = New-Object System.Drawing.Point(20, 50)
$combobox.Size = New-Object System.Drawing.Size(390, 20)	
$combobox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;
$combobox.FlatStyle = "Flat"
$combobox.BackColor = 'White'
$combobox.Font = "Arial,8pt,style=Bold"
$combobox.Cursor = [System.Windows.Forms.Cursors]::Hand

$combobox.Add_SelectedIndexChanged({
	write-host $combobox.Text $combobox.SelectedValue
})

#must set this to override the draw mode!
$combobox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed

$combobox.Add_DrawItem({
    
 param(
    [System.Object] $sender, 
    [System.Windows.Forms.DrawItemEventArgs] $e
    )
    
    If ($Sender.Items.Count -eq 0) {return}
    
    Try {

        #get current item
        $lbItem=$Sender.Items[$e.Index]
 
        #calculate text colour conditionally
        If ($lbItem -eq "Sample1") {
            $textColor = [System.Drawing.Color]::Red
        }
        ElseIf ($lbItem -eq "Sample2") {
            $textColor = [System.Drawing.Color]::Orange
        }
        ElseIf ($lbItem -eq "Sample3") {
            $textColor = [System.Drawing.Color]::Green
        }
        ElseIf ($lbItem -eq "Sample4") {
            $textColor = [System.Drawing.Color]::Blue
        }
        ElseIf ($lbItem -eq "Sample5") {
            $textColor = [System.Drawing.Color]::Blue
        }
        Else {
            $textColor = [System.Drawing.Color]::Black
        }


        #now calculate background color

        $backgroundColor = if(($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected){ 
             #if item is in focus fill with whitesmoke
             [System.Drawing.Color]::WhiteSmoke
        }else{
            #if item not in focus

            #if we want static background color for all rows
            #[System.Drawing.Color]::White

            #or if we want alternating row colors etc

            if($e.Index % 2 -eq 0){
                [System.Drawing.Color]::White
            }else{
                [System.Drawing.Color]::AntiqueWhite
            }
        }

        #create brushes
        $BackgroundColorBrush = New-Object System.Drawing.SolidBrush($backgroundColor)            
        $TextColourBrush = New-Object System.Drawing.SolidBrush($textColor)
        
        #nice smooth rendering of fonts
        $e.Graphics.TextRenderingHint = 'AntiAlias'
        
        #default font
        $font = $e.Font
        
        #or specify a custom font
        #$font = [System.Drawing.Font]::new($e.Font.FontFamily.Name, 18)
              
        # Draw the background
        $e.Graphics.FillRectangle($BackgroundColorBrush, $e.Bounds)
        
        # Draw the text
        $e.Graphics.DrawString($lbItem, $font, $TextColourBrush, (new-object System.Drawing.PointF($e.Bounds.X, $e.Bounds.Y)))
       
        #we decide not to draw the dotted focus triangle
        #$e.DrawFocusRectangle()
    }
    Catch {
        write-host $_.Exception
    }
    Finally {
        $TextColourBrush.Dispose()
         $BackgroundColorBrush.Dispose()
    }


})

$combobox.items.Add("Sample1") | Out-Null
$combobox.items.Add("Sample2") | Out-Null
$combobox.items.Add("Sample3") | Out-Null
$combobox.items.Add("Sample4") | Out-Null
$combobox.items.Add("Sample5") | Out-Null

$form.Controls.Add($combobox)

[void]$form.showdialog()
