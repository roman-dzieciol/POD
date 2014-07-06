// ============================================================================
//  PODPlayer.uc ::
// ============================================================================
class PODPlayer extends xPlayer;

var float   YawAccel, PitchAccel, RollAccel;
//var             Quat    QuatRotation;
var rotator LastDriveRotation;

// ============================================================================
//  Replication
// ============================================================================
replication
{
    // functions called by client on server
    reliable if( Role<ROLE_Authority )
        ServerChangeClass;

    unreliable if( Role < ROLE_Authority )
        PODServerDrive;

}


/* ClientSetLocation()
replicated function to set location and rotation.  Allows server to force new location for
teleports, etc.
*/
function ClientSetLocation( vector NewLocation, rotator NewRotation )
{
    SetRotation(NewRotation);
    /*If ( (Rotation.Pitch > RotationRate.Pitch)
        && (Rotation.Pitch < 65536 - RotationRate.Pitch) )
    {
        If (Rotation.Pitch < 32768)
            NewRotation.Pitch = RotationRate.Pitch;
        else
            NewRotation.Pitch = 65536 - RotationRate.Pitch;
    }*/
    if ( Pawn != None )
    {
        //NewRotation.Roll  = 0;
        Pawn.SetRotation( NewRotation );
        Pawn.SetLocation( NewLocation );
    }
}

/* ClientSetRotation()
replicated function to set rotation.  Allows server to force new rotation.
*/
function ClientSetRotation( rotator NewRotation )
{
    SetRotation(NewRotation);
    if ( Pawn != None )
    {
        //NewRotation.Pitch = 0;
        //NewRotation.Roll  = 0;
        Pawn.SetRotation( NewRotation );
    }
}


// ============================================================================
//  PlayerClass
// ============================================================================

exec function PlayerClass( coerce byte b )
{
    ServerChangeClass(b);
}

function ServerChangeClass( byte b )
{
    //xLog( "ServerChangeClass" #b );

    if( PODGame(Level.Game).ChangeClass(self, b) )
    {
        if( PODKVehicle(Pawn) != None )
            PODKVehicle(Pawn).PlayerChangedClass();
    }
}

simulated function class<PODPlayerClass> GetPlayerClass()
{
    local PODPRI PRI;

    PRI = PODPRI(PlayerReplicationInfo);
    if( PRI != None )
        return PRI.GetPlayerClass();

    return None;
}


// ============================================================================
//  Pawn
// ============================================================================
function Possess( Pawn Other )
{
    Super.Possess( Other );
    if( PODKVehicle(Other) != None )
        PODKVehicle(Other).SetupPlayerClass();
}

function SetPawnClass(string inClass, string inCharacter)
{
}

