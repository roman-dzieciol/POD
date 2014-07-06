// ============================================================================
//  PODTab_PlayerLoginControls.uc ::
// ============================================================================
class PODTab_PlayerLoginControls extends UT2K4Tab_PlayerLoginControls;

var automated GUIButton b_Engineer;
var automated GUIButton b_Medic;
var automated GUIButton b_Soldier;

function bool ClassChange(GUIComponent Sender)
{
    PlayerOwner().ConsoleCommand("playerclass" @Sender.IniDefault);
    Controller.CloseMenu(false);
    return true;
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local string s;
    local int i;
    local eFontScale FS;

    Super.InitComponent(MyController, MyOwner);

    li_Red  = lb_Red.List;
    li_Blue = lb_Blue.List;
    li_FFA  = lb_FFA.List;

    s = GetSizingCaption();
    for ( i = 0; i < Controls.Length; i++ )
    {
        if ( GUIButton(Controls[i]) != None
        && Controls[i]!=b_Team
        && Controls[i]!=b_Engineer
        && Controls[i]!=b_Medic
        && Controls[i]!=b_Soldier
        )
        {
            GUIButton(Controls[i]).bAutoSize = True;
            GUIButton(Controls[i]).SizingCaption = s;
            GUIButton(Controls[i]).AutoSizePadding.HorzPerc = 0.04;
            GUIButton(Controls[i]).AutoSizePadding.VertPerc = 0.5;
        }
    }
    PlayerStyle = MyController.GetStyle(PlayerStyleName,fs);

    sb_Red.Managecomponent(lb_Red);
    sb_Blue.ManageComponent(lb_Blue);
    sb_FFA.ManageComponent(lb_FFA);

}
function string GetSizingCaption()
{
    local int i;
    local string s;

    for ( i = 0; i < Controls.Length; i++ )
    {
        if ( GUIButton(Controls[i]) != none
         && Controls[i]!=b_Team
        && Controls[i]!=b_Engineer
        && Controls[i]!=b_Medic
        && Controls[i]!=b_Soldier
         )
        {
            if ( s == "" || Len(GUIButton(Controls[i]).Caption) > Len(s) )
                s = GUIButton(Controls[i]).Caption;
        }
    }

    return s;
}

function SetButtonPositions(Canvas C)
{
    local int i, j, ButtonsPerRow, ButtonsLeftInRow;
    local float Width, Center, X, Y, XL, YL;

    bInit = False;

    Width = b_Settings.ActualWidth();
    Center = ActualLeft() + ActualWidth() / 2;

    XL = Width * 1.05;
    YL = b_Settings.ActualHeight() * 1.2;
    Y = b_Settings.ActualTop();

    ButtonsPerRow = ActualWidth() / XL;
    ButtonsLeftInRow = ButtonsPerRow;

    if (ButtonsPerRow > 1)
        X = Center - (0.5 * (XL * float(ButtonsPerRow - 1) + Width));
    else
        X = Center - Width / 2;

    for (i = 0; i < Components.Length; i++)
    {
        if (!Components[i].bVisible
        || GUIButton(Components[i]) == none
        || Components[i]==b_Team
        || Components[i]==b_Engineer
        || Components[i]==b_Medic
        || Components[i]==b_Soldier
         )
            continue;

        Components[i].SetPosition( X, Y, Components[i].WinWidth, Components[i].WinHeight, True );
        if ( --ButtonsLeftInRow > 0 )
            X += XL;
        else
        {
            Y += YL;
            for (j = i + 1; j < Components.Length && ButtonsLeftInRow < ButtonsPerRow; j++)
                if ( GUIButton(Components[j]) != None )
                    ButtonsLeftInRow++;

            if (ButtonsLeftInRow > 1)
                X = Center - (0.5 * (XL * float(ButtonsLeftInRow - 1) + Width));
            else
                X = Center - Width / 2;
        }
    }
}

function InitGRI()
{
    local PlayerController PC;
    local GameReplicationInfo GRI;
    local PODPRI PRI;

    Super.InitGRI();

    GRI = GetGRI();
    if ( GRI == None )
        return;

    PC = PlayerOwner();
    PRI = PODPRI(PC.PlayerReplicationInfo);
    if( PRI == None )
        return;

    UpdateClassButton( b_Engineer, PRI.PlayerClassByte );
    UpdateClassButton( b_Medic, PRI.PlayerClassByte );
    UpdateClassButton( b_Soldier, PRI.PlayerClassByte );
}

function UpdateClassButton( GUIComponent C, byte B )
{
    if( B == byte(C.IniDefault) )
        C.DisableMe();
    else
        C.EnableMe();
}

DefaultProperties
{
    Begin Object Class=GUIButton Name=TeamButton
        Caption="Change Team"
        StyleName="SquareButton"
        OnClick=TeamChange
        WinWidth=0.24
        WinLeft=0.0
        WinTop=0.016613
        TabOrder=0
        bStandardized=true
        bBoundToParent=true
        bScaleToParent=true
    End Object
    b_Team=TeamButton


    Begin Object Class=GUIButton Name=ob_Engineer
        Caption="Engineer Class"
        IniDefault="0"
        StyleName="SquareButton"
        OnClick=ClassChange
        WinWidth=0.25
        WinLeft=0.245
        WinTop=0.016613
        TabOrder=1
        bStandardized=true
        bBoundToParent=true
        bScaleToParent=true
    End Object
    b_Engineer=ob_Engineer

    Begin Object Class=GUIButton Name=ob_Medic
        Caption="Medic Class"
        IniDefault="1"
        StyleName="SquareButton"
        OnClick=ClassChange
        WinWidth=0.23
        WinLeft=0.495
        WinTop=0.016613
        TabOrder=2
        bStandardized=true
        bBoundToParent=true
        bScaleToParent=true
    End Object
    b_Medic=ob_Medic

    Begin Object Class=GUIButton Name=ob_Soldier
        Caption="Soldier Class"
        IniDefault="2"
        StyleName="SquareButton"
        OnClick=ClassChange
        WinWidth=0.24
        WinLeft=0.75
        WinTop=0.016613
        TabOrder=3
        bStandardized=true
        bBoundToParent=true
        bScaleToParent=true
    End Object
    b_Soldier=ob_Soldier


}
