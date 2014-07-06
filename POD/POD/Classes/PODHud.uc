// ============================================================================
//  PODHud.uc ::
// ============================================================================
class PODHud extends HudCTeamDeathMatch;


var texture PODCrossHair, PODCrossHairWBuild, PODHealthBar, PODEnergyBar, PODBuildBar;

// - Heart --------------------------------------------------------------------

var transient PODHeart Heart;
var() SpriteWidget HeartBG;
var() NumericWidget HeartHealth;


// - Stats --------------------------------------------------------------------

var() NumericWidget DigitsEnergy;
var() SpriteWidget HudBorderEnergyIcon;

var   int MaxHealth;


// - Radar --------------------------------------------------------------------

var() float RadarRange;
var() SpriteWidget RadarBG;
var() SpriteWidget RadarDot;
var() byte RadarMode;
var() byte RadarDir;

var() float RadarPosX;
var() float RadarPosY;
var() float RadarSize;
var() float RadarDotScale;


// ============================================================================
//  HUD
// ============================================================================

simulated function DrawAdrenaline( Canvas C );
simulated function DrawChargeBar( Canvas C );

simulated function DrawTimer(Canvas C)
{
    local GameReplicationInfo GRI;
    local int Minutes, Hours, Seconds;

    GRI = PlayerOwner.GameReplicationInfo;

    if ( GRI.TimeLimit != 0 )
        Seconds = GRI.RemainingTime;
    else
        Seconds = GRI.ElapsedTime;

    TimerBackground.Tints[TeamIndex] = HudColorBlack;
    TimerBackground.Tints[TeamIndex].A = 150;

    //DrawSpriteWidget( C, TimerBackground);
    //DrawSpriteWidget( C, TimerBackgroundDisc);
    DrawSpriteWidget( C, TimerIcon);

    TimerMinutes.OffsetX = default.TimerMinutes.OffsetX - 80;
    TimerSeconds.OffsetX = default.TimerSeconds.OffsetX - 80;
    //TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX;
    //TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX;

    if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

        DrawNumericWidget( C, TimerHours, DigitsBig);
        TimerHours.Value = Hours;

        if(Hours>9)
        {
            TimerMinutes.OffsetX = default.TimerMinutes.OffsetX;
            TimerSeconds.OffsetX = default.TimerSeconds.OffsetX;
        }
        else
        {
            TimerMinutes.OffsetX = default.TimerMinutes.OffsetX -40;
            TimerSeconds.OffsetX = default.TimerSeconds.OffsetX -40;
            //TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX - 32;
            //TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX - 32;
        }
        //DrawSpriteWidget( C, TimerDigitSpacer[0]);
    }
    //DrawSpriteWidget( C, TimerDigitSpacer[1]);

    Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    TimerMinutes.Value = Min(Minutes, 60);
    TimerSeconds.Value = Min(Seconds, 60);

    DrawNumericWidget( C, TimerMinutes, DigitsBig);
    DrawNumericWidget( C, TimerSeconds, DigitsBig);
}

simulated function DrawCrosshair (Canvas C)
{
    local SpriteWidget CHtexture, HealthTexture, EnergyTexture, BuildTexture;
    local float HFinal, EFinal, BFinal;

    CHTexture = Crosshairs[0];

    // Progress
    if( PawnOwner != None && PODToolboxGun(PawnOwner.Weapon) != None )
    {
        BFinal = PODToolboxGun(PawnOwner.Weapon).ChargeBar();
    }
    if( BFinal > 0 && BFinal < 1 )
    {
        CHTexture.WidgetTexture = PODCrossHairWBuild;
        BuildTexture = Crosshairs[0];
        BuildTexture.WidgetTexture = PODBuildBar;
        BuildTexture.TextureCoords.X1 = 14;
        BuildTexture.TextureCoords.X2 = 43;
        BuildTexture.Scale = BFinal;
        BuildTexture.ScaleMode = SM_Right;
        DrawSpriteWidget (C, BuildTexture);
    }
    else
    {
        CHTexture.WidgetTexture = PODCrossHair;
    }

    // Health
    HFinal = FMin(1, float(CurHealth)/MaxHealth);
    HealthTexture = Crosshairs[0];
    HealthTexture.WidgetTexture = PODHealthBar;
    HealthTexture.TextureCoords.Y1 = 15;
    HealthTexture.TextureCoords.Y2 = 48;
    HealthTexture.Scale = HFinal;
    HealthTexture.ScaleMode = SM_Up;
    DrawSpriteWidget (C, HealthTexture);

    // Energy
    EFinal = FMin(1, float(CurEnergy)/MaxEnergy);
    EnergyTexture = Crosshairs[0];
    EnergyTexture.WidgetTexture = PODEnergyBar;
    EnergyTexture.TextureCoords.Y1 = 15;
    EnergyTexture.TextureCoords.Y2 = 48;
    EnergyTexture.Scale = EFinal;
    EnergyTexture.ScaleMode = SM_Up;
    DrawSpriteWidget (C, EnergyTexture);
    DrawSpriteWidget (C, CHtexture);

    DrawEnemyName(C);
}

