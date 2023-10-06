

execute sys.sp_configure 'show advanced options',1 
reconfigure
execute sys.sp_configure 'ad hoc distributed queries',1
reconfigure
go

execute sys.sp_MSset_oledb_prop	'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1
execute sys.sp_MSset_oledb_prop	'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1
go

use margem_relacional
use margem_dimensional

/* Criei um procedimento para inserir de uma planilha que faz os custos dos produtos para dentro do SQL na base de dados relacional, atualizando dados j� existentes,
ou criando novos registros*/
CREATE PROCEDURE sp_cadastro_produto_relacional 
AS
BEGIN
	BEGIN TRAN
		Merge margem_relacional..produto as DESTINO
		using openrowset('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;hdr=yes;Database=C:\Users\USER\OneDrive\�rea de Trabalho\bg_margem.xlsx;', [Form$]) as ORIGEM 
			ON DESTINO.Produto = ORIGEM.Produto 
		WHEN MATCHED THEN
			UPDATE SET
			DESTINO.PRODUTO = ORIGEM.PRODUTO,
			DESTINO.Data = ORIGEM.DATA,
			DESTINO.Custo = ORIGEM.CUSTO,
			DESTINO.M�s = ORIGEM.M�s
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (Produto, Data, Custo, M�s) VALUES (ORIGEM.Produto,ORIGEM.Data,ORIGEM.Custo,ORIGEM.M�s);
	COMMIT TRAN
END;
----------------------------------------------------------------------------------------------------------------------------------------------------


/* Ap�s os produtos precisei fazer um Merge dos dados de Vendas para a tabela relacional*/
CREATE PROCEDURE sp_merge_vendas
AS 
BEGIN
BEGIN TRAN
MERGE margem_dimensional..vendas AS D
	USING OPENROWSET ('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;hdr=yes;Database=C:\Users\USER\OneDrive\�rea de Trabalho\bg_margem.xlsx;', [Vendas$]) AS O
		ON D.Cliente = O.Cliente and D.Data_Venda = O.Data and D.Produto = O.Produto
	WHEN MATCHED THEN
		UPDATE	
			SET D.ICMS = O.ICMS,
				D.PIS = O.PIS,
				D.COFINS = O.COFINS,
				D.QTDY_Venda = O.Quantidade,
				D.Total_Venda = O.Total,
				D.M�s = O.M�s
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (Cliente, Produto, Data_Venda, ICMS, PIS, COFINS, QTDY_Venda, Total_Venda, M�s) 
		VALUES (O.Cliente, O.Produto, O.Data, O.ICMS, O.PIS, O.COFINS, O.Quantidade, O.Total, O.M�s);
COMMIT TRAN
END;		

---------------------------------------------------------------------------------------------------------------------------------------
/* Aqui crio procedimentos para poder inserir ou atualizar clientes e configura��es dos produtos sem que haja necessidade de reescrever os scripts ou
importar de um arquivo.*/
CREATE PROCEDURE sp_in_cliente(
@Cliente varchar (50), 
@DF REAL, 
@DS REAL, 
@FAJOANIS REAL,  
@COMISSAO REAL,
@Rua varchar (255),
@Estado varchar (255),
@Pais varchar (255)
)
AS
BEGIN
	declare @result int
	set @result =  (select count(SKCLIENTE) from margem_relacional..clientes WHERE Cliente = 'Kachani')
	IF @result <= 0 and @DS >= 0 and @DF <> 0 and @FAJOANIS <> 0 and @COMISSAO >= 0
	BEGIN
		BEGIN TRANSACTION
		INSERT INTO margem_relacional..Clientes (Cliente, DF, DS, Fajoanis, Comiss�o, Date, M�s, Cidade, Estado, Pa�s) 
			VALUES (@Cliente, @DF, @DS, @FAJOANIS, @COMISSAO, getdate(), datepart(month,getdate()),@Rua,@Estado,@Pais)
		COMMIT TRANSACTION
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		PRINT 'Transa��o n�o segue com as regras, o Cliente j� tem cadastro ou valores DS, DF, FAJO, COMISS�O fogem � regra de neg�cio'
		COMMIT TRAN	
	END;
