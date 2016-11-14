
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


/*--------------------
 2. All US stocks
 
 About Google:	Google is listed on NASDAQ as GOOG and GOOGL. GOO"G" owner doesn't have a voting right while "L" does.
				This split has occured on April 2014. The reason why they split it is to protect owners' major votes.
				"G" is called as "Class C". "L" is the class B that grants 1 vote with 10 shares. The owners have class A grating 1 vote for 1 share.

				In the next year of class split, Google founded Alphabet which is a parent company of Google, Google Ventures etc..
				The tickers have not changed from the originals (GOOG (C) and GOOGL(B))

---------------------*/
drop table #wsus
select
    m.*
,   p.*
/*
,   p.isrcode  -- Issuer code
,   p.code  -- SecCode to map with the master table
,   p.typ_      -- Security type where 1=North America, 6=Global
,   p.vencode */
into #wsus
from vw_securityMasterX m
    join vw_wsCompanyMapping p on p.code = m.seccode and p.type_ = m.typ
where 
    m.Country='USA'
    and p.type_ = 1

select * from #wsus order by name

-- With ticker (from DS2)
drop table #ds2us
select
	dmap.*
,	difo.*
into #ds2us
from
	vw_Ds2Mapping dmap
	join vw_Ds2SecInfo difo on dmap.VenCode=difo.InfoCode
where
	difo.IsPrimQt = 1
	and difo.CountryTradingInName='UNITED STATES'

select * from #ds2us order by dsqtname -- ALPHABET B (GOOGL) doesn't exist in DS2

select
	w.*
,	d.*
,	l.DsLocalCode
from
	#wsus w
	join #ds2us d on w.seccode=d.seccode
	join Ds2CtryQtInfo l on d.InfoCode=l.InfoCode
order by
	d.dsqtname



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
	m.id = '@NIPPO138'

-- JAL @JAPAN304
-- Bessi @SUMIT40
-- shinnittestu sumikin 5401 , sumitomo kinzoku kogyo 5405
-- Google (Class A) GOOG
-- Google (Class C) 38259P70

select * from #wsjp order by name