simulated function UpdateHud()
{
    local PODGRI GRI;

    super.UpdateHud();

    GRI = PODGRI(PlayerOwner.GameReplicationInfo);

    // If player is on the NanoBot team and the heart health changes,
    // show them a warning message
    if( HeartHealth.Value != 0
    &&  PawnOwner != None
    &&  PlayerOwner != None
    &&  PlayerOwner.GetTeamNum() == 0
    &&  GRI != None
    &&  HeartHealth.Value != GRI.HeartTHealth
    ){
        PawnOwner.ReceiveLocalizedMessage(class'PODHeartMessage', 0);
    }

    if( GRI != none )
    {
        HeartHealth.Value = GRI.HeartTHealth;
    }

    if( HeartHealth.Value < 0 )
        HeartHealth.Value = 0;

    DigitsShield.Value    = CurShield;
    DigitsEnergy.Value    = CurEnergy;
}

simulated function ShowTeamScorePassA(Canvas C)
{
    local vector Pos;

    DrawSpriteWidget (C, HeartBG);

    if( PlayerOwner != None && PODGRI(PlayerOwner.GameReplicationInfo) != none )
    {
        Pos = PODGRI(PlayerOwner.GameReplicationInfo).HeartPos;
    }

    C.DrawColor = HudColorHighLight;
    Draw2DLocationDot(C, Pos, 0.5 - 0.0071*HUDScale, 0.058*HUDScale, 0.036*HUDScale, 0.048*HUDScale);
    DrawNumericWidget( C, HeartHealth, DigitsBig);
}

function Draw2DLocationDot(Canvas C, vector Loc,float OffsetX, float OffsetY, float ScaleX, float ScaleY)
{
    local rotator Dir;
    local float Angle, Scaling;
    local Actor Start;

    if ( PawnOwner == None )
        Start = PlayerOwner;
    else
        Start = PawnOwner;

    if( Start != None && PawnOwner != None )
    {
        Dir = rotator(Loc - Start.Location);
        Angle = ((Dir.Yaw - PlayerOwner.Rotation.Yaw) & 65535) * 6.2832/65536;
        C.Style = ERenderStyle.STY_Alpha;
        C.SetPos(OffsetX * C.ClipX + ScaleX * C.ClipX * sin(Angle),
                OffsetY * C.ClipY - ScaleY * C.ClipY * cos(Angle));

        Scaling = 24*C.ClipX*HUDScale/1600;

        C.DrawTile(LocationDot, Scaling, Scaling,0,0,16,16);
    }
}

