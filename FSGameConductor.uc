class FSGameConductor extends KFGameConductor within FSGameInfo
	config(Game);

function NotifyHumanTeamPlayerDeath()
{
    return;
}

function NotifySoloPlayerSurrounded()
{
    return;
}

function UpdateAveragePerkRank()
{
    return;
}

function HandlePlayerChangedTeam()
{
    return;
}

function TimerUpdate()
{
    return;
}

function UpdateOverallAttackCoolDowns(KFAIController KFAIC)
{
    return;
}

defaultproperties
{
    bBypassGameConductor=true
}