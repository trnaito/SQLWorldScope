
/*====================================================================================================================

 Version 1.0 2016/11/09 Ryoichi Naito ryoichi.naito@thomsonreuters.com

 To search all available KPIs of all stocks, the final result from this query will be used as a stock list
 to pick available IBES2 items including KPIs.

 Temp tables:
 #measlist .. All available IBES2 items those stocks
 #ibsdsall .. All DS2 active stocks with EstPermID which is mapped to IBES2 items.

 Note: If you encountered an error 'Cannot drop the table...', please ignore and continue the rest of SQLs.
  
 ====================================================================================================================*/

------------------------------------------------------------------------------
-- 1. List all PermID for current listed stocks where IBES2 data is available
------------------------------------------------------------------------------
/*
 Domestic securities: SecMstrX.SecCode -> PermSecMapX.SecCode where EntType=55 and RegCode= 1 -> PermSecMapX.EntPermID -> TREInfo.QuotePermID
 Global securities: GSecMstrX.SecCode -> PermSecMapX.SecCode where EntType=55 and RegCode= 0 -> PermSecMapX.EntPermID -> TREInfo.QuotePermID
*/
---------------------------------- Take all Stocks from SecMstrX and GSecMstrX with EntPermID
drop table #allg_ibes2
select
	gmst.SecCode
,	gmst.Isin
,	gmst.Name
,	gmap.VenCode
,	pmap.EntPermID
,	pmap.EndDate
,	iifo.QuotePermID
,	iifo.EstPermID
into #allg_ibes2
from
	GSecMstrX gmst
	join GSecMapX gmap on gmst.SecCode = gmap.SecCode and gmap.VenType=2
	join PermSecMapX pmap on gmst.SecCode=pmap.SecCode and pmap.RegCode=0 and pmap.EntType=55 and pmap.EndDate > getdate()
	join TREInfo iifo on pmap.EntPermID = iifo.QuotePermID
order by Name asc

insert into #allg_ibes2
select
	mstr.SecCode
,	mstr.Isin
,	mstr.Name
,	mapx.VenCode
,	pmap.EntPermID
,	pmap.EndDate
,	iifo.QuotePermID
,	iifo.EstPermID
from
	SecMstrX mstr
	join SecMapX mapx on mstr.SecCode = mapx.SecCode and mapx.VenType=2
	join PermSecMapX pmap on mstr.SecCode=pmap.SecCode and pmap.RegCode=1 and pmap.EntType=55 and pmap.EndDate > getdate()
	join TREInfo iifo on pmap.EntPermID = iifo.QuotePermID
order by Name asc

select * from #allg_ibes2


--------------------------------- Retrieve all DS2 available stocks
drop table #ds2all
select
	dmap.*
,	difo.*
into #ds2all
from
	vw_Ds2Mapping dmap
	join vw_Ds2SecInfo difo on dmap.VenCode=difo.InfoCode
where
	difo.IsPrimQt = 1
	and difo.StatusCode='A'

drop table #ibsdsall
select 
	ibs2.SecCode
,	ibs2.Name
,	ibs2.EntPermID
,	ibs2.EstPermID
,	ds2.InfoCode
,	ds2.DsQtName
,	ds2.PrimaryExchange
,	dsqt.DsLocalCode
into #ibsdsall
from
	#allg_ibes2 ibs2
	join #ds2all ds2 on ibs2.SecCode=ds2.SecCode
	join Ds2CtryQtInfo dsqt on ds2.InfoCode=dsqt.InfoCode


--------------------------------------------------------
-- 2. Pick only available items for FY 2016/10 - 2017/9
--------------------------------------------------------
drop table #measlist
select
	distinct(Measure)
into #measlist
from
	TRESumPer esum
where
	EstPermID in (select distinct EstPermID from #ibsdsall)
	and IsParent=0 -- Consolidated
	and PerType=4 -- Year
	and PerEndDate > GetDate()
	and format(PerEndDate, 'yyyyMM') between '201610' and '201709'
	and ExpireDate is null


------------------------------------------------------------------------
-- 3. Summarize and format the table and delete unnecessary temp tables
------------------------------------------------------------------------
select
	mname.*
from
	#measlist mlst
	join TRECode mname on mlst.Measure=mname.Code
where
	mname.CodeType=5

drop table #allg_ibes2
drop table #ds2all

-------------------------------------
-- 4. Sample KPI data for each stock 
-------------------------------------
select * from #ibsdsall

select
	tsum.EstPermID
,	tsum.Measure
,	mcod.Description
,	Min(tsum.PerEndDate) as 'PerEndDate'
,	tsum.DefMeanEst
from
	TRESumPer tsum
	join TRECode mcod on tsum.Measure = mcod.Code and mcod.CodeType=5
where
	tsum.EstPermID=30064783263
	and tsum.ExpireDate is null
	and tsum.PerEndDate > GetDate()
group by
	tsum.EstPermID, tsum.Measure, mcod.Description, tsum.DefMeanEst

	-- and IsParent=0 -- Consolidated
	-- and PerType=4 -- Year
	-- and (DateDiff(year, PerEndDate, EffectiveDate) = 0 -- temporary specify Konki
	-- or (EffectiveDate>='2016-07-25' and DateDiff(year, PerEndDate, EffectiveDate) <0))



select
        tsum.EstPermID
,       tsum.Measure
,       mcod.Description
,       Min(tsum.PerEndDate) as 'PerEndDate'
,       tsum.DefMeanEst
from
        TRESumPer tsum
        join TRECode mcod on tsum.Measure = mcod.Code and mcod.CodeType=5
where
        tsum.EstPermID= 30064795966
        and tsum.ExpireDate is null
        and tsum.PerEndDate > GetDate()
group by
        tsum.EstPermID, tsum.Measure, mcod.Description, tsum.DefMeanEst