simulated function DrawWeaponBar( Canvas C )
{
    local int i, Count, Pos;
    local float IconOffset;
    local float HudScaleOffset, HudMinScale;

    local Weapon Weapons[WEAPON_BAR_SIZE];
    local byte ExtraWeapon[WEAPON_BAR_SIZE];
    local Inventory Inv;
    local Weapon W, PendingWeapon;

    HudMinScale=0.5;
    // CurHudScale = HudScale;
    //no weaponbar for vehicles
    if (Vehicle(PawnOwner) != None)
        return;

    if (PawnOwner.PendingWeapon != None)
        PendingWeapon = PawnOwner.PendingWeapon;
    else
        PendingWeapon = PawnOwner.Weapon;

    // fill:
    for( Inv=PawnOwner.Inventory; Inv!=None; Inv=Inv.Inventory )
    {
        W = Weapon( Inv );
        Count++;
        if ( Count > 100 )
            break;

        if( (W == None) || (W.IconMaterial == None) )
            continue;

        if ( W.InventoryGroup == 0 )
            Pos = 8;
        else if ( W.InventoryGroup < 10 )
            Pos = W.InventoryGroup-1;
        else
            continue;

        if ( Weapons[Pos] != None )
            ExtraWeapon[Pos] = 1;
        else
            Weapons[Pos] = W;
    }

    if ( PendingWeapon != None )
    {
        if ( PendingWeapon.InventoryGroup == 0 )
            Weapons[8] = PendingWeapon;
        else if ( PendingWeapon.InventoryGroup < 10 )
            Weapons[PendingWeapon.InventoryGroup-1] = PendingWeapon;
    }

    // Draw:
    for( i=0; i<WEAPON_BAR_SIZE; i++ )
    {
        W = Weapons[i];

        // Keep weaponbar organized when scaled
        HudScaleOffset= 1-(HudScale-HudMinScale)/HudMinScale;
        BarBorder[i].PosX =  default.BarBorder[i].PosX+( BarBorderScaledPosition[i] - default.BarBorder[i].PosX) *HudScaleOffset;
        BarWeaponIcon[i].PosX = BarBorder[i].PosX;

        IconOffset = (default.BarBorder[i].TextureCoords.X2 - default.BarBorder[i].TextureCoords.X1) *0.5 ;
        BarWeaponIcon[i].OffsetX =  IconOffset;

        BarBorder[i].Tints[0] = HudColorRed;
        BarBorder[i].Tints[1] = HudColorBlue;
        BarBorder[i].OffsetY = 0;
        BarWeaponIcon[i].OffsetY = default.BarWeaponIcon[i].OffsetY;

        if( W == none )
        {
            BarWeaponStates[i].HasWeapon = false;
            if ( bShowMissingWeaponInfo )
            {
                if ( BarWeaponIcon[i].Tints[TeamIndex] != HudColorBlack )
                {
                    BarWeaponIcon[i].WidgetTexture = default.BarWeaponIcon[i].WidgetTexture;
                    BarWeaponIcon[i].TextureCoords = default.BarWeaponIcon[i].TextureCoords;
                    BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale;
                    BarWeaponIcon[i].Tints[TeamIndex] = HudColorBlack;
                    BarWeaponIconAnim[i] = 0;
                }
                DrawSpriteWidget( C, BarBorder[i] );
                DrawSpriteWidget( C, BarWeaponIcon[i] ); // FIXME- have combined version
            }
       }
        else
        {
            if( !BarWeaponStates[i].HasWeapon )
            {
                // just picked this weapon up!
                BarWeaponStates[i].PickupTimer = Level.TimeSeconds;
                BarWeaponStates[i].HasWeapon = true;
            }

            BarBorderAmmoIndicator[i].PosX = BarBorder[i].PosX;
            BarBorderAmmoIndicator[i].OffsetY = 0;
            BarWeaponIcon[i].WidgetTexture = W.IconMaterial;
            BarWeaponIcon[i].TextureCoords = W.IconCoords;

            BarBorderAmmoIndicator[i].Scale = W.AmmoStatus();
            BarWeaponIcon[i].Tints[TeamIndex] = HudColorNormal;

            if( BarWeaponIconAnim[i] == 0 )
            {
                if ( BarWeaponStates[i].PickupTimer > Level.TimeSeconds - 0.6 )
                {
                   if ( BarWeaponStates[i].PickupTimer > Level.TimeSeconds - 0.3 )
                   {
                        BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale * (1 + 1.3 * (Level.TimeSeconds - BarWeaponStates[i].PickupTimer));
                        BarWeaponIcon[i].OffsetX =  IconOffset - IconOffset * ( Level.TimeSeconds - BarWeaponStates[i].PickupTimer );
                   }
                   else
                   {
                        BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale * (1 + 1.3 * (BarWeaponStates[i].PickupTimer + 0.6 - Level.TimeSeconds));
                        BarWeaponIcon[i].OffsetX = IconOffset - IconOffset * (BarWeaponStates[i].PickupTimer + 0.6 - Level.TimeSeconds);
                   }
                }
                else
                {
                    BarWeaponIconAnim[i] = 1;
                    BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale;
                }
            }

            if (W == PendingWeapon)
            {
                // Change color to highlight and possibly changeTexture or animate it
                BarBorder[i].Tints[TeamIndex] = HudColorHighLight;
                BarBorder[i].OffsetY = -10;
                BarBorderAmmoIndicator[i].OffsetY = -10;
                BarWeaponIcon[i].OffsetY += -10;
            }
            if ( ExtraWeapon[i] == 1 )
            {
                if ( W == PendingWeapon )
                {
                    BarBorder[i].Tints[0] = HudColorRed;
                    BarBorder[i].Tints[1] = HudColorBlue;
                    BarBorder[i].OffsetY = 0;
                    BarBorder[i].TextureCoords.Y1 = 80;
                    DrawSpriteWidget( C, BarBorder[i] );
                    BarBorder[i].TextureCoords.Y1 = 39;
                    BarBorder[i].OffsetY = -10;
                    BarBorder[i].Tints[TeamIndex] = HudColorHighLight;
                }
                else
                {
                    BarBorder[i].OffsetY = -52;
                    BarBorder[i].TextureCoords.Y2 = 48;
                    DrawSpriteWidget( C, BarBorder[i] );
                    BarBorder[i].TextureCoords.Y2 = 93;
                    BarBorder[i].OffsetY = 0;
                }
            }
            DrawSpriteWidget( C, BarBorder[i] );
            DrawSpriteWidget( C, BarBorderAmmoIndicator[i] );
            DrawSpriteWidget( C, BarWeaponIcon[i] );
       }
    }

}


