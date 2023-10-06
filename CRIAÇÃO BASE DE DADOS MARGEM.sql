

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

/* Criei um procedimento para inserir de uma planilha que faz os custos dos produtos para dentro do SQL na base de dados relacional, atualizando dados já existentes,
ou criando novos registros*/
CREATE PROCEDURE sp_cadastro_produto_relacional 
AS
BEGIN
	BEGIN TRAN
		Merge margem_relacional..produto as DESTINO
		using openrowset('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;hdr=yes;Database=C:\Users\USER\OneDrive\Área de Trabalho\bg_margem.xlsx;', [Form$]) as ORIGEM 
			ON DESTINO.Produto = ORIGEM.Produto 
		WHEN MATCHED THEN
			UPDATE SET
			DESTINO.PRODUTO = ORIGEM.PRODUTO,
			DESTINO.Data = ORIGEM.DATA,
			DESTINO.Custo = ORIGEM.CUSTO,
			DESTINO.Mês = ORIGEM.Mês
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (Produto, Data, Custo, Mês) VALUES (ORIGEM.Produto,ORIGEM.Data,ORIGEM.Custo,ORIGEM.Mês);
	COMMIT TRAN
END;
----------------------------------------------------------------------------------------------------------------------------------------------------


/* Após os produtos precisei fazer um Merge dos dados de Vendas para a tabela relacional*/
CREATE PROCEDURE sp_merge_vendas
AS 
BEGIN
BEGIN TRAN
MERGE margem_dimensional..vendas AS D
	USING OPENROWSET ('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;hdr=yes;Database=C:\Users\USER\OneDrive\Área de Trabalho\bg_margem.xlsx;', [Vendas$]) AS O
		ON D.Cliente = O.Cliente and D.Data_Venda = O.Data and D.Produto = O.Produto
	WHEN MATCHED THEN
		UPDATE	
			SET D.ICMS = O.ICMS,
				D.PIS = O.PIS,
				D.COFINS = O.COFINS,
				D.QTDY_Venda = O.Quantidade,
				D.Total_Venda = O.Total,
				D.Mês = O.Mês
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (Cliente, Produto, Data_Venda, ICMS, PIS, COFINS, QTDY_Venda, Total_Venda, Mês) 
		VALUES (O.Cliente, O.Produto, O.Data, O.ICMS, O.PIS, O.COFINS, O.Quantidade, O.Total, O.Mês);
COMMIT TRAN
END;		

