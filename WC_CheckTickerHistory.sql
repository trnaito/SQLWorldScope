
/*====================================================================================================================

 Version 1.0 2016/11/10 Ryoichi Naito ryoichi.naito@thomsonreuters.com

 Check some ticker histories that has a delisted period, ticker changes, or M&As.
 Basic queries to understand Worldscope schemas are included.

 Note: If you encountered an error 'Cannot drop the table...', please ignore and continue the rest of SQLs.
  
 ====================================================================================================================*/

-------------------------------------------------------------
-- 1. All Japanese companies (about 7,400 companies in total)
-------------------------------------------------------------
drop table #wsjp
select
    m.*
,   p.*
/*
,   p.isrcode  -- Issuer code
,   p.code  -- SecCode to map with the master table
,   p.typ_      -- Security type where 1=North America, 6=Global
,   p.vencode */
into #wsjp
from vw_securityMasterX m
    join vw_wsCompanyMapping p on p.code = m.seccode and p.type_ = m.typ
where 
    m.Country='JPN'
    and p.type_ = 6
order by
	name

-- With ticker (from DS2)
drop table #ds2jp
select
	dmap.*
,	difo.*
into #ds2jp
from
	vw_Ds2Mapping dmap
	join vw_Ds2SecInfo difo on dmap.VenCode=difo.InfoCode
where
	difo.IsPrimQt = 1
	and difo.CountryTradingInName='JAPAN'

select
	w.*
,	d.*
,	l.DsLocalCode
from
	#wsjp w
	join #ds2jp d on w.seccode=d.seccode
	join Ds2CtryQtInfo l on d.InfoCode=l.InfoCode
order by
	l.DsLocalCode


--------------------------------------------------------
-- 2. Data items
--------------------------------------------------------

# The list of items for Historical
select top 1000
	Number	-- cross-references with Ws*DATA.Item
,	Name
,	Frequency-- C=current, H=historical
,	DataType	-- A=alphanumeric, N=numeric
,	Length_		-- string lendgh if DataType=A
,	QType		-- A=alphanumeric, D=date, F=flag, I=integer, N=numeric
,	SplitFlag
,	Industry
,	Units
,	RefSect
,	RefNumb
,	Table_		-- table association. D=wsdata, I=wsidata, L=wsldata, M=wsmdata, N=wsndata, S=wssdata, X=wsxdata
,	UsBasis
,	NonUsBasis
,	Month_ 
 from Wsitem
 where
	Frequency='H'

# Just as an example about "Unit".. ---------------------------------
select
    code -- primary link across all Worldscope(Ws*) tables
,	item -- cross-references with all Ws*DATA tables where item=Ws*data.Item
from
	vw_WSItemUnits
where
	item = 1001 -- net sales or revenues


# Sample query for a historical BPS of ABC Mart (id=@ABCMA1) --------------------------
select
	m.id as qaID
,	m.sedol
,	m.name
,	d.fiscalPeriodEndDate
,	d.epsReportDate
,	d.periodUpdateFlag
,	d.periodUpdateDescription
,	d.currencyOfDocument
,	d.periodSource
,	d.Value_,d.itemUnits
from
	vw_SecurityMasterX m
	join vw_WsCompanyMapping w on w.code = m.seccode and w.type_ = m.typ
	left join vw_WsItemData d on d.code = w.vencode
									and d.item = 5476 -- BOOK VALUE PER SHARE
									and d.freq = 'a' -- ANNUAL
where
	m.id = '@SUMIT40'

-- JAL @JAPAN304
-- Bessi @SUMIT40
-- 


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