simulated function DrawHudPassA (Canvas C)
{
    //local Pawn RealPawnOwner;
    //local class<Ammunition> AmmoClass;

    ZoomFadeOut(C);

    if ( PawnOwner != None )
    {
        /*if( bShowWeaponInfo && (PawnOwner.Weapon != None) )
        {

            if ( PawnOwner.Weapon.bShowChargingBar )
                DrawChargeBar(C);

            DrawSpriteWidget( C, HudBorderAmmo );

            if( PawnOwner.Weapon != None )
            {
                AmmoClass = PawnOwner.Weapon.GetAmmoClass(0);
                if ( (AmmoClass != None) && (AmmoClass.Default.IconMaterial != None) )
                {
                    if( (CurAmmoPrimary/MaxAmmoPrimary) < 0.15)
                    {
                        DrawSpriteWidget(C, HudAmmoALERT);
                        HudAmmoALERT.Tints[TeamIndex] = HudColorTeam[TeamIndex];
                        if ( AmmoClass.Default.IconFlashMaterial == None )
                            AmmoIcon.WidgetTexture = Material'HudContent.Generic.HUDPulse';
                        else
                            AmmoIcon.WidgetTexture = AmmoClass.Default.IconFlashMaterial;
                    }
                    else
                    {
                        AmmoIcon.WidgetTexture = AmmoClass.default.IconMaterial;
                    }

                    AmmoIcon.TextureCoords = AmmoClass.Default.IconCoords;
                    DrawSpriteWidget (C, AmmoIcon);
                }
            }
            DrawNumericWidget( C, DigitsAmmo, DigitsBig);

        }

        if ( bShowWeaponBar && (PawnOwner.Weapon != None) )
            DrawWeaponBar(C);

        */

        if( bShowPersonalInfo )
        {

//            if( CurShield > 0 )
//            {
//                DrawSpriteWidget( C, HudBorderShield );
//                DrawSpriteWidget( C, HudBorderShieldIcon);
//                DrawNumericWidget( C, DigitsShield, DigitsBig);
//                DrawHUDAnimWidget( HudBorderShieldIcon, default.HudBorderShieldIcon.TextureScale, LastArmorPickupTime, 0.6, 0.6);
//            }

            DrawSpriteWidget( C, HudBorderHealthIcon);

            if( CurHealth < LastHealth )
                LastDamagedHealth = Level.TimeSeconds;

            DrawHUDAnimDigit( DigitsHealth, default.DigitsHealth.TextureScale, LastDamagedHealth, 0.8, default.DigitsHealth.Tints[TeamIndex], HudColorHighLight);
            DrawNumericWidget( C, DigitsHealth, DigitsBig);

            if(CurHealth > 999)
            {
                DigitsHealth.OffsetX=220;
                DigitsHealth.OffsetY=-35;
                DigitsHealth.TextureScale=0.39;
            }
            else
            {
                DigitsHealth.OffsetX = default.DigitsHealth.OffsetX;
                DigitsHealth.OffsetY = default.DigitsHealth.OffsetY;
                DigitsHealth.TextureScale = default.DigitsHealth.TextureScale;
            }

            DrawAdrenaline(C);

            DrawSpriteWidget( C, HudBorderShieldIcon);
            DrawNumericWidget( C, DigitsShield, DigitsBig);

            DrawSpriteWidget( C, HudBorderEnergyIcon);
            DrawNumericWidget( C, DigitsEnergy, DigitsBig);

        }
    }

    UpdateRankAndSpread(C);
    DrawUDamage(C);

    if(bDrawTimer)
        DrawTimer(C);

    // POD: Adding this in to draw location of heart radar
    ShowTeamScorePassA(C);

    // Temp Drawwwith Hud Colors
    HudBorderShield.Tints[0] = HudColorRed;
    HudBorderShield.Tints[1] = HudColorBlue;
    HudBorderHealth.Tints[0] = HudColorRed;
    HudBorderHealth.Tints[1] = HudColorBlue;
    HudBorderVehicleHealth.Tints[0] = HudColorRed;
    HudBorderVehicleHealth.Tints[1] = HudColorBlue;
    HudBorderAmmo.Tints[0] = HudColorRed;
    HudBorderAmmo.Tints[1] = HudColorBlue;

    if( Level.TimeSeconds - LastVoiceGainTime < 0.333 )
        DisplayVoiceGain(C);

    DisplayLocalMessages (C);
    DrawRadar(C);
}