function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
    local vector FireDir, AimSpot, HitNormal, HitLocation, OldAim, AimOffset;
    local actor BestTarget;
    local float bestAim, bestDist, projspeed;
    local actor HitActor;
    local bool bNoZAdjust, bLeading;
    local rotator AimRot;

    FireDir = vector(Pawn.Rotation);
    if ( FiredAmmunition.bInstantHit )
        HitActor = Trace(HitLocation, HitNormal, projStart + 10000 * FireDir, projStart, true);
    else
        HitActor = Trace(HitLocation, HitNormal, projStart + 4000 * FireDir, projStart, true);
    if ( (HitActor != None) && HitActor.bProjTarget )
    {
        BestTarget = HitActor;
        bNoZAdjust = true;
        OldAim = HitLocation;
        BestDist = VSize(BestTarget.Location - Pawn.Location);
    }
    else
    {
        // adjust aim based on FOV
        bestAim = 0.90;
        if ( (Level.NetMode == NM_Standalone) && bAimingHelp )
        {
            bestAim = 0.93;
            if ( FiredAmmunition.bInstantHit )
                bestAim = 0.97;
            if ( FOVAngle < DefaultFOV - 8 )
                bestAim = 0.99;
        }
        else if ( FiredAmmunition.bInstantHit )
                bestAim = 1.0;
        BestTarget = PickTarget(bestAim, bestDist, FireDir, projStart, FiredAmmunition.MaxRange);
        if ( BestTarget == None )
        {
            return Pawn.Rotation;
        }
        OldAim = projStart + FireDir * bestDist;
    }
    InstantWarnTarget(BestTarget,FiredAmmunition,FireDir);
    ShotTarget = Pawn(BestTarget);
    if ( !bAimingHelp || (Level.NetMode != NM_Standalone) )
    {
        return Pawn.Rotation;
    }

    // aim at target - help with leading also
    if ( !FiredAmmunition.bInstantHit )
    {
        projspeed = FiredAmmunition.ProjectileClass.default.speed;
        BestDist = vsize(BestTarget.Location + BestTarget.Velocity * FMin(1, 0.02 + BestDist/projSpeed) - projStart);
        bLeading = true;
        FireDir = BestTarget.Location + BestTarget.Velocity * FMin(1, 0.02 + BestDist/projSpeed) - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
        // if splash damage weapon, try aiming at feet - trace down to find floor
        if ( FiredAmmunition.bTrySplash
            && ((BestTarget.Velocity != vect(0,0,0)) || (BestDist > 1500)) )
        {
            HitActor = Trace(HitLocation, HitNormal, AimSpot - BestTarget.CollisionHeight * vect(0,0,2), AimSpot, false);
            if ( (HitActor != None)
                && FastTrace(HitLocation + vect(0,0,4),projstart) )
                return rotator(HitLocation + vect(0,0,6) - projStart);
        }
    }
    else
    {
        FireDir = BestTarget.Location - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
    }
    AimOffset = AimSpot - OldAim;

    // adjust Z of shooter if necessary
    if ( bNoZAdjust || (bLeading && (Abs(AimOffset.Z) < BestTarget.CollisionHeight)) )
        AimSpot.Z = OldAim.Z;
    else if ( AimOffset.Z < 0 )
        AimSpot.Z = BestTarget.Location.Z + 0.4 * BestTarget.CollisionHeight;
    else
        AimSpot.Z = BestTarget.Location.Z - 0.7 * BestTarget.CollisionHeight;

    if ( !bLeading )
    {
        // if not leading, add slight random error ( significant at long distances )
        if ( !bNoZAdjust )
        {
            AimRot = rotator(AimSpot - projStart);
            if ( FOVAngle < DefaultFOV - 8 )
                AimRot.Yaw = AimRot.Yaw + 200 - Rand(400);
            else
                AimRot.Yaw = AimRot.Yaw + 375 - Rand(750);
            return AimRot;
        }
    }
    else if ( !FastTrace(projStart + 0.9 * bestDist * Normal(FireDir), projStart) )
    {
        FireDir = BestTarget.Location - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
    }

    return rotator(AimSpot - projStart);
}


// ============================================================================
//  States
// ============================================================================

// ----------------------------------------------------------------------------
//  States
// ----------------------------------------------------------------------------


function UpdateRotation(float DeltaTime, float maxPitch)
{
    local quat QView, QNew;
    local vector X,Y,Z;
    local float dyaw,dpitch,droll;

    if ( bInterpolating || ((Pawn != None) && Pawn.bInterpolating) )
    {
        ViewShake(deltaTime);
        return;
    }

    // Added FreeCam control for better view control
    if ( false && bFreeCam == True)
    {
        if (bFreeCamZoom == True)
        {
            CameraDeltaRad += DeltaTime * 0.25 * aLookUp;
        }
        else if (bFreeCamSwivel == True)
        {
            CameraSwivel.Yaw += 16.0 * DeltaTime * aTurn;
            CameraSwivel.Pitch += 16.0 * DeltaTime * aLookUp;
        }
        else
        {
            CameraDeltaRotation.Yaw += 32.0 * DeltaTime * aTurn;
            CameraDeltaRotation.Pitch += 32.0 * DeltaTime * aLookUp;
        }
    }
    else
    {
        DesiredRotation = Rotation; // save old rotation

        QView = QuatFromRotator(Rotation);

        TurnTarget = None;
        bRotateToDesired = false;
        bSetTurnRot = false;

        GetAxes( Rotation, X, Y, Z );

        dyaw = aTurn * -0.005;
        dpitch = aLookUp * 0.005;
        if( bRun != 0 )
            droll = aStrafe/3000;

        QNew =  QuatProduct(QView,
                QuatProduct(QuatFromAxisAndAngle(Z, DeltaTime * dyaw),
                QuatProduct(QuatFromAxisAndAngle(Y, DeltaTime * dpitch),
                QuatFromAxisAndAngle(X, DeltaTime * droll))));

        SetRotation(QuatToRotator(QNew));
        ViewShake(deltaTime);
        ViewFlash(deltaTime);
    }
}

//function UpdateRotation(float DeltaTime, float maxPitch)
//{
//    local rotator ViewRotation;
//    local Quat QRot, QNew;
//    local vector    X,Y,Z;
//    local float     RotationSmoothFactor;
//    local float     PitchChange,YawChange,RollChange;
//    local float     VehicleRotationSpeed, AirSpeed, RotationInertia;

