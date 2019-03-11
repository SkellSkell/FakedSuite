class FSAISM_Normal extends KFAISpawnManager_Normal
    within FSGameInfo;

function int GetMaxMonsters()
{
    if(!bCustomMaxMonsters)
        return Super.GetMaxMonsters();
    return CustomMaxMonsters;
}

function float CalcNextGroupSpawnTime()
{
    return Super.CalcNextGroupSpawnTime() * ZedSpawnRateModifier;
}

function bool ShouldAddAI()
{
    if(bNoSpawningCooldown && !IsFinishedSpawning())
        return GetNumAINeeded() > 0;

    return Super.ShouldAddAI();
}

function GetSpawnListFromSquad(byte SquadIdx, out array< KFAISpawnSquad > SquadsList, out array< class<KFPawn_Monster> >  AISpawnList)
{
	Super.GetSpawnListFromSquad(SquadIdx, SquadsList, AISpawnList);

	if(bEnforceFairSpawns)
		static.GetCorrectedSquad(GameLength, WaveNum, AISpawnList);
}