// ============================================================================

simulated function DrawUDamage( Canvas C )
{
}

simulated function CalculateHealth()
{
    LastHealth = CurHealth;
    CurHealth = PawnOwner.Health;
    MaxHealth = PawnOwner.HealthMax;

    if( Vehicle(PawnOwner) != None )
    {
        if( Vehicle(PawnOwner).Driver != None )
            CurHealth = Vehicle(PawnOwner).Driver.Health;
        LastVehicleHealth = CurVehicleHealth;
        CurVehicleHealth = PawnOwner.Health;
    }
    else
    {
        MaxHealth = 100;
        CurVehicleHealth = 0;
    }

}

simulated function CalculateShield()
{
    local PODKVehicle P;

    LastShield = CurShield;
    P = PODKVehicle(PawnOwner);

    if( P != None )
    {
        MaxShield = P.ShieldMax;
        CurShield = Clamp(P.Shield, 0, MaxShield);
    }
    else
    {
        MaxShield = 100;
        CurShield = 0;
    }
}

simulated function CalculateEnergy()
{
    local PODKVehicle P;

    LastEnergy = CurEnergy;
    P = PODKVehicle(PawnOwner);

    if( P != None )
    {
        MaxEnergy = P.EnergyMax;
        CurEnergy = Clamp(P.Energy, 0, MaxEnergy);
    }
    else
    {
        MaxEnergy = 100;
        CurEnergy = 0;
    }
}


// ============================================================================
//  Radar
// ============================================================================

static final function float RayPlaneDist( vector RayPoint, vector RayNormal, vector PlanePoint, vector PlaneNormal )
{
    return ( (PlanePoint - RayPoint) dot PlaneNormal ) / ( RayNormal dot PlaneNormal );
}


exec function RadarD( byte b )
{
    RadarDir = b;
}

exec function RadarM( byte b )
{
    RadarMode = b;
}

