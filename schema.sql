/************************************************ Object: Build the stage -- Script ID: 1 -- Lang : SQL **********************************************
-- Author:				Ivan
-- Script Date: 		05/05/2019
-- Description:			CHECKING SYSTEM AND PREPARING THE STAGE  
*****************************************************************************************************************************************************/
IF EXISTS (SELECT type_desc, type FROM sys.procedures WITH(NOLOCK) WHERE NAME = 'PRC_View_FactCurrency' AND type = 'P')
	DROP PROCEDURE Forex.PRC_View_FactCurrency 
GO

IF EXISTS (SELECT type_desc, type FROM sys.procedures WITH(NOLOCK) WHERE NAME = 'PRC_Delete_DimCurrency_Full' AND type = 'P')
	DROP PROCEDURE Forex.PRC_Delete_DimCurrency_Full
GO

IF EXISTS (SELECT type_desc, type FROM sys.procedures WITH(NOLOCK) WHERE NAME = 'PRC_Delete_FactOutSourceCurrency_Clean' AND type = 'P')
	DROP PROCEDURE Forex.PRC_Delete_FactOutSourceCurrency_Clean
GO

IF EXISTS (SELECT type_desc, type FROM sys.procedures WITH(NOLOCK) WHERE NAME = 'PRC_Delete_FullSystemClean' AND type = 'P')
	DROP PROCEDURE Forex.PRC_Delete_FullSystemClean
GO

IF EXISTS (SELECT type_desc, type FROM sys.procedures WITH(NOLOCK) WHERE NAME = 'PRC_View_FactOutSource' AND type = 'P')
	DROP PROCEDURE Forex.PRC_View_FactOutSource
GO

IF OBJECT_ID('Forex.v_FactCurrency', 'V') IS NOT NULL
	DROP VIEW Forex.v_FactCurrency;
GO

IF OBJECT_ID('Forex.v_DimCurrency', 'V') IS NOT NULL
	DROP VIEW Forex.v_DimCurrency;
GO

IF OBJECT_ID('Forex.v_FactOutSource', 'V') IS NOT NULL
	DROP VIEW Forex.v_FactOutSource;
GO

IF OBJECT_ID('Forex.FactCurrencyQuotes') IS NOT NULL
	DROP TABLE Forex.FactCurrencyQuotes;
GO

IF OBJECT_ID('Forex.FactOutSourceCurrency') IS NOT NULL
	DROP TABLE Forex.FactOutSourceCurrency;
GO

IF OBJECT_ID('Forex.DimCurrency') IS NOT NULL
	DROP TABLE Forex.DimCurrency;
GO

IF OBJECT_ID('Forex.DimCurrencySource') IS NOT NULL
	DROP TABLE Forex.DimCurrencySource;
GO

IF OBJECT_ID('Forex.DimCurrencyQuotesType') IS NOT NULL
	DROP TABLE Forex.DimCurrencyQuotesType;
GO

IF OBJECT_ID('Forex.DimSourceSystem') IS NOT NULL
	DROP TABLE Forex.DimSourceSystem;
GO

IF EXISTS (SELECT name FROM sys.schemas WHERE name = N'Forex')
	BEGIN
		DROP SCHEMA Forex;
		EXEC('CREATE SCHEMA Forex;');
	END
ELSE
	BEGIN
		EXEC('CREATE SCHEMA Forex;');
	END
GO

/*********************************************** Object: Define Parametes -- Script ID: 2 -- Lang : SQL **********************************************
-- Author:				Ivan
-- Script Date: 		05/05/2019
-- Description:			DEFINE SYSTEM PARAMETERS 
*****************************************************************************************************************************************************/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/********************************************** Object: Begin the Creation -- Script ID: 3 -- Lang : SQL *********************************************
-- Author:				Ivan
-- Script Date: 		05/05/2019
-- Description:			CREATE DATABASE FOR THE SYSTEM
*****************************************************************************************************************************************************/
CREATE TABLE Forex.CurrencyXml(
	[ID] [int] NOT NULL,
	[LAST_UPDATE] [date] NOT NULL,
	[NAME] [varchar](20) NOT NULL,
	[UNIT] [int] NOT NULL,
	[CURRENCYCODE] [varchar](3) NOT NULL,
	[COUNTRY] [varchar](50) NOT NULL,
	[RATE] [decimal](15, 6) NOT NULL,
	[CHANGE] [decimal](6, 3) NOT NULL,
	[Download_datetime] [datetime] NULL,
	[XML_NAME] [varchar](50) NULL,
	[XML_PATH] [varchar](100) NULL,
	[Source_File_Name] [varchar](200) NULL
);
GO