//    if( IsSpectating() )
//    {
//        if( bInterpolating )
//        {
//            ViewShake(deltaTime);
//            return;
//        }
//
//
//        ViewRotation = Rotation;
//        DesiredRotation = ViewRotation; //save old rotation
//
//        TurnTarget = None;
//        bRotateToDesired = false;
//        bSetTurnRot = false;
//
//        AirSpeed = class'PODKVehicle'.default.AirSpeed;
//        VehicleRotationSpeed = class'PODKVehicle'.default.VehicleRotationSpeed;
//        RotationInertia = class'PODKVehicle'.default.RotationInertia;
//
//        RotationSmoothFactor = FClamp(1.f - RotationInertia * DeltaTime, 0.f, 1.f);
//
//        PitchChange = aLookUp;
//        YawChange = aTurn;
//
//        if( aUp > 0 ) // Rolling
//            RollChange = aStrafe * 0.66;
//
//        // Rotation Acceleration
//        YawAccel    = RotationSmoothFactor*YawAccel   + DeltaTime*VehicleRotationSpeed*YawChange;
//        PitchAccel  = RotationSmoothFactor*PitchAccel + DeltaTime*VehicleRotationSpeed*PitchChange;
//        RollAccel   = RotationSmoothFactor*RollAccel  + DeltaTime*VehicleRotationSpeed*RollChange;
//
//        YawAccel    = FClamp( YawAccel, -AirSpeed, AirSpeed );
//        PitchAccel  = FClamp( PitchAccel, -AirSpeed, AirSpeed );
//        RollAccel   = FClamp( RollAccel, -AirSpeed, AirSpeed );
//
//        // Perform new rotation
//        QRot = QuatFromRotator(ViewRotation);
//        GetAxes( ViewRotation, X, Y, Z );
//        QNew =  QuatProduct(QRot,
//                QuatProduct(QuatFromAxisAndAngle(Y, DeltaTime*PitchAccel),
//                QuatProduct(QuatFromAxisAndAngle(Z, -1.0 * DeltaTime * YawAccel),
//                QuatFromAxisAndAngle(X, DeltaTime * RollAccel))));
//
//        ViewRotation = QuatToRotator( QNew );
//        SetRotation(ViewRotation);
//
//        ViewShake(deltaTime);
//        ViewFlash(deltaTime);
//    }
//    else
//    {
//        Super.UpdateRotation(DeltaTime,MaxPitch);
//    }
//
//
//        SetRotation(QuatToRotator(QuatFromRotator(Rotation)));
//        Super.UpdateRotation(DeltaTime,MaxPitch);
//}

function PODServerDrive(float InForward, float InStrafe, float aUp, rotator View);

