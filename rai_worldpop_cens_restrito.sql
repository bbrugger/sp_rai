CREATE TABLE IF NOT EXISTS municipios_rural_cens AS
	SELECT 
		munic.cd_mun,
		ST_Union(setor.geom) AS geom
	FROM
		municipios AS munic,
		setores_censitarios AS setor
	WHERE
		setor.cd_mun = munic.cd_mun
		AND setor.cd_sit IN ('5', '6', '7', '8')
	GROUP BY
		munic.cd_mun;


CREATE TABLE IF NOT EXISTS access_area_cens_restrito AS
	SELECT	
		municipios_rural_cens.cd_mun,
		ST_Intersection(
			ST_Union(ST_Buffer(osm_roads.geom, 2000)),
			municipios_rural_cens.geom
		) AS geom
	FROM
		municipios_rural_cens,
		osm_roads
	WHERE
		ST_Intersects(
			osm_roads.geom,
			municipios_rural_cens.geom
		)
	AND osm_roads.fclass IN (
		'primary',
		'primary_link',
		'secondary',
		'secondary_link',
		'tertiary',
		'tertiary_link',
		'trunk',
		'motorway'
	)
	GROUP BY municipios_rural_cens.cd_mun, municipios_rural_cens.geom;


CREATE TABLE IF NOT EXISTS rai_worldpop_cens_restrito AS
	SELECT 
		mun.cd_mun,
		mun.nm_mun,
		mun.geom,
		(
			SUM((ST_SummaryStats(ST_Clip(pop.rast, ST_Transform(acc.geom, 4326), 0.0))).sum)
			/ SUM((ST_SummaryStats(ST_Clip(pop.rast, ST_Transform(rur.geom, 4326), 0.0))).sum)
		) AS rai
	FROM
		worldpop AS pop,
		municipios AS mun,
		municipios_rural_cens AS rur,
		access_area_cens_restrito AS acc
	WHERE
		mun.cd_mun = rur.cd_mun
		AND mun.cd_mun = acc.cd_mun
		AND ST_Intersects(pop.rast, ST_Transform(mun.geom, 4326))
	GROUP BY mun.cd_mun, mun.nm_mun, mun.geom;
