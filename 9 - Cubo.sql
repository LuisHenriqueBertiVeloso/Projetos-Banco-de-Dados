IF OBJECT_ID('DIMENSIONAL..CUBOVENDAS', 'U') IS NOT NULL
	DROP TABLE DIMENSIONAL..CUBOVENDAS;

SELECT 
	CLI.CLIENTE,
	CLI.ESTADO,
	CLI.SEXO,
	CLI.STATUS,
	VENDA.QUANTIDADE,
	VENDA.VALORUNITARIO,
	VENDA.VALORTOTAL,
	VENDA.DESCONTO,
	PROD.PRODUTO,
	TEMPO.DATA,
	TEMPO.DIA,
	TEMPO.MES,
	TEMPO.ANO,
	TEMPO.TRIMESTRE,
	VENDEDOR.NOME
       
	INTO DIMENSIONAL..CUBOVENDAS
       
FROM DIMENSIONAL..DIMENSAOCLIENTE CLI
INNER JOIN DIMENSIONAL..FATOVENDAS VENDA
	ON VENDA.CHAVECLIENTE = CLI.CHAVECLIENTE
INNER JOIN DIMENSIONAL..DIMENSAOPRODUTO PROD
	ON PROD.CHAVEPRODUTO = VENDA.CHAVEPRODUTO
INNER JOIN DIMENSIONAL..DIMENSAOTEMPO TEMPO
	ON TEMPO.CHAVETEMPO = VENDA.CHAVETEMPO
INNER JOIN DIMENSIONAL..DIMENSAOVENDEDOR VENDEDOR
	ON VENDEDOR.CHAVEVENDEDOR = VENDA.CHAVEVENDEDOR

	select * from Dimensional..CUBOVENDAS
	select * from margem_relacional..Clientes


-----------------------------------------------------------------------------------------------------------------------------------------------------------------


	Merge margem_relacional..Clientes as DESTINO
using openrowset('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;hdr=yes;Database=C:\Users\USER\OneDrive\Área de Trabalho\bg_margem.xlsx;', [Clientes$]) as ORIGEM 
			ON DESTINO.Cliente = ORIGEM.Cliente 
		WHEN MATCHED THEN
			UPDATE SET
			DESTINO.Cliente = ORIGEM.Cliente,
			DESTINO.DS = ORIGEM.DS,
			DESTINO.DF = ORIGEM.DF,
			DESTINO.Fajoanis = ORIGEM.FAJOANIS,
			DESTINO.COMISSÃO = ORIGEM.COMISSÃO,
			DESTINO.DATE = ORIGEM.DATA,
			DESTINO.Cidade = ORIGEM.Cidade,
			DESTINO.ESTADO = ORIGEM.ESTADO,
			DESTINO.PAÍS = ORIGEM.PAÍS,
			DESTINO.MÊS = ORIGEM.Mês
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (Cliente, DS, DF, Fajoanis, Comissão, Date, Cidade, Estado, País, Mês)  
			VALUES (ORIGEM.Cliente, Origem.DS, Origem.DF, Origem.FAJOANIS, Origem.COMISSÃO, Origem.DATA, ORIGEM.Cidade, ORIGEM.ESTADO, ORIGEM.PAÍS, ORIGEM.MÊs)
		WHEN NOT MATCHED BY SOURCE THEN
		DELETE;
		
	
		Merge margem_relacional..config as DESTINO
using openrowset('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;hdr=yes;Database=C:\Users\USER\OneDrive\Área de Trabalho\bg_margem.xlsx;', [Custos$]) as ORIGEM 
			ON DESTINO.Produto = ORIGEM.Produto
		WHEN MATCHED THEN
			UPDATE SET
			DESTINO.Produto = Origem.Produto,
			DESTINO.Frete = Origem.Frete,
			DESTINO.Custo_Fixo = Origem.Custo_Fixo,
			DESTINO.Embalagem = Origem.Embalagem,
			DESTINO.Data = Origem.Data,
			DESTINO.Mês = Origem.Mês
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (Produto,Frete,Custo_Fixo,Embalagem,Data,Mês)  
			VALUES (ORIGEM.Produto, Origem.Frete, Origem.Custo_Fixo, Origem.Embalagem, Origem.Data, Origem.Mês)
		WHEN NOT MATCHED BY SOURCE THEN
		DELETE;

		
