// ============================================================================
//  PODProjectile.uc ::
// ============================================================================
class PODProjectile extends Projectile;

var float ReflectDamageMult;
var float ReflectSpawnOffset;
var bool bReflectInstigator;
var bool bReflectOwner;



simulated function Destroyed()
{
    Super.Destroyed();
    DestroyEffects();
}


simulated function DestroyEffects()
{
}

simulated function InitCopy( Projectile PR )
{
    PR.Damage = Damage;
}

simulated function bool Reflect( Actor Other )
{
    local Pawn P;
    local vector RefNormal;
    local Projectile PR;
    local Actor NewOwner;

    if( Other == None )
        return false;

    P = Pawn(Other);
    if( P == None
    ||  P.Weapon == None
    || !P.Weapon.CheckReflect(Location,RefNormal,Damage*ReflectDamageMult)  )
    {
        return false;
    }

    //xLog( "Reflecting" @name @"off" @other.name );

    if( Role == ROLE_Authority )
    {
        if( bReflectInstigator )
            Instigator = P;

        if( bReflectOwner )
            NewOwner = Other;
        else
            NewOwner = Owner;

        PR = Spawn(Class, NewOwner,, Location+RefNormal*ReflectSpawnOffset, rotator(RefNormal));
        if( PR != None )
        {
            InitCopy( PR );
        }
    }

    DestroyEffects();
    Destroy();
    return true;
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
    TossZ                       = 0
    bUseCollisionStaticMesh     = True
    bProjTarget                 = False
    bSwitchToZeroCollision      = True
    bBounce                     = True
    LifeSpan                    = 30.0
    CullDistance                = 8192.0

    ReflectDamageMult           = 0.25
    ReflectSpawnOffset          = 24
    bReflectInstigator          = True
    bReflectOwner               = True
}
