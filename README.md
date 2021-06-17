# Cálculo do RAI em SP
Dados e comandos para estimar o Índice de Acesso Rural (RAI) para os municípios do estado de São Paulo

## Introdução

## Instalação

1. Instale o [PostgreSQL](https://www.postgresql.org/) e crie um banco com as extensões [PostGIS](https://postgis.net/install/) habilitadas:

```
$ CREATE DATABASE sp_rai;
$ \c sp_rai
$ CREATE EXTENSION postgis;
$ CREATE EXTENSION postgis_raster;
```

2. Para visualização e preparação dos dados instale o [QGIS](https://www.qgis.org/en/site/)
3. Clone este repositório

## Carregando os dados

Para as estimativas são necessárias os seguintes dados: 

1. [Malha municipal do estado de São Paulo](https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/26565-malhas-de-setores-censitarios-divisoes-intramunicipais.html?=&t=downloads)
2. [Malha censitária do estado de São Paulo](https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/26565-malhas-de-setores-censitarios-divisoes-intramunicipais.html?=&t=downloads)
3. [Dados do OpenStreetMap para a região sudeste](https://download.geofabrik.de/south-america/brazil/sudeste.html)
4. [GHS-POP (250m)](https://ghsl.jrc.ec.europa.eu/download.php?ds=pop)
5. [GHS-SMOD (1km)](https://ghsl.jrc.ec.europa.eu/download.php?ds=smod)

Nota: Para englobar o estado de SP, são necessários os tiles 12_11, 13_11 e 13_12 de cada base GHS. Os tiles podem ser agrupados em único arquivo através da operação `merge` da biblioteca GDAL pelo QGIS. O arquivo GHS-SMOD precisará também ser reamostrado para ser compatível com o GHS-POP, o que pode ser feito através do operados `r.resample` da biblioteca GRASS pelo QGIS. Recomenda-se também remover dos rasters as áreas fora do estado de São Paulo através do operador `Clip raster by extent` da biblioteca GDAL pelo QGIS. Os comandos a seguir assumem que os arquivos foram salvos como `ghs_pop_sp.tiff` e `ghs_smod_sp.tiff`, ambos em uma grade de 250m e englobando todo o estado de SP.
