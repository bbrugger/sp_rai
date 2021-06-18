# Cálculo da estimativa do RAI em SP
Dados e comandos para estimar o Índice de Acesso Rural (RAI) para os municípios do estado de São Paulo

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
6. [WorldPop (100m)](https://www.worldpop.org/geodata/summary?id=24967)

Notas: 
- Para englobar o estado de SP, são necessários os tiles 12_11, 13_11 e 13_12 de cada base GHS. Os tiles podem ser agrupados em único arquivo através da operação `merge` da biblioteca GDAL pelo QGIS.
- O arquivo GHS-SMOD precisará também ser reamostrado para ser compatível com o GHS-POP, o que pode ser feito através do operados `r.resample` da biblioteca GRASS pelo QGIS.
- Recomenda-se também remover dos rasters as áreas fora do estado de São Paulo através do operador `Clip raster by extent` da biblioteca GDAL pelo QGIS. Os comandos a seguir assumem que os arquivos foram salvos como `data/ghs_pop/ghs_pop_sp.tiff` e `data/ghs_smod/ghs_smod_sp.tiff`, ambos em uma grade de 250m e englobando todo o estado de SP.
- Recomenda-se também realizar o clip do WorldPop para carregar apenas a área que engloba o estado de São Paulo.

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
raster2pgsql -s 54009 -I -C -r -t 250x250 .\data\worldpop\worldpop_sp.tif public.worldpop > worldpop.sql
psql -U <usuário> -d sp_rai -f ghs_pop.sql
psql -U <usuário> -d sp_rai -f worldpop.sql
```

Para utilizar a grade SMOD na identificação de áreas rurais, é preciso criar um novo arquivo raster a partir do `ghs_pop_sp.tif`, onde o valor de população será colocado como zero nas células onde o SMOD contém uma classe urbana, na grade 250m do GHS-POP. Isso pode ser realizado no QGIS através da calculadora raster. Após carregar ambos os arquivos `ghs_smod_sp.tif` e `ghs_pop_sp.tif` utilize a seguinte expressão na calculadora raster para criar um novo arquivo representando apenas a população rural: `"ghs_pop_sp@1"  *  ("ghs_smod_sp@1" < 20)`. Salve esse arquivo como `data/ghs_pop/ghs_pop_sp_rural.tiff` e carregue-o no Postgres:

```
raster2pgsql -s 54009 -I -C -r -t 250x250 .\data\ghs_pop\ghs_pop_sp_rural.tif public.ghs_pop_rural > ghs_pop_rural.sql
psql -U <usuário> -d sp_rai -f ghs_pop_rural.sql
```

## Execução

Existe um arquivo `.sql` para cada um dos seis cenários para os quais o RAI pode ser estimado:

1. Grade de população GHS-POP, Áreas rurais identificadas pelos setores censitários, definição restrita de estradas:
    `rai_ghs_cens_restrito.sql`
2. Grade de população GHS-POP, Áreas rurais identificadas pelos setores censitários, definição abrangente de estradas:
    `rai_ghs_cens_abrang.sql`
3. Grade de população GHS-POP, Áreas rurais identificadas pelo GHS-SMOD, definição restrita de estradas:
    `rai_ghs_smod_restrito.sql`
4. Grade de população GHS-POP, Áreas rurais identificadas pelo GHS-SMOD, definição abrangente de estradas:
    `rai_ghs_cens_abrang.sql`
5. Grade de população WorldPop, Áreas rurais identificadas pelos setores censitários, definição restrita de estradas:
    `rai_worldpop_cens_restrito.sql`
6. Grade de população WorldPop, Áreas rurais identificadas pelos setores censitários, definição abrangente de estradas:
    `rai_worldpop_cens_abrang.sql`

A estimativa de cada caso pode ser feita pelo comando `psql -U <usuário> -d sp_rai -f <nome do arquivo>.sql`. Essa execução cria uma nova tabela no banco com o mesmo nome do arquivo, contendo uma linha para cada município com sua geometria e o RAI estimado. Algumas tabelas utilizadas nas etapas intermediárias da estimativa também são criadas.

Para visualizar os resultados, essa tabela pode ser importada para o QGIS, e de lá exportada como um shapefile caso desejado.