END;

----------------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE sp_up_cliente (
@Cliente varchar (50), 
@DF REAL, 
@DS REAL, 
@FAJOANIS REAL,  
@COMISSAO REAL,
@Cidade varchar (255),
@Estado varchar (255),
@Pais varchar (255)
)
AS
BEGIN

	DECLARE @DATA date
	DECLARE @M�s int
	DECLARE @RESULT INT
	SET @DATA = GETDATE()
	SET @M�s = DATEPART(MONTH,GETDATE())
	SET @RESULT = (SELECT COUNT(SKCLIENTE) FROM MARGEM_RELACIONAL..CLIENTES WHERE CLIENTE = @Cliente)
	IF @RESULT >= 0 and @DS >= 0 and @DF <> 0 and @FAJOANIS <> 0 and @COMISSAO >= 0
	BEGIN 
		BEGIN TRANSACTION
		UPDATE margem_relacional..Clientes 
			SET		
				DS = @DS,
				DF = @DF,
				FAJOANIS = @FAJOANIS,
				Comiss�o = @COMISSAO,
				Date = @Data,
				M�s = @M�s,
				Cidade = @Cidade,
				Estado = @Estado,
				Pa�s = @Pais
			WHERE Cliente = @Cliente
		COMMIT TRANSACTION
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		PRINT 'Transa��o n�o segue com as regras'
		COMMIT TRAN
	END;
END;
--------------------------------------------------------------------------------------------------------------------------------------


CREATE PROCEDURE sp_in_config(
@Produto varchar(255),
@Custo_Fixo REAL,
@Frete REAL,
@Embalagem REAL
)  
AS
BEGIN
	DECLARE @RESULT INT
	DECLARE @DATA date
	DECLARE @M�S int
	SET @DATA = GETDATE()
	SET @M�S = DATEPART(MONTH,GETDATE())
	SET @RESULT = (SELECT COUNT(UKCONFIG) FROM margem_relacional..CONFIG WHERE Produto = @Produto)
	IF @result <= 0 and @Custo_Fixo > 0 and @Frete > 0 and @Embalagem >0
		BEGIN
			BEGIN TRAN
				INSERT INTO margem_relacional..config (Produto, Custo_Fixo, Frete, Embalagem, Data, M�s)
					VALUES (@Produto, @Custo_Fixo, @Frete, @Embalagem, @DATA, @M�S)
			COMMIT TRAN
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		ROLLBACK TRANSACTION
		PRINT 'Transa��o n�o segue com as regras'
	END;
END;

---------------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE sp_up_config (
@Produto varchar(255),
@Custo_Fixo REAL,
@Frete REAL,
@Embalagem REAL
)  
AS
BEGIN
	DECLARE @RESULT INT
	DECLARE @DATA date
	DECLARE @M�s int
	SET @DATA = GETDATE()
	SET @M�s = DATEPART(MONTH,GETDATE())
	SET @RESULT = (SELECT COUNT(UKCONFIG) FROM MARGEM_RELACIONAL..CONFIG WHERE PRODUTO = @Produto)
	IF @RESULT >= 0 and @Custo_Fixo > 0 and @Frete > 0 and @Embalagem > 0 
	BEGIN 
		BEGIN TRANSACTION
		UPDATE margem_relacional..Config 
			SET		
				Custo_Fixo = @Custo_Fixo,
				Frete = @Frete,
				Embalagem = @Embalagem,
				Data = @Data,
				M�s = @M�s
			WHERE Produto = @Produto
		COMMIT TRANSACTION
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		PRINT 'Transa��o n�o segue com as regras'
		COMMIT TRAN
	END;
END;


-------------------------------------------------------------------------------------------------------------------------------------------

