class FSMDI_Crawler_NoVSBlock extends KFDifficulty_Crawler
	abstract;

static function float GetSpecialCrawlerChance( KFPawn_ZedCrawler CrawlerPawn , KFGameReplicationInfo KFGRI )
{
	return -1.f;
}

defaultproperties
{
	Normal={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}	

	Hard={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}
	
	Suicidal={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}
	
	HellOnEarth={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}
}