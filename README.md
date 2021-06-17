# Cálculo da estimativa do RAI em SP
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

Nota: Para englobar o estado de SP, são necessários os tiles 12_11, 13_11 e 13_12 de cada base GHS. Os tiles podem ser agrupados em único arquivo através da operação `merge` da biblioteca GDAL pelo QGIS. O arquivo GHS-SMOD precisará também ser reamostrado para ser compatível com o GHS-POP, o que pode ser feito através do operados `r.resample` da biblioteca GRASS pelo QGIS. Recomenda-se também remover dos rasters as áreas fora do estado de São Paulo através do operador `Clip raster by extent` da biblioteca GDAL pelo QGIS. Os comandos a seguir assumem que os arquivos foram salvos como `data/ghs_pop/ghs_pop_sp.tiff` e `data/ghs_smod/ghs_smod_sp.tiff`, ambos em uma grade de 250m e englobando todo o estado de SP.

Em seguida, para adicionar os arquivos vetoriais ao banco pode-se utilizar o PostGIS Shapefile Importer, lembrando de associar os SRIDs a cada arquivo. Os comandos a seguir assumem que os arquivos foram importados com os seguintes nomes:

1. `municipios` (EPSG:4674)
2. `setores_censitarios` (EPSG:4674)
3. `osm_roads` (EPSG:4326)

Após importadas, as tabelas precisam ter seus SRID alterados, para que sejam compatíveis e em um sistema projetado (por exempo o EPSG 32723). Isso pode ser realizado através do seguinte comando:

```
ALTER TABLE <tabela>
  ALTER COLUMN geom
  TYPE geometry(MultiPolygon, 32723)
  USING ST_Transform(geom, 32723);
```

Para a importação dos arquivos raster, pode-se utilizar a ferramenta `raster2pgsql` (os arquivos GHS são fornecidos com SRID 54009):

```
raster2pgsql -s 54009 -I -C -r -t 250x250 .\data\ghs_pop\ghs_pop_sp.tif public.ghs_pop > ghs_pop.sql
raster2pgsql -s 54009 -I -C -r -t 250x250 .\data\ghs_smod\ghs_smod_sp.tif public.ghs_smod > ghs_smod.sql
psql -U <usuário> -d sp_rai -f ghs_pop.sql
psql -U <usuário> -d sp_rai -f ghs_smod.sql
```

## Execução

Existe um arquivo `.sql` para cada um dos oito cenários para os quais o RAI pode ser estimado:

1. Grade de população GHS-POP, Áreas rurais identificadas pelos setores censitários, definição restrita de estradas:
    `rai_ghs_cens_restrito.sql`
3. Grade de população GHS-POP, Áreas rurais identificadas pelos setores censitários, definição abrangente de estradas:
    `rai_ghs_cens_abrang.sql`
6. Grade de população GHS-POP, Áreas rurais identificadas pelo GHS-SMOD, definição restrita de estradas:
    `rai_ghs_smod_restrito.sql`
8. Grade de população GHS-POP, Áreas rurais identificadas pelo GHS-SMOD, definição abrangente de estradas:
    `rai_ghs_cens_abrang.sql`
10. Grade de população WorldPop, Áreas rurais identificadas pelos setores censitários, definição restrita de estradas:
    `rai_worldpop_cens_restrito.sql`
12. Grade de população WorldPop, Áreas rurais identificadas pelos setores censitários, definição abrangente de estradas:
    `rai_worldpop_cens_abrang.sql`
14. Grade de população WorldPop, Áreas rurais identificadas pelo GHS-SMOD, definição restrita de estradas:
    `rai_worldpop_smod_restrito.sql`
16. Grade de população WorldPop, Áreas rurais identificadas pelo GHS-SMOD, definição abrangente de estradas:
    `rai_worldpop_cens_abrang.sql`

A estimativa de cada caso pode ser feita pelo comando `psql -U <usuário> -d sp_rai -f <nome do arquivo>.sql`. Essa execução cria uma nova tabela no banco com o mesmo nome do arquivo, contendo uma linha para cada município com sua geometria e o RAI estimado. Algumas tabelas utilizadas nas etapas intermediárias da estimativa também são criadas.

Para visualizar os resultados, essa tabela pode ser importada para o QGIS, e de lá exportada como um shapefile caso desejado.