simulated function DrawRadar( Canvas C )
{
    local Pawn P;
    local PlayerController LP;
    local vector VX,VY,VZ,CamLoc,PLoc,rdelta,rloc;
    local float cx,cy,px,py,rdist,rx,ry,ax,ay,as,cs,ds;
    local rotator CamRot;
//    local int i;

    DrawSpriteWidget( C, RadarBG);

    // setup canvas
    C.Style = ERenderStyle.STY_Alpha;
    C.DrawColor = WhiteColor;
    C.ColorModulate = C.default.ColorModulate;

    // prepare stuff
    cx = RadarPosX * C.ClipX;
    cy = RadarPosY * C.ClipY;
    cs = RadarSize * (C.ClipX/640);
    ds = RadarDotScale * (C.ClipX/640);

    LP = Level.GetLocalPlayerController();

    // Get cam coords
    C.GetCameraLocation(CamLoc,CamRot);
    //CamLoc = LP.Pawn.Location;
    //CamRot = LP.GetViewRotation();

    if( RadarDir == 0 )
    {
        GetAxes(CamRot,VX,VY,VZ);
    }
    else
    {
        GetAxes(CamRot,VZ,VY,VX);
    }

//    // Ingame positioning helper
//    for( i=0; i!=6; ++i)
//    {
//        if( i == 0 ) PLoc = CamLoc + VY*RadarRange;
//        if( i == 1 ) PLoc = CamLoc - VY*RadarRange;
//        if( i == 2 ) PLoc = CamLoc + VZ*RadarRange;
//        if( i == 3 ) PLoc = CamLoc - VZ*RadarRange;
//        if( i == 4 ) PLoc = CamLoc + VX*RadarRange;
//        if( i == 5 ) PLoc = CamLoc - VX*RadarRange;

    foreach CollidingActors(class'Pawn',P,RadarRange,CamLoc)
    {
        PLoc = P.Location;

        // filter out unwanted stuff
        if( P.GetTeamNum() != LP.GetTeamNum()
        ||  PODKVehicle(P) == None )
            continue;

        // project location on radar plane
        rdist = RayPlaneDist( PLoc, VZ, CamLoc, VZ );
        rloc = PLoc + ( VZ * rdist );
        rdelta = rloc - CamLoc;

        // x position
        ax = VY dot Normal(rdelta);
        //ax = acos(ax)/pi;
        rx = ( ax * VSize(rdelta) ) / RadarRange;
        rx *= cs;
        px = rx + cx;

        // y position
        ay = VX dot Normal(rdelta);
        //ay = acos(ay)/pi;
        ry = ( ay * VSize(rdelta) ) / RadarRange;
        ry *= cs;
        py = -ry + cy;

        // scale
        as = -rdist / RadarRange; // size from distance
        as = 1.0 + FClamp(as,-0.5,1.0);
        as = ds * as;

        C.SetPos(px-16*as*0.5,py-16*as*0.5);
        C.DrawTile(LocationDot,16*as,16*as,0,0,16,16);

//        if( P != LP.Pawn )
//        {
//            C.SetPos(10,240);
//            C.DrawText( "P:" @ax @ay @az @as /*@rx @ry*/ );
//            break;
//        }
    }
}


// ============================================================================
//  Debug
// ============================================================================
final simulated function xLog ( coerce string s )
{
    Log
    (   "[" $Left("00",2-Len(Level.Second)) $Level.Second $":"
            $Left("000",3-Len(Level.Millisecond)) $Level.Millisecond $"]"
    @   "[" $StrShort(GetStateName()) $"]"
    @   s
    ,   name );
}

final static function nLog ( coerce string s )
{
    Log( s, default.name );
}

final static function string StrShort( coerce string s )
{
    local string r,c;
    local int i,n;

    c = Caps(s);
    n = Len(s);

    for( i=0; i!=n; ++i )
        if( Mid(s,i,1) == Mid(c,i,1) )
            r $= Mid(s,i,1);

    return r;
}

final static operator(112) string # ( coerce string A, coerce string B )
{
    return A @"[" $B $"]";
}

final static function name GON( Object O )
{
    if( O != None ) return O.Name;
    else            return 'None';
}

final simulated function string GPT( string S )
{
    return GetPropertyText(S);
}

// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    RadarRange                  = 4096
    RadarMode                   = 0
    RadarPosX                   = 0.87
    RadarPosY                   = 0.195
    RadarSize                   = 60.0
    RadarDotScale               = 1.0

    RadarBG                     = (WidgetTexture=Texture'PODTX_Interface.Radar_Circle',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=3.0,DrawPivot=DP_MiddleMiddle,PosX=0.875,PosY=0.2,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))

    TimerIcon                   = (WidgetTexture=Texture'PODTX_Interface.PHUDText.Timer',PosX=0.00,PosY=0.00,OffsetX=10,OffsetY=13,DrawPivot=DP_UpperLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.75,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))
    TimerMinutes                = (MinDigitCount=2,RenderStyle=STY_Alpha,TextureScale=0.32,DrawPivot=DP_MiddleLeft,PosX=0.0,PosY=0.0,OffsetX=240,OffsetY=103,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)
    TimerSeconds                = (MinDigitCount=2,RenderStyle=STY_Alpha,TextureScale=0.32,DrawPivot=DP_MiddleLeft,PosX=0.0,PosY=0.0,OffsetX=325,OffsetY=103,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)

    HudBorderHealthIcon         = (WidgetTexture=Texture'PODTX_Interface.PHUDText.Health',PosX=0.00,PosY=0.885,OffsetX=10,OffsetY=0,DrawPivot=DP_UpperLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.75,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))
    HudBorderShieldIcon         = (WidgetTexture=Texture'PODTX_Interface.PHUDText.Shield',PosX=0.00,PosY=0.815,OffsetX=10,OffsetY=0,DrawPivot=DP_UpperLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.75,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))
    HudBorderEnergyIcon         = (WidgetTexture=Texture'PODTX_Interface.PHUDText.Energy',PosX=0.00,PosY=0.745,OffsetX=10,OffsetY=0,DrawPivot=DP_UpperLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.75,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))

    DigitsHealth                = (MinDigitCount=3,RenderStyle=STY_Alpha,TextureScale=0.32,DrawPivot=DP_MiddleLeft,PosX=0.0,PosY=1.0,OffsetX=168,OffsetY=-95,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)
    DigitsShield                = (MinDigitCount=3,RenderStyle=STY_Alpha,TextureScale=0.32,DrawPivot=DP_MiddleLeft,PosX=0.0,PosY=1.0,OffsetX=168,OffsetY=-205,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)
    DigitsEnergy                = (MinDigitCount=3,RenderStyle=STY_Alpha,TextureScale=0.32,DrawPivot=DP_MiddleLeft,PosX=0.0,PosY=1.0,OffsetX=168,OffsetY=-315,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255),bPadWithZeroes=1)

    //HudBorderHealthIcon       = (WidgetTexture=Texture'PODTX_Interface.PHUDText.Health',DrawPivot=DP_LowerLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.75,PosX=0.0,PosY=0.0,OffsetX=5,OffsetY=0,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))
    //HudBorderHealth           = (WidgetTexture=Texture'PODTX_Interface.PHUDText.Health',DrawPivot=DP_LowerLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.75,PosX=0.0,PosY=1.0,OffsetX=5,OffsetY=0,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))

    PODHealthBar                = Texture'PODTX_Interface.PHUDText.Health_bar'
    PODEnergyBar                = Texture'PODTX_Interface.PHUDText.Energy_bar'
    PODBuildBar                 = Texture'PODTX_Interface.PHUDText.Progress_bar'
    PODCrossHair                = Texture'PODTX_Interface.PHUDText.Crosshair'
    PODCrossHairWBuild          = Texture'PODTX_Interface.PHUDText.Crosshair_progress'

    HudColorHighLight           = (G=255,R=255,B=255,A=255)
    LocationDot                 = Texture'PODTX_Interface.PHUDText.Radar_Dot'
    DigitsBig                   = (DigitTexture=Texture'PODTX_Interface.PHUDText.FBase',TextureCoords[0]=(X1=9,Y1=7,X2=47,Y2=35),TextureCoords[1]=(X1=48,Y1=7,X2=85,Y2=35),TextureCoords[2]=(X1=86,Y1=7,X2=123,Y2=35),TextureCoords[3]=(X1=124,Y1=7,X2=161,Y2=35),TextureCoords[4]=(X1=162,Y1=7,X2=199,Y2=35),TextureCoords[5]=(X1=200,Y1=7,X2=237,Y2=35),TextureCoords[6]=(X1=238,Y1=7,X2=275,Y2=35),TextureCoords[7]=(X1=276,Y1=7,X2=312,Y2=35),TextureCoords[8]=(X1=313,Y1=7,X2=350,Y2=35),TextureCoords[9]=(X1=351,Y1=7,X2=392,Y2=35),TextureCoords[10]=(X1=0,Y1=0,X2=1,Y2=1))
    HeartHealth                 = (RenderStyle=STY_Alpha,PosX=0.475,PosY=0.062,bPadWithZeroes=1,MinDigitCount=3,TextureScale=0.260000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    HeartBG                     = (WidgetTexture=Texture'PODTX_Interface.Radar_Circle',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.750000,DrawPivot=DP_UpperMiddle,PosX=0.500000,PosY=0.021,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    //HeartBG                   = (WidgetTexture=Texture'InterfaceContent.HUD.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=142,Y1=880,Y2=1023),TextureScale=0.350000,DrawPivot=DP_UpperMiddle,PosX=0.500000,PosY=0.010000,OffsetY=-15,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    WaitingToSpawn              = "[Fire] to Join / [AltFire] to change class"

}
