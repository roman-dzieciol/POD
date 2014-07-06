// ============================================================================
//  PODUtil.uc ::
// ============================================================================
class PODUtil extends PODObject;


static final function int PackInt2( int a, int b )
{
    return a + (b << 16);
}

static final function UnPackInt2( int v, out int a, out int b )
{
    a = v & 0xFFFF;
    b = v >> 16;
}

static final function int PackInt4( int a, int b, optional int c, optional int d )
{
    return a + (b << 8) + (c << 16) + (d << 24);
}

static final function UnPackInt4( int v, out int a, out int b, out int c, out int d )
{
    a = v & 0xFF;
    b = (v >> 8) & 0xFF;
    c = (v >> 16) & 0xFF;
    d = v >> 24;
}

DefaultProperties
{

}