CREATE TABLE Forex.DimCurrency (
	Currency_Key				  INT					    NOT NULL		IDENTITY(1,1)	PRIMARY KEY,	--Inner identifier			
	ISO							      VARCHAR(5)			NOT NULL		UNIQUE,							        --ISO 4217 for currencies
	CurrencyEnglish				VARCHAR(70)			NULL,											              --Name English
	CurrencyHebrew				VARCHAR(70)			NULL,											              --Name Hebrew	
	CurrencySymbols				VARCHAR(5)			NULL,											              --Symbol on the bill
	Rec_Insert_Date				DATETIME			  NULL			DEFAULT	CURRENT_TIMESTAMP,
	Rec_Insert_User				VARCHAR(50)			NULL			DEFAULT	CURRENT_USER,
	Rec_Delete_Flag				BIT					    NULL			DEFAULT 0,
);
GO

CREATE TABLE Forex.DimCurrencySource (
	Source_Key					  INT					    NOT NULL		IDENTITY(1,1)	PRIMARY KEY,
	SourceName					  VARCHAR(100)		NOT NULL,										            --Source of currency rate. Ex. "Israel Central Bank"
	Rec_Insert_Date				DATETIME			  NULL			  DEFAULT	CURRENT_TIMESTAMP,
	Rec_Insert_User				VARCHAR(50)			NULL			  DEFAULT	CURRENT_USER,
	Rec_Delete_Flag				BIT					    NULL			  DEFAULT 0,
);
GO

CREATE TABLE Forex.DimCurrencyQuotesType (
	QuotesType_Key				INT 				    NOT NULL		IDENTITY(1,1)	PRIMARY KEY,
	QuotesType					  VARCHAR(100)		NOT NULL,										            --Type of rate. Ex. "Representative"
	Rec_Insert_Date				DATETIME			  NULL			  DEFAULT	CURRENT_TIMESTAMP,
	Rec_Insert_User				VARCHAR(50)			NULL			  DEFAULT	CURRENT_USER,
	Rec_Delete_Flag				BIT					    NULL			  DEFAULT 0
);
GO

CREATE TABLE Forex.DimSourceSystem (
	SourceSystem_Key			INT 				    NOT NULL		IDENTITY(1,1)	PRIMARY KEY,
	SourceSystem				  VARCHAR(100)		NOT NULL,										            --Type of rate. Ex. "Representative"
	Rec_Insert_Date				DATETIME			  NULL			  DEFAULT	CURRENT_TIMESTAMP,
	Rec_Insert_User				VARCHAR(50)			NULL			  DEFAULT	CURRENT_USER,
	Rec_Delete_Flag				BIT					    NULL			  DEFAULT 0
);
GO

CREATE TABLE Forex.FactOutSourceCurrency (
	ID							      INT					    NOT NULL		IDENTITY(1,1),
	Currency_Key				  INT					    NULL			  FOREIGN KEY REFERENCES Forex.DimCurrency(Currency_Key),				    --Inner identifier
	SourceSystem_Key			INT					    NOT NULL		FOREIGN KEY REFERENCES Forex.DimSourceSystem(SourceSystem_Key),		--Outside system identifier
	System_ID					    VARCHAR(20)			NOT NULL,																			                                --Identifier
	System_Name					  VARCHAR(255)		NULL,																				                                  --Outside System name
	Rec_Insert_Date				DATETIME			  NULL			  DEFAULT	CURRENT_TIMESTAMP,
	Rec_Insert_User				VARCHAR(50)			NULL			  DEFAULT	CURRENT_USER,
	Rec_Delete_Flag				BIT					    NULL			  DEFAULT 0,
	CONSTRAINT PK_FactOutSourceCurrency_Key PRIMARY KEY (ID)
);
GO

CREATE TABLE Forex.FactCurrencyQuotes (
	ID							      INT 				      NOT NULL		IDENTITY(1,1),
	Currency_Key				  INT					      NOT NULL		FOREIGN KEY REFERENCES Forex.DimCurrency(Currency_Key),
	DateKey						    DATE				      NOT NULL,
	QuotesType_Key				INT					      NOT NULL		FOREIGN KEY REFERENCES Forex.DimCurrencyQuotesType(QuotesType_Key),
	Source_Key					  INT					      NOT NULL		FOREIGN KEY REFERENCES Forex.DimCurrencySource(Source_Key),
	DateTimeStamp				  TIME				      NOT NULL		DEFAULT '00:00:00.000',
	BaseCurrency_Key			INT					      NOT NULL		FOREIGN KEY REFERENCES Forex.DimCurrency(Currency_Key),
	Quotes						    DECIMAL(18, 6)		NOT NULL		CHECK (Quotes >= 0),
	Rec_Insert_Date				DATETIME			    NULL			  DEFAULT	CURRENT_TIMESTAMP,
	Rec_Insert_User				VARCHAR(50)			  NULL			  DEFAULT	CURRENT_USER,
	Rec_Delete_Flag				BIT					      NULL			  DEFAULT 0,
	CONSTRAINT PK_FactCurrencyQuotes_Key PRIMARY KEY (ID)
);
GO

