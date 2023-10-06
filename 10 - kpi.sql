IF OBJECT_ID('DIMENSIONAL..KPI', 'U') IS NOT NULL
	DROP TABLE DIMENSIONAL..KPI;

--CRIAMOS UMA TABELA PARA KPI
SELECT 
	TEMPO.MES AS MES,
	SUM(VENDAS.VALORTOTAL) AS REALIZADO
  
INTO DIMENSIONAL..KPI
       
FROM ( DIMENSIONAL..FATOVENDAS VENDAS
INNER JOIN DIMENSIONAL..DIMENSAOTEMPO TEMPO
ON (TEMPO.CHAVETEMPO = VENDAS.CHAVETEMPO))

GROUP BY TEMPO.MES
ORDER BY TEMPO.MES


--ADICIONA UMA COLUNA META
ALTER TABLE DIMENSIONAL..KPI ADD META NUMERIC

--ADICIONAMOS METAS POR MES
UPDATE DIMENSIONAL..KPI SET META = 220000   WHERE MES =1;
UPDATE DIMENSIONAL..KPI SET META = 220000   WHERE MES =2;
UPDATE DIMENSIONAL..KPI SET META = 230000   WHERE MES =3;
UPDATE DIMENSIONAL..KPI SET META = 235000   WHERE MES =4;
UPDATE DIMENSIONAL..KPI SET META = 240000   WHERE MES =5;
UPDATE DIMENSIONAL..KPI SET META = 250000   WHERE MES =6;
UPDATE DIMENSIONAL..KPI SET META = 255000   WHERE MES =7;
UPDATE DIMENSIONAL..KPI SET META = 260000   WHERE MES =8;
UPDATE DIMENSIONAL..KPI SET META = 262500   WHERE MES =9;
UPDATE DIMENSIONAL..KPI SET META = 265000   WHERE MES =10;
UPDATE DIMENSIONAL..KPI SET META = 267000   WHERE MES =11;
UPDATE DIMENSIONAL..KPI SET META = 270000   WHERE MES =12;

SELECT * FROM DIMENSIONAL..KPI