---------------------------------------------------------------------------------------------------------------------------------------
/* Aqui crio procedimentos para poder inserir ou atualizar clientes e configurações dos produtos sem que haja necessidade de reescrever os scripts ou
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
		INSERT INTO margem_relacional..Clientes (Cliente, DF, DS, Fajoanis, Comissão, Date, Mês, Cidade, Estado, País) 
			VALUES (@Cliente, @DF, @DS, @FAJOANIS, @COMISSAO, getdate(), datepart(month,getdate()),@Rua,@Estado,@Pais)
		COMMIT TRANSACTION
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		PRINT 'Transação não segue com as regras, o Cliente já tem cadastro ou valores DS, DF, FAJO, COMISSÃO fogem à regra de negócio'
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
	DECLARE @Mês int
	DECLARE @RESULT INT
	SET @DATA = GETDATE()
	SET @Mês = DATEPART(MONTH,GETDATE())
	SET @RESULT = (SELECT COUNT(SKCLIENTE) FROM MARGEM_RELACIONAL..CLIENTES WHERE CLIENTE = @Cliente)
	IF @RESULT >= 0 and @DS >= 0 and @DF <> 0 and @FAJOANIS <> 0 and @COMISSAO >= 0
	BEGIN 
		BEGIN TRANSACTION
		UPDATE margem_relacional..Clientes 
			SET		
				DS = @DS,
				DF = @DF,
				FAJOANIS = @FAJOANIS,
				Comissão = @COMISSAO,
				Date = @Data,
				Mês = @Mês,
				Cidade = @Cidade,
				Estado = @Estado,
				País = @Pais
			WHERE Cliente = @Cliente
		COMMIT TRANSACTION
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		PRINT 'Transação não segue com as regras'
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
	DECLARE @MÊS int
	SET @DATA = GETDATE()
	SET @MÊS = DATEPART(MONTH,GETDATE())
	SET @RESULT = (SELECT COUNT(UKCONFIG) FROM margem_relacional..CONFIG WHERE Produto = @Produto)
	IF @result <= 0 and @Custo_Fixo > 0 and @Frete > 0 and @Embalagem >0
		BEGIN
			BEGIN TRAN
				INSERT INTO margem_relacional..config (Produto, Custo_Fixo, Frete, Embalagem, Data, Mês)
					VALUES (@Produto, @Custo_Fixo, @Frete, @Embalagem, @DATA, @MÊS)
			COMMIT TRAN
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		ROLLBACK TRANSACTION
		PRINT 'Transação não segue com as regras'
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
	DECLARE @Mês int
	SET @DATA = GETDATE()
	SET @Mês = DATEPART(MONTH,GETDATE())
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
				Mês = @Mês
			WHERE Produto = @Produto
		COMMIT TRANSACTION
	END;
	ELSE
	BEGIN
		BEGIN TRAN
		PRINT 'Transação não segue com as regras'
		COMMIT TRAN
	END;
END;


-------------------------------------------------------------------------------------------------------------------------------------------

/*Já nessa parte, desenvolvi triggers para fazer um merge de Produtos, Clientes e Config para as tabelas dimensional onde 
quando criado as tabelas, elas aceitam dados repeditos*/
CREATE TRIGGER tr_in_up_cliente
ON margem_relacional..Clientes 
AFTER UPDATE, INSERT
AS
	BEGIN TRANSACTION
	MERGE margem_dimensional..Clientes AS D
		USING margem_relacional..Clientes AS O
		 ON D.Cliente = O.Cliente and  D.Mês = O.Mês
		WHEN MATCHED THEN	
			UPDATE SET 
				D.Cliente = O.Cliente, 
				D.DF = O.DF, 
				D.DS = O.DS, 
				D.Fajoanis = O.Fajoanis, 
				D.Comissão = O.Comissão,
				D.Cidade = O.Cidade,
				D.Estado = O.Estado,
				D.País = O.País
		WHEN NOT MATCHED BY TARGET
		THEN
			INSERT (Cliente, DF, DS, Fajoanis, Comissão, Date, Mês, Cidade, Estado, País) 
				VALUES (O.Cliente, O.DF, O.DS, O.Fajoanis, O.Comissão, O.Date, O.Mês, O.Cidade, O.Estado, O.País);
		COMMIT TRANSACTION
		PRINT 'Carga de Clientes para dimensão Clientes efetivada com sucesso'

------------------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER tr_in_up_produto
ON margem_relacional..produto
AFTER UPDATE, INSERT
AS
	BEGIN TRAN
		MERGE margem_dimensional..produto AS D
			USING margem_relacional..produto AS O ON D.Produto = O.Produto and D.Mês = O.Mês
		WHEN MATCHED THEN
		UPDATE SET
			D.Custo = O.Custo, 
			D.Data = O.Data
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (Produto, Custo, Data, Mês) VALUES (O.Produto, O.Custo, O.Data, O.Mês);
	COMMIT TRAN
	PRINT 'Carga de Produtos para Dimensão Produtos efetivada com sucesso'


-----------------------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER tr_in_up_config
ON margem_relacional..config
AFTER UPDATE, INSERT
AS
	BEGIN TRAN	
		MERGE margem_dimensional..config AS D
			USING margem_relacional..config as O
				ON D.Produto = O.Produto and D.Mês = O.Mês
		WHEN MATCHED THEN
			UPDATE SET 
				D.Produto = O.Produto,
				D.Custo_Fixo = O.Custo_Fixo,
				D.Frete = O.Frete,
				D.Embalagem = O.Embalagem
		WHEN NOT MATCHED BY TARGET THEN
				INSERT (Produto, Custo_Fixo, Frete, Embalagem, Data, Mês) 
				VALUES (O.Produto, O.Custo_Fixo, O.Frete, O.Embalagem, O.Data, O.Mês);
	COMMIT TRAN
	PRINT 'Carga de Configurações para a Dimensão Configurações efetivada com sucesso'