// Player movement.
// Player Driving a Karma vehicle.
state PODPlayerDriving extends PlayerDriving
{
ignores SeePlayer, HearNoise, Bump;


    function PODServerDrive(float InForward, float InStrafe, float aUp, rotator View)
    {
        SetRotation(View);
        PODProcessDrive(InForward, InStrafe, aUp);
    }

//    function ServerDrive(float InForward, float InStrafe, float aUp, bool InJump, int View)
//    {
//        local rotator ViewRotation;
//
//        // Added to handle setting of the correct ViewRotation on the server in network games --Dave@Psyonix
//        ViewRotation.Pitch = View/32768;
//        ViewRotation.Yaw = 2 * (View - 32768 * ViewRotation.Pitch);
//        ViewRotation.Pitch *= 2;
//        ViewRotation.Roll = 0;
//        SetRotation(ViewRotation);
//
//        ProcessDrive(InForward, InStrafe, aUp, InJump);
//    }


    // Set the throttle, steering etc. for the vehicle based on the input provided
    function PODProcessDrive(float InForward, float InStrafe, float InUp)
    {
        local Vehicle CurrentVehicle;

        CurrentVehicle = Vehicle(Pawn);

        if(CurrentVehicle == None)
            return;

        //log("Forward:"@InForward@" Strafe:"@InStrafe@" Up:"@InUp);

        CurrentVehicle.Throttle = FClamp( InForward/5000.0, -1.0, 1.0 );
        CurrentVehicle.Steering = FClamp( -InStrafe/5000.0, -1.0, 1.0 );
        CurrentVehicle.Rise = FClamp( InUp/5000.0, -1.0, 1.0 );
    }

    function PlayerMove( float DeltaTime )
    {
        local Vehicle CurrentVehicle;
        local float NewPing;

        CurrentVehicle = Vehicle(Pawn);

        if( CurrentVehicle == None )
        {
            GotoState('Dead');
            return;
        }

        // update 'looking' rotation
        UpdateRotation(DeltaTime, 2);

        // TODO: Don't send things like aForward and aStrafe for gunners who don't need it
        // Only servers can actually do the driving logic.

        if (Role < ROLE_Authority )
        {
            if ( (Level.TimeSeconds - LastPingUpdate > 4) && (PlayerReplicationInfo != None) && !bDemoOwner )
            {
                LastPingUpdate = Level.TimeSeconds;
                NewPing = float(ConsoleCommand("GETPING"));
                if ( ExactPing < 0.006 )
                    ExactPing = FMin(0.1,0.001 * NewPing);
                else
                    ExactPing = 0.99 * ExactPing + 0.0001 * NewPing;
                PlayerReplicationInfo.Ping = Min(250.0 * ExactPing, 255);
                PlayerReplicationInfo.bReceivedPing = true;
                OldPing = ExactPing;
                ServerUpdatePing(1000 * ExactPing);
            }

            if (!bSkippedLastUpdate                                 // in order to skip this update we must not have skipped the last one
            &&  (Player.CurrentNetSpeed < 10000)                    // and netspeed must be low
            &&  (Level.TimeSeconds - ClientUpdateTime < 0.0222)     // and time since last update must be short
            &&  aUp - aLastUp < 0.01                                // and update must not contain major changes
            &&  aForward - aLastForward < 0.01                      // "
            &&  aStrafe - aLastStrafe < 0.01                        // "
            &&  Rotation == LastDriveRotation
               )

            {
//                log("!bSkippedLastUpdate: "$!bSkippedLastUpdate);
//                log("(Player.CurrentNetSpeed < 10000): "$(Player.CurrentNetSpeed < 10000));
//                log("(Level.TimeSeconds - ClientUpdateTime < 0.0222): "$(Level.TimeSeconds - ClientUpdateTime < 0.0222)$"  - "$Level.TimeSeconds - ClientUpdateTime);
//                log("bPressedJump == bLastPressedJump: "$bPressedJump == bLastPressedJump);
//                log("aUp - aLastUp < 0.01: "$aUp - aLastUp < 0.01);
//                log("aForward - aLastForward < 0.01: "$aForward - aLastForward < 0.01);
//                log("aStrafe - aLastStrafe < 0.01: "$aStrafe - aLastStrafe < 0.01);

                bSkippedLastUpdate = True;
                return;
            }
            else
            {
                bSkippedLastUpdate = False;
                ClientUpdateTime = Level.TimeSeconds;

                // Save Move
                aLastUp = aUp;
                aLastForward = aForward;
                aLastStrafe = aStrafe;
                LastDriveRotation = Rotation;

                if (CurrentVehicle != None)
                {
                    CurrentVehicle.Throttle = FClamp( aForward/5000.0, -1.0, 1.0 );
                    CurrentVehicle.Steering = FClamp( -aStrafe/5000.0, -1.0, 1.0 );
                    CurrentVehicle.Rise = FClamp( aUp/5000.0, -1.0, 1.0 );
                }

                PODServerDrive(aForward, aStrafe, aUp, Rotation );
                //ServerDrive(aForward, aStrafe, aUp, bPressedJump, (32767 & (Rotation.Pitch/2)) * 32768 + (32767 & (Rotation.Yaw/2)));
            }
        }
        else
            PODProcessDrive(aForward, aStrafe, aUp);

        // If the vehicle is being controlled here - set replicated variables.
        if (CurrentVehicle != None)
        {
            if(bFire == 0 && CurrentVehicle.bWeaponIsFiring)
                CurrentVehicle.ClientVehicleCeaseFire(False);

            if(bAltFire == 0 && CurrentVehicle.bWeaponIsAltFiring)
                CurrentVehicle.ClientVehicleCeaseFire(True);
        }
    }

    function BeginState()
    {
        PlayerReplicationInfo.bReceivedPing = false;
        CleanOutSavedMoves();
    }

    function EndState()
    {
        CleanOutSavedMoves();
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
//  Debug Draw
// ============================================================================
simulated final function DrawAxesRot( vector Loc, rotator Rot, float Length )
{
    local vector X,Y,Z;
    GetAxes( Rot, X, Y, Z );
    Level.DrawStayingDebugLine(Loc,Loc+X*Length,255,0,0);
    Level.DrawStayingDebugLine(Loc,Loc+Y*Length,0,255,0);
    Level.DrawStayingDebugLine(Loc,Loc+Z*Length,0,0,255);
}

simulated final function DrawAxesXYZ( vector Loc, vector X, vector Y, vector Z, float Length )
{
    Level.DrawDebugLine(Loc,Loc+X*Length,255,0,0);
    Level.DrawDebugLine(Loc,Loc+Y*Length,0,255,0);
    Level.DrawDebugLine(Loc,Loc+Z*Length,0,0,255);
}


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    PawnClass                       = class'PODKVehicle'
    PlayerReplicationInfoClass      = Class'PODPRI'
     bZeroRoll=False
}
