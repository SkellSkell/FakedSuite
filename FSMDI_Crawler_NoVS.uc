class FSMDI_Crawler_NoVS extends KFDifficulty_Crawler
	abstract;

static function float GetSpecialCrawlerChance( KFPawn_ZedCrawler CrawlerPawn , KFGameReplicationInfo KFGRI )
{
	return -1.f;
}