/******************************************************************************************************************************************************
************************************************************************* VIEWS ***********************************************************************
******************************************************************************************************************************************************/
CREATE VIEW Forex.v_FactCurrency WITH SCHEMABINDING AS
SELECT
	c.Currency_Key,
	c.ISO,
	c.CurrencyEnglish,
	c.CurrencyHebrew,
	c.CurrencySymbols,
	cs.SourceName,
	cqt.QuotesType,
	fcq.DateKey,			
	fcq.DateTimeStamp,				
	cb.ISO AS ISO_Base,
	cb.CurrencyEnglish AS English_Base,
	cb.CurrencyHebrew AS Hebrew_Base,
	cb.CurrencySymbols AS Symbols_Base,		
	fcq.Quotes						
FROM Forex.FactCurrencyQuotes fcq INNER JOIN Forex.DimCurrency c ON fcq.Currency_Key = c.Currency_Key
								  INNER JOIN Forex.DimCurrency cb ON fcq.BaseCurrency_Key = cb.Currency_Key
								  INNER JOIN Forex.DimCurrencySource cs ON fcq.Source_Key = cs.Source_Key
								  INNER JOIN Forex.DimCurrencyQuotesType cqt ON fcq.QuotesType_Key = cqt.QuotesType_Key
GO

CREATE VIEW Forex.v_DimCurrency WITH SCHEMABINDING AS
SELECT
	Currency_Key,
	ISO,
	CurrencyEnglish,
	CurrencyHebrew,
	CurrencySymbols
FROM Forex.DimCurrency
GO

CREATE VIEW Forex.v_FactOutSource WITH SCHEMABINDING AS
SELECT
	fosc.Currency_Key,
	fosc.System_ID,
	fosc.System_Name,
	c.ISO,
	c.CurrencyEnglish,
	c.CurrencyHebrew,
	c.CurrencySymbols
FROM Forex.FactOutSourceCurrency fosc INNER JOIN Forex.DimCurrency c ON fosc.Currency_Key = c.Currency_Key
									  INNER JOIN Main.DimSourceSystem sc ON fosc.SourceSystem_Key = sc.SourceSystem_Key
WHERE fosc.Currency_Key IS NOT NULL
GO

/******************************************************************************************************************************************************
****************************************************************** STORED PROCEDURES ******************************************************************
******************************************************************************************************************************************************/
CREATE PROCEDURE Forex.PRC_Delete_DimCurrency_Full @Currency_Key INT
AS
	DELETE FROM Forex.FactCurrencyQuotes WHERE Currency_Key = @Currency_Key;
	DELETE FROM Forex.FactOutSourceCurrency WHERE Currency_Key = @Currency_Key;
	DELETE FROM Forex.DimCurrency WHERE Currency_Key = @Currency_Key;
GO

CREATE PROCEDURE Forex.PRC_Delete_FactOutSourceCurrency_Clean
AS
	DELETE FROM Forex.FactOutSourceCurrency WHERE Currency_Key IS NULL
GO

CREATE PROCEDURE Forex.PRC_Delete_FullSystemClean
AS
	DELETE FROM Forex.DimCurrencySource
	WHERE Source_Key NOT IN (SELECT DISTINCT Source_Key FROM Forex.FactCurrencyQuotes);
	DELETE FROM Forex.DimCurrencyQuotesType
	WHERE QuotesType_Key NOT IN (SELECT DISTINCT QuotesType_Key FROM Forex.FactCurrencyQuotes);
	DELETE FROM Forex.DimCurrency
	WHERE Currency_Key NOT IN (SELECT DISTINCT Currency_Key FROM Forex.FactCurrencyQuotes UNION SELECT DISTINCT BaseCurrency_Key FROM Forex.FactCurrencyQuotes);
GO

CREATE PROCEDURE Forex.PRC_View_FactOutSource @SourceSystem_Key INT
AS
	SELECT
	fosc.Currency_Key,
	fosc.System_ID,
	fosc.System_Name,
	c.ISO,
	c.CurrencyEnglish,
	c.CurrencyHebrew,
	c.CurrencySymbols
	FROM Forex.FactOutSourceCurrency fosc INNER JOIN Forex.DimCurrency c ON fosc.Currency_Key = c.Currency_Key
									  INNER JOIN Main.DimSourceSystem sc ON fosc.SourceSystem_Key = sc.SourceSystem_Key
	WHERE fosc.Currency_Key IS NOT NULL AND fosc.SourceSystem_Key = @SourceSystem_Key
GO

CREATE PROCEDURE Forex.PRC_View_FactCurrency @Source_Key INT, @QuotesType_Key INT 
AS
	SELECT
		fcq.Currency_Key,
		fcq.DateKey,	
		fcq.Quotes						
	FROM Forex.FactCurrencyQuotes fcq 
	WHERE fcq.Source_Key = @Source_Key AND fcq.QuotesType_Key = @QuotesType_Key
GO