/*J� nessa parte, desenvolvi triggers para fazer um merge de Produtos, Clientes e Config para as tabelas dimensional onde 
quando criado as tabelas, elas aceitam dados repeditos*/
CREATE TRIGGER tr_in_up_cliente
ON margem_relacional..Clientes 
AFTER UPDATE, INSERT
AS
	BEGIN TRANSACTION
	MERGE margem_dimensional..Clientes AS D
		USING margem_relacional..Clientes AS O
		 ON D.Cliente = O.Cliente and  D.M�s = O.M�s
		WHEN MATCHED THEN	
			UPDATE SET 
				D.Cliente = O.Cliente, 
				D.DF = O.DF, 
				D.DS = O.DS, 
				D.Fajoanis = O.Fajoanis, 
				D.Comiss�o = O.Comiss�o,
				D.Cidade = O.Cidade,
				D.Estado = O.Estado,
				D.Pa�s = O.Pa�s
		WHEN NOT MATCHED BY TARGET
		THEN
			INSERT (Cliente, DF, DS, Fajoanis, Comiss�o, Date, M�s, Cidade, Estado, Pa�s) 
				VALUES (O.Cliente, O.DF, O.DS, O.Fajoanis, O.Comiss�o, O.Date, O.M�s, O.Cidade, O.Estado, O.Pa�s);
		COMMIT TRANSACTION
		PRINT 'Carga de Clientes para dimens�o Clientes efetivada com sucesso'

------------------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER tr_in_up_produto
ON margem_relacional..produto
AFTER UPDATE, INSERT
AS
	BEGIN TRAN
		MERGE margem_dimensional..produto AS D
			USING margem_relacional..produto AS O ON D.Produto = O.Produto and D.M�s = O.M�s
		WHEN MATCHED THEN
		UPDATE SET
			D.Custo = O.Custo, 
			D.Data = O.Data
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (Produto, Custo, Data, M�s) VALUES (O.Produto, O.Custo, O.Data, O.M�s);
	COMMIT TRAN
	PRINT 'Carga de Produtos para Dimens�o Produtos efetivada com sucesso'


-----------------------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER tr_in_up_config
ON margem_relacional..config
AFTER UPDATE, INSERT
AS
	BEGIN TRAN	
		MERGE margem_dimensional..config AS D
			USING margem_relacional..config as O
				ON D.Produto = O.Produto and D.M�s = O.M�s
		WHEN MATCHED THEN
			UPDATE SET 
				D.Produto = O.Produto,
				D.Custo_Fixo = O.Custo_Fixo,
				D.Frete = O.Frete,
				D.Embalagem = O.Embalagem
		WHEN NOT MATCHED BY TARGET THEN
				INSERT (Produto, Custo_Fixo, Frete, Embalagem, Data, M�s) 
				VALUES (O.Produto, O.Custo_Fixo, O.Frete, O.Embalagem, O.Data, O.M�s);
	COMMIT TRAN
	PRINT 'Carga de Configura��es para a Dimens�o Configura��es efetivada com sucesso'

---------------------------------------------------------------------------------------------------------------------------------------------

/*Aqui desenolvi um procedimento para criar uma tabela cubo com todas as informa��es necess�rias para trabalho no Power BI*/
create procedure sp_create_cubo
AS 
BEGIN
IF OBJECT_ID('margem_dimensional..cubo', 'U') IS NOT NULL
		DROP TABLE margem_dimensional..cubo;
BEGIN TRAN
		SELECT 
			V.UKVENDA,
			V.Cliente,
			V.Produto,
			V.Data_Venda,
			V.ICMS,
			V.PIS,
			V.COFINS,
			V.Total_Venda,
			V.QTDY_Venda,
			V.M�s, P.Custo,
			Cn.Custo_Fixo,
			Cn.Frete,
			Cn.Embalagem,
			C.DS,
			C.DF,
			C.Fajoanis,
			C.Comiss�o
	 
			INTO margem_dimensional..cubo
       
		FROM margem_dimensional..vendas V
		INNER JOIN margem_dimensional..Clientes C
			ON C.Cliente = V.Cliente and C.M�s = V.M�s
		INNER JOIN margem_dimensional..produto P
			ON P.Produto = V.Produto and P.M�s = V.M�s
		INNER JOIN margem_dimensional..config Cn
			ON Cn.Produto = V.Produto and Cn.M�s = V.M�s
