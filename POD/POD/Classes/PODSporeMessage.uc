class PODSporeMessage extends PODMessage;

var(Message) localized string AVSporeString, ANSporeString, CVSporeString, CNSporeString, NVSporeString, NNSporeString;
var(Message) color YellowColor, RedColor;

static function color GetColor(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2
	)
{
	if (Switch == 0)
		return Default.YellowColor;
	else
		return Default.RedColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
    if (Switch == 0)
	    return Default.ANSporeString;
    else if (Switch == 1)
	    return Default.AVSporeString;
	else if (Switch == 2)
	    return Default.CNSporeString;
    else if (Switch == 3)
	    return Default.CVSporeString;
    else if (Switch == 4)
	    return Default.NNSporeString;
     else if (Switch == 5)
	    return Default.NVSporeString;
}


defaultproperties
{
     AVSporeString="A Virus spore-point is under attack!"
     ANSporeString="A NanoBot spore-point is under attack!"
     CVSporeString="A NanoBot has captured a Virus spore-point!"
     CNSporeString="A Virus has captured a NanoBot spore-point!"
     NVSporeString="A new Virus spore-point has been created!"
     NNSporeString="A new NanoBot spore-point has been created!"
     RedColor=(R=255,A=255)
     YellowColor=(G=255,R=255,A=255)
     bIsPartiallyUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=3
     DrawColor=(G=160,R=0)
     StackMode=SM_Down
     PosY=0.200000
     FontSize=1
}