---------------------------------------------------------------------------------------------------------------------------------------------

/*Aqui desenolvi um procedimento para criar uma tabela cubo com todas as informações necessárias para trabalho no Power BI*/
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
			V.Mês, P.Custo,
			Cn.Custo_Fixo,
			Cn.Frete,
			Cn.Embalagem,
			C.DS,
			C.DF,
			C.Fajoanis,
			C.Comissão
	 
			INTO margem_dimensional..cubo
       
		FROM margem_dimensional..vendas V
		INNER JOIN margem_dimensional..Clientes C
			ON C.Cliente = V.Cliente and C.Mês = V.Mês
		INNER JOIN margem_dimensional..produto P
			ON P.Produto = V.Produto and P.Mês = V.Mês
		INNER JOIN margem_dimensional..config Cn
			ON Cn.Produto = V.Produto and Cn.Mês = V.Mês
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

		UPDATE margem_dimensional..cubo set DS = 0.15 WHERE Cliente like 'Jolimode%' and Mês > 8 and Produto like '%IGUACOLOR%'
		
		UPDATE margem_dimensional..cubo set DS = 0.15 WHERE Cliente like 'Jolimode%' and Mês > 8 and Produto like '%PI026%'

		UPDATE margem_dimensional..cubo set DS = 0 WHERE Cliente like 'Fajoanis%' and Mês = 8

COMMIT TRAN
BEGIN TRAN

		alter table margem_dimensional..cubo ADD CV AS ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda))
		alter table margem_dimensional..cubo ADD DS_total AS (DS*(Total_Venda))
		alter table margem_dimensional..cubo ADD DF_total AS (DF*(Total_Venda))
		alter table margem_dimensional..cubo ADD Fajoanis_total AS (Fajoanis*(Total_Venda))
		alter table margem_dimensional..cubo ADD Lucro AS ((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda)))
		alter table margem_dimensional..cubo ADD Comissão_Total AS (((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda)))*Comissão)
		alter table margem_dimensional..cubo ADD Margem AS (((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda))) - (((Total_Venda) - ICMS - PIS - COFINS - ((Custo + Frete + Embalagem + Custo_Fixo)*(QTDY_Venda)) - (DS*(Total_Venda)) -  (DF*(Total_Venda)) - (Fajoanis*(Total_Venda)))*Comissão))

COMMIT TRAN
BEGIN TRAN
		alter table margem_dimensional..cubo add TIPO varchar(255)

		update margem_dimensional..cubo set TIPO = left(produto, 2)
COMMIT TRAN
		PRINT 'Criada Tabela Cubo'
		SELECT * FROM margem_dimensional..cubo
END;

------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Aqui criei uma função para verificar de forma rápida, a margem de qualquer mês para qualquer pedido do Gestor que costumava pedir com frequência e
a resposta vinha de forma demorada*/

create function percentual_margem (
@Mês int)
RETURNS REAL
AS
BEGIN
DECLARE @MARGEM REAL
SELECT @MARGEM = (sum(Margem)/sum(Total_Venda)*100) from margem_dimensional..cubo WHERE Mês = @Mês
RETURN @MARGEM
END

-------------------------------------------------------------------------------------------------------------------------------------------------------


select dbo.percentual_margem (2) 


--------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure sp_pesquisa_margem_cliente(@Cliente varchar(255), @Mês int)
AS
BEGIN

SELECT Cliente, 
(SUM(Margem)/SUM(Total)*100) as Margem,
Mês

FROM margem_dimensional..cubo 

WHERE Cliente like @Cliente and Mês = @Mês 

GROUP BY Cliente, Mês
END;


exec sp_create_cubo



SELECT UKVENDA, Margem,DS_total,DS,CV,Total_Venda FROM margem_dimensional..cubo WHERE MÊS = 8