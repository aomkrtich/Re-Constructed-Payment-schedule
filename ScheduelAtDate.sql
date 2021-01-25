USE [proc] 

go 

/****** Object:  UserDefinedFunction [dbo].[HC_graf]    Script Date: 25/01/21 3:27:54 PM ******/
SET ansi_nulls ON 

go 

SET quoted_identifier ON 

go 

--DECLARE @loanid AS VARCHAR(150) = 'CV20-B0130    ' 
ALTER FUNCTION [dbo].[Hc_graf] (@loanid VARCHAR(150), 
                                @rdate  AS DATETIME) 
returns @graph TABLE ( 
  fdate DATETIME, 
  princ DECIMAL(18, 2), 
  intr  DECIMAL(18, 2), 
  sfvan DECIMAL(18, 2), 
  mtot  DECIMAL(18, 2)) 
AS 
  BEGIN 
      DECLARE @lstf AS INT 
      DECLARE @dsi AS VARCHAR(30) 

      SELECT @dsi = CN.fdgisn 
      FROM   [asvark].dbo.contracts CN 
      WHERE  CN.fdgcode = @loanid 

      SELECT @lstf = Max(finc) 
      FROM   [asvark].[dbo].[agrschedule] 
      WHERE  fagrisn = @dsi 
             AND Datediff(d, fdate, @rdate) >= 0 

      INSERT INTO @graph 
      SELECT prin.fdate, 
             prin.fsum               princ, 
             Isnull(Sint.fsum, 0)    intr, 
             Isnull(SFval.fsum, 0)   sfvam, 
             prin.fsum + Isnull(Sint.fsum, 0) 
             + Isnull(SFval.fsum, 0) mtot 
      FROM   [asvark].[dbo].[agrschedulevalues] prin 
             CROSS apply (SELECT fdate 
                          FROM   [asvark].[dbo].[agrschedule] 
                          WHERE  fagrisn = @dsi 
                                 AND finc = @lstf 
                                 AND ftype <> 7) dc 
             OUTER apply (SELECT Max(finc) mx 
                          FROM   [asvark].[dbo].[agrschedule] 
                          WHERE  fagrisn = @dsi 
                                 AND fdate <= dc.fdate 
                                 AND ftype = 7) sff 
             OUTER apply (SELECT Sum(fsum) AS fSUM 
                          FROM   [asvark].[dbo].[agrschedulevalues] 
                          WHERE  fagrisn = @dsi 
                                 AND fvaluetype = 7 
                                 AND fdate = prin.fdate 
                                 AND finc = sff.mx) SFval 
             OUTER apply (SELECT Sum(fsum) AS fSUM 
                          FROM   [asvark].[dbo].[agrschedulevalues] 
                          WHERE  fagrisn = @dsi 
                                 AND fvaluetype = 2 
                                 AND fdate = prin.fdate 
                                 AND finc = @lstf) Sint 
      WHERE  prin.fagrisn = @dsi 
             AND prin.fvaluetype = 1 
             AND prin.finc = @lstf 

      RETURN 
  END 