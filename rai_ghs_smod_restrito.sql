CREATE TABLE IF NOT EXISTS access_area_smod_restrito AS
	SELECT	
		municipios.cd_mun,
		ST_Intersection(
			ST_Union(ST_Buffer(osm_roads.geom, 2000)),
			municipios.geom
		) AS geom
	FROM
		municipios,
		osm_roads
	WHERE
		ST_Intersects(
			osm_roads.geom,
			municipios.geom
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
	GROUP BY municipios.cd_mun, municipios.geom;


CREATE TABLE IF NOT EXISTS rai_ghs_smod_restrito AS
	SELECT 
		mun.cd_mun,
		mun.nm_mun,
		mun.geom,
		(
			SUM((ST_SummaryStats(ST_Clip(pop.rast, ST_Transform(acc.geom, 54009), 0.0))).sum)
			/ SUM((ST_SummaryStats(ST_Clip(pop.rast, ST_Transform(mun.geom, 54009), 0.0))).sum)
		) AS rai
	FROM
		ghs_pop_rural AS pop,
		municipios AS mun,
		access_area_smod_restrito AS acc
	WHERE
		mun.cd_mun = acc.cd_mun
		AND ST_Intersects(pop.rast, ST_Transform(mun.geom, 54009))
	GROUP BY mun.cd_mun, mun.nm_mun, mun.geom;