COMMIT TRAN
BEGIN TRAN
		alter table margem_dimensional..cubo add PKCUBOPRO varchar (650)
		update margem_dimensional..cubo set PKCUBOPRO = REPLACE(Produto,'-1', '')
		update margem_dimensional..cubo set PKCUBOPRO = REPLACE(PKCUBOPRO,'-2', '')
		update margem_dimensional..cubo set PKCUBOPRO = REPLACE(PKCUBOPRO,'-3', '')
		update margem_dimensional..cubo set PKCUBOPRO = REPLACE(PKCUBOPRO,'-4', '')
		--alter table margem_dimensional..cubo add ESTADO varchar(255)
		--update tb set tb.ESTADO = tbl.Estado from margem_dimensional..cubo tb inner join margem_dimensional..Clientes tbl on tb.Cliente = tbl.Cliente
COMMIT TRAN
BEGIN TRAN		

		UPDATE margem_dimensional..cubo set DS = 0.15 WHERE Cliente like 'Jolimode%' and M�s > 8 and Produto like '%IGUACOLOR%'
		
		UPDATE margem_dimensional..cubo set DS = 0.15 WHERE Cliente like 'Jolimode%' and M�s > 8 and Produto like '%PI026%'

		UPDATE margem_dimensional..cubo set DS = 0 WHERE Cliente like 'Fajoanis%' and M�s = 8

COMMIT TRAN
BEGIN TRAN

		alter table margem_dimensional..cubo ADD CV AS ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda))
		alter table margem_dimensional..cubo ADD DS_total AS (DS*(Total_Venda))
		alter table margem_dimensional..cubo ADD DF_total AS (DF*(Total_Venda))
		alter table margem_dimensional..cubo ADD Fajoanis_total AS (Fajoanis*(Total_Venda))
		alter table margem_dimensional..cubo ADD Lucro AS ((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda)))
		alter table margem_dimensional..cubo ADD Comiss�o_Total AS (((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda)))*Comiss�o)
		alter table margem_dimensional..cubo ADD Margem AS (((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda))) - (((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda)))*Comiss�o))

COMMIT TRAN
BEGIN TRAN
		alter table margem_dimensional..cubo add TIPO varchar(255)

		update margem_dimensional..cubo set TIPO = left(produto, 2)
COMMIT TRAN
		PRINT 'Criada Tabela Cubo'
		SELECT * FROM margem_dimensional..cubo
END;

------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Aqui criei uma fun��o para verificar de forma r�pida, a margem de qualquer m�s para qualquer pedido do Gestor que costumava pedir com frequ�ncia e
a resposta vinha de forma demorada*/

create function percentual_margem (
@M�s int)
RETURNS REAL
AS
BEGIN
DECLARE @MARGEM REAL
SELECT @MARGEM = (sum(Margem)/sum(Total_Venda)*100) from margem_dimensional..cubo WHERE M�s = @M�s
RETURN @MARGEM
END

-------------------------------------------------------------------------------------------------------------------------------------------------------


select dbo.percentual_margem (2) 


--------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure sp_pesquisa_margem_cliente(@Cliente varchar(255), @M�s int)
AS
BEGIN

SELECT Cliente, 
(SUM(Margem)/SUM(Total)*100) as Margem,
M�s

FROM margem_dimensional..cubo 

WHERE Cliente like @Cliente and M�s = @M�s 

GROUP BY Cliente, M�s
END;


exec sp_create_cubo



SELECT UKVENDA, Margem,DS_total,DS,CV,Total_Venda FROM margem_dimensional..cubo WHERE M�S = 8