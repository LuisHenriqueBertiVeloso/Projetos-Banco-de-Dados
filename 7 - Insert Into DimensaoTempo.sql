declare @Inicio datetime = '19700101',
    @Fim datetime = '20301231',
    @Intervalo int = 1

;WITH Sequencia AS
(
    SELECT
       @Inicio AS StartRange, 
       DATEADD(DAY, @Intervalo, @Inicio) AS EndRange
    UNION ALL
    SELECT
      EndRange, 
      DATEADD(DAY, @Intervalo, EndRange)
    FROM Sequencia 
    WHERE DATEADD(DAY, @Intervalo, EndRange) <= @Fim
)
INSERT INTO Dimensional..DimensaoTempo(data, dia, mes, ano, diasemana, trimestre)
SELECT StartRange as data, DATEPART(DAY, StartRange) as dia, month(startrange) as mes, year(startrange) as ano, DATEPART(dw, startrange) as diasemana, datepart(qq, startrange) as trimestre FROM Sequencia OPTION (MAXRECURSION 0);