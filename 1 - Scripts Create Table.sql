CREATE DATABASE Dimensional
GO
CREATE DATABASE Relacional
GO


CREATE TABLE Dimensional..DimensaoVendedor(
  ChaveVendedor int IDENTITY PRIMARY KEY,
  IDVendedor int,
  Nome Varchar(50),
  DataInicioValidade DATETIME not null,
  DataFimValidade DATETIME
);

CREATE TABLE Dimensional..DimensaoCliente(
  ChaveCliente int IDENTITY PRIMARY KEY,
  IDCliente int,
  Cliente Varchar(50),
  Estado Varchar(2),
  Sexo Char(1),
  Status Varchar(50),
  DataInicioValidade DATETIME not null,
  DataFimValidade DATETIME
);

CREATE TABLE Dimensional..DimensaoProduto(
  ChaveProduto int IDENTITY PRIMARY KEY,
  IDProduto int,
  Produto Varchar(100),
  DataInicioValidade DATETIME not null,
  DataFimValidade DATETIME
);

CREATE TABLE Dimensional..DimensaoTempo(
  ChaveTempo int IDENTITY PRIMARY KEY,
  Data DATETIME,
  Dia int,
  Mes int,
  Ano int,
  DiaSemana int,
  Trimestre int
);

CREATE TABLE Dimensional..FatoVendas(
  ChaveVendas int IDENTITY PRIMARY KEY,
  ChaveVendedor int,
  ChaveCliente int,
  ChaveProduto int,
  ChaveTempo int,
  Quantidade int,
  ValorUnitario Numeric(10,2),
  ValorTotal Numeric(10,2),
  Desconto Numeric(10,2)
);

CREATE TABLE Relacional..Vendedores(
  IDVendedor int IDENTITY PRIMARY KEY,
  Nome Varchar(50)
);

CREATE TABLE Relacional..Produtos(
  IDProduto int IDENTITY PRIMARY KEY,
  Produto Varchar(100),
  Preco Numeric(10,2)
);

CREATE TABLE Relacional..Clientes(
  IDCliente int IDENTITY PRIMARY KEY,
  Cliente Varchar(50),
  Estado Varchar(2),
  Sexo Char(1),
  Status Varchar(50)
);

CREATE TABLE Relacional..Vendas(
  IDVenda int IDENTITY PRIMARY KEY,
  IDVendedor int references Relacional..Vendedores (IDVendedor),
  IDCliente int references Relacional..Clientes (IDCliente),
  Data DATETIME,
  Total Numeric(10,2)
);
ALTER TABLE Relacional..Vendas ADD CONSTRAINT FKVENDASVENDEDOR FOREIGN KEY (IDVendedor) REFERENCES Relacional..Vendedores (IDVendedor);
ALTER TABLE Relacional..Vendas ADD CONSTRAINT FKVENDASCLIENTE FOREIGN KEY (IDCliente) REFERENCES Relacional..Clientes (IDCliente);

CREATE TABLE Relacional..ItensVenda (
    IDProduto int,
    IDVenda int,
    Quantidade int,
    ValorUnitario decimal(10,2),
    ValorTotal decimal(10,2),
	Desconto decimal(10,2),
    PRIMARY KEY (IDProduto, IDVenda)
);
ALTER TABLE Relacional..ItensVenda ADD CONSTRAINT FKITENSVENDASVENDEDOR FOREIGN KEY (IDProduto) REFERENCES Relacional..Produtos (IDProduto);
ALTER TABLE Relacional..ItensVenda ADD CONSTRAINT FKITENSVENDASCLIENTE FOREIGN KEY (IDVenda) REFERENCES Relacional..Vendas (IDVenda);