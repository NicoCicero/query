USE [emt_desarrollo]															
GO															
/****** Object:  StoredProcedure [dbo].[wf_p_out_TECNOVOZ]    Script Date: 09/02/2026 10:36:47 ******/															
SET ANSI_NULLS ON															
GO															
SET QUOTED_IDENTIFIER OFF															
GO															
															
ALTER PROCEDURE [dbo].[wf_p_out_TECNOVOZ]															
(															
											@v_fec_proceso_in		DATETIME,		
											@v_usu_id_in			INT,	
											@v_cat_nombre_corto		VARCHAR(10),		
											@v_cod_ret				INT OUT
)															
AS  															
															
SET NOCOUNT ON  															
--SP 20210201 Se modifica el SP para parametrizar los escenarios y acciones que viajan al TECNOVOZ.															
--VDO 2015/12/17 paq_204 Se ajusta por Telefonos MACRO en novedades de Telefonos															
--VDO 2014/06/26 se corrige y reemplaza el calculo de deuda total y se optimiza deuda vencida															
--MLG -- 2013 Agosto															
#¿NOMBRE?															
#¿NOMBRE?															
															
#¿NOMBRE?															
#¿NOMBRE?															
#¿NOMBRE?															
--declare @v_fec_proceso_in		DATETIME													
---------------------------------------------------------------------															
DECLARE @prc_nombre_corto varchar(10)															
DECLARE @usu_id            INT															
															
#¿NOMBRE?															
SET @prc_nombre_corto = 'OUT_TCNVOZ'															
  															
#¿NOMBRE?															
SET @usu_id = ISNULL(@v_usu_id_in, 1)															
---------------------------------------------------------------------  															
DECLARE @kit_id VARCHAR(255)															
SELECT TOP 1 @kit_id = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'KIT_ID' AND prt_baja_fecha IS NULL															
DECLARE @car_id VARCHAR(255)															
SELECT TOP 1 @car_id = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'CAT_ID' AND prt_baja_fecha IS NULL															
---------------------------------------------------------------------  															
DECLARE @fecha_proceso DATETIME															
  															
-- Si no se definio la fecha de proceso en el parametro, la tomo del parametro															
IF @v_fec_proceso_in IS NULL 															
	BEGIN  														
	SELECT TOP 1 @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECPRO' AND prt_baja_fecha IS NULL														
															
	#¿NOMBRE?														
	IF @fecha_proceso IS NULL OR ISDATE(@fecha_proceso)=0  														
	BEGIN  														
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','PROCESO GENERACION ARCHIVO CLIENTES A TECNOVOZ - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113) , @usu_id, Null, null													
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','PROCESO ABORTADO - No existe fecha de proceso ' + CONVERT(CHAR(20),GETDATE(),113), @usu_id, Null, null													
		SELECT @v_cod_ret = -1000  													
		RETURN  													
	END  														
	END  														
ELSE  															
	SET @fecha_proceso = @v_fec_proceso_in														
															
DECLARE @v_est_id_REFIPEN INT															
select @v_est_id_REFIPEN = est_id from wf_estados where est_nombre_corto = 'REFIPEN' and est_baja_fecha is null															
															
 declare @v_mul_age varchar(255)															
 select @v_mul_age = prt_valor from wf_parametros where prt_nombre_corto='c.agencia'															
															
---------------------------------------------------------------------  															
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'I','PROCESO GENERACION ARCHIVO CLIENTES A TECNOVOZ - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@usu_id, Null, null															
---------------------------------------------------------------------  															
TRUNCATE TABLE macro_out_TECNOVOZ															
TRUNCATE TABLE macro_out_TECNOVOZ_aux_TEL															
TRUNCATE TABLE macro_out_TECNOVOZ_aux_LT															
															
DELETE FROM add_tecnovoz WHERE atz_fec_arch = @fecha_proceso															
															
DECLARE @atz_id INT															
SELECT @atz_id = MAX(atz_id) FROM add_tecnovoz															
SET @atz_id = ISNULL(@atz_id ,0)															
UPDATE id_numeracion SET idn_ultimo_id = @atz_id WHERE idn_tabla = 'add_tecnovoz'															
---------------------------------------------------------------------  															
#¿NOMBRE?															
/*DECLARE @age_id_GESTIVA INT															
SELECT TOP 1 @age_id_GESTIVA = age_id FROM agencias WHERE age_cod = 'AGMC' AND age_baja_fecha IS NULL															
*/															
---------------------------------------------------------------------  															
-- busco los escenarios correspondientes a Mora Temprana II Individuos, Mora Pre Legal I, Mora Pre Legal II															
--Y RDT (146-T2RTD) 08-2018															
															
DECLARE @tab_ESC TABLE (esc_id INT)															
INSERT INTO @tab_ESC															
	SELECT esc_id														
	FROM wf_escenarios 														
	WHERE esc_baja_fecha IS NULL AND ESC_OBS = 'envio_tecnovoz'														
															
/* SP															
	AND esc_nombre_corto in (														
    'MTIMA',--VD_paq_130_20121011															
	'MT2MA', 	'MT2PS',													
    'MT2PM',--VD_paq_130_20121011															
	'MT2J', 	'MPLIJ', 	'MPIMA', 	'MPIPS', 	'MPL2J', 	'MP2MA',  	'MP2PS',	'MAMA',							
	'MAPS', 	'MAJ', 	'MAMC', 	'MAA', 	'MAPM', 	'MTIPS', 	'MTIJ',      --agrego el nuevo esc refi								
	'REFC' ,  														
--agrego nuevos esc 16-03-2018															
'CEST', 'EAAMI',															
--agrego nuevos esc 13-04-2018															
'EGENA', 'EPA1I', 'EPA2I', 'EPA3I', 'EAEI1', 'EAEI2', 'EAEI3',															
--agregado en 08-2018															
'RTD',		'MAPM', 'MPLPM',													
--agregar creditos baja renta 14-02-2020															
'MACBR', 'MT1BR', 'MT2BR' )															
	AND (ISNULL(@kit_id,'') = '' OR @kit_id LIKE '%,' + convert(varchar,esc_kit) + ',%')														
*/															
---------------------------------------------  															
#¿NOMBRE?															
															
DECLARE @tab_LT TABLE (est_id INT)															
INSERT INTO @tab_LT															
SELECT est_id															
FROM wf_estados															
WHERE est_baja_fecha IS NULL and est_obs = 'envio_tecnovoz'															
															
/* SP															
AND est_nombre_corto IN ('LLMANUA','GESPENIND','REFU', 'PREMIUM')															
--- SIN CESE DE GESTION - 04/06/2013 AND est_nombre_corto IN ('LLMANUA','GESPENIND','CESEGES','REFU', 'PREMIUM')															
*/															
--------------------------------------------------------------------- 															
															
--Busco los IDs de los tipos de acciones LLamado Manual, Llamado Entrante y Llamado Automatico I y II															
#¿NOMBRE?															
DECLARE @tac_LLM INT, @tac_LLE INT, @tac_LLAI INT, @tac_LLAII INT															
SELECT TOP 1 @tac_LLM = tac_id FROM tipos_acciones WHERE tac_nombre_corto = 'LLM' AND tac_baja_fecha IS NULL															
SELECT TOP 1 @tac_LLE = tac_id FROM tipos_acciones WHERE tac_nombre_corto = 'LLE' AND tac_baja_fecha IS NULL															
SELECT TOP 1 @tac_LLAI = tac_id FROM tipos_acciones WHERE tac_nombre_corto = 'LLAI' AND tac_baja_fecha IS NULL															
SELECT TOP 1 @tac_LLAII = tac_id FROM tipos_acciones WHERE tac_nombre_corto = 'LLAII' AND tac_baja_fecha IS NULL															
---------------------------------------------------------------------  															
DECLARE @tab_cotizac TABLE(															
	tca_mon INT,														
	tca_valor NUMERIC(16,4) NULL)														
															
															
INSERT INTO @tab_cotizac															
SELECT tt.tca_mon, convert(numeric(16,4),tt.tca_valor)															
FROM tipos_cambios tt															
WHERE tt.tca_baja_fecha IS NULL															
AND tt.tca_fecha = (SELECT MAX(t.tca_fecha) FROM tipos_cambios t WHERE t.tca_mon = tt.tca_mon AND t.tca_fecha <= @fecha_proceso)  															
															
#¿NOMBRE?															
insert into macro_out_TECNOVOZ															
select 															
out_fec_archivo           = 'fec_arch'    ,      															
out_orden_LT              = 'orden_LT'    ,         															
out_tipo                  = 'tp'          ,       															
out_per_id                = '0'      ,  															
out_per_cli               = 'per_cli'     ,         															
out_per_nombre            = 'per_nombre'  ,         															
out_documento             = 'documento'   ,         															
out_tel_1                 = 'tel_1'       ,         															
out_tel_2                 = 'tel_2'       ,         															
out_tel_3                 = 'tel_3'       ,         															
out_tel_4                 = 'tel_4'       ,         															
out_tel_5                 = 'tel_5'       ,         															
out_deuda_total           = 'deuda_total' ,         															
out_deuda_venc            = 'deuda_venc'  ,         															
out_dias_mora             = 'dias_mora'   ,         															
out_sucursal              = 'sucursal'    ,         															
out_fec_ult_contacto      = 'fec_ult_co',     															
out_estado_gestion        = 'est_gestio' ,      															
out_lista_trab            = 'lista_trab'  ,         															
out_fec_hora_trab         = 'fec_hora_trab',        															
out_region                = 'region'       ,        															
out_division              = 'division'     ,        															
out_escenario_gestion_cli = 'esc_gestion_cli',															
out_estado_gestion_cli    = 'est_gestion_cli' ,  															
out_deuda_contable        = 'deuda_contable'  ,    															
out_prevision             = 'prevision'       ,     															
out_segmento              = 'segmento'        ,     															
out_subsegmento           = 'subsegmento'     ,     															
out_resp_ult_acc_manual   = 'resp_ult_acc_manual',  															
out_fec_ult_prom          = 'fec_ult_pr'       ,  															
out_fec_pago_ult_prom     = 'fec_p_u_pr'  ,  															
out_estado_ult_prom       = 'estado_ult_prom'    ,  															
out_fec_refin_pend        = 'fec_refi_p'     ,  															
out_score                 = 'score'              ,  															
out_perdida_esperada      = 'perdida_esperada'   ,  															
out_ciclo                 = 'ciclo'              ,															
out_age					= 'Agen'				  						
															
--MLG: Inicio Optimización Agosto 2013															
#¿NOMBRE?															
INSERT INTO macro_out_TECNOVOZ 															
SELECT 															
	out_fec_archivo = convert(varchar, @fecha_proceso, 103),														
	out_orden_LT = '',														
	out_tipo = convert(varchar,@tac_LLM),														
	out_per_id = pe.per_id,														
	out_per_cli = pe.per_cli,														
	out_per_nombre = LTRIM(RTRIM(pe.per_apellido)) + ' ' + LTRIM(RTRIM(pe.per_nombre)),														
	out_documento = '',														
	out_tel_1 = '', 														
	out_tel_2 = '',														
	out_tel_3 = '',														
	out_tel_4 = '',														
	out_tel_5 = '',														
	out_deuda_total = '',														
	out_deuda_venc = '',														
	out_dias_mora ='',														
	out_sucursal = suc_nombre_corto,														
	'',														
	'',														
	out_lista_trab = ' ',														
	out_fec_hora_trab = '',														
	out_region = ISNULL(are_nombre,''),														
	out_division = ISNULL(are_division,''),														
	out_escenario_gestion_cli  = '',														
	out_estado_gestion_cli  = '',														
	out_deuda_contable = '',														
	out_prevision = per_nacionalidad,														
	out_segmento = pea_texto6,														
	out_subsegmento = pea_texto8,														
	out_resp_ult_acc_manual ='',														
	out_fec_ult_prom = null, 														
	out_fec_pago_ult_prom = null, 														
	out_estado_ult_prom = '',														
	out_fec_refin_pend = ' ',														
    out_score = ' ', 															
	out_perdida_esperada = ' ',														
    out_ciclo = ' '			,												
	out_age = ' '														
FROM personas pe															
INNER JOIN sucursales ON pe.per_suc = suc_id															
INNER JOIN per_atributos ON pe.per_id = pea_id															
LEFT JOIN add_reg_x_suc ON rxs_suc = suc_cod															
LEFT JOIN add_regiones ON rxs_reg = are_id															
WHERE EXISTS(SELECT 1 FROM cuentas 															
				INNER JOIN wf_sit_objetos ON cta_id = sob_id AND cta_baja_fecha IS NULL AND sob_baja_fecha IS NULL											
				WHERE cta_per = pe.per_id											
                AND (ISNULL(@car_id,'') = '' OR @car_id LIKE '%,' + convert(varchar,cta_cat) + ',%')															
				AND cta_age in (select age_id from agencias where age_cod in (select * from dbo.emx_f_split_c(@v_mul_age,',')))											
				AND sob_esc IN (SELECT esc_id FROM @tab_ESC)											
				AND sob_est IN (SELECT est_id FROM @tab_LT)											
				AND (sob_fec_susp <= @fecha_proceso OR sob_fec_susp IS NULL)											
			)												
AND EXISTS(															
select per.per_cli from personas per left join per_tel on pte_per = per.per_id and pte_baja_fecha is null and pte_obs <> 'DESESTIMAR'															
where per.per_cli = pe.per_cli 															
union															
select cte_cliente from personas per left join add_cli_tel on cte_cliente = per.per_cli and cte_baja_fecha is null															
where per.per_cli = pe.per_cli)															
and pe.per_baja_fecha is null															
and suc_baja_fecha is null															
and pea_baja_fecha is null															
and rxs_baja_fecha is null															
and are_baja_fecha is null															
															
#¿NOMBRE?															
/*Movido más abajo */															
------------------------------------------------------------------------------------------------------------------------------------------------															
															
/*MLG: Agrego un update para no efectuar el sub-select masivamente antes de los delete´s anteriores*/															
															
#¿NOMBRE?															
CREATE TABLE dbo.#tmp_ultima_promesa (id_promesa int null,id_persona int null)															
															
insert into #tmp_ultima_promesa															
Select 															
isnull((select top 1 prm_id															
								from promesas 							
								where prm_per = out_per_id and prm_baja_fecha is null 							
								order by prm_fecha desc),' '),out_per_id							
from macro_out_TECNOVOZ															
															
---															
update macro_out_TECNOVOZ															
set															
out_dias_mora = convert(varchar,per_dias_mora),															
out_deuda_total = convert(varchar,per_deuda),															
out_deuda_venc = ISNULL((SELECT convert(varchar,SUM(cta_deuda_venc * ISNULL(tca_valor,1)))															
					  FROM cuentas 										
					  	LEFT JOIN @tab_cotizac ON cta_mon = tca_mon									
						inner join wf_sit_objetos on sob_id = cta_id and (sob_fec_susp <= @fecha_proceso OR sob_fec_susp IS NULL)  --RM por SocMilitar toda la linea									
					  WHERE cta_per = out_per_id AND cta_baja_fecha IS NULL --AND cta_age = @age_id_GESTIVA										
					  ),0),										
out_lista_trab = est_nombre_corto,															
out_escenario_gestion_cli  = esc_nombre,															
out_estado_gestion_cli  = est_nombre,															
out_deuda_contable = (select convert(varchar,SUM((CASE WHEN cta_paq_precierre_deuda > 0 THEN cta_paq_precierre_deuda ELSE 0 END) * ISNULL(tca_valor, 1)))															
						from cuentas 									
						inner join @tab_cotizac on cta_mon = tca_mon 									
						where cta_per = out_per_id and cta_baja_fecha is null --AND cta_age = @age_id_GESTIVA									
						),									
out_resp_ult_acc_manual = isnull((select top 1 trp_nombre 															
										from acciones a 					
										inner join tipos_acciones on tac_id = a.acc_tac and tac_online = 'S'					
										inner join tipos_respuestas on  trp_id = a.acc_trp 					
										where a.acc_per = out_per_id					
										and a.acc_fec_hora = (select max(b.acc_fec_hora) from acciones b where b.acc_per = out_per_id)),' '),					
out_fec_ult_prom = convert(varchar, prm_fecha, 103), 															
out_fec_pago_ult_prom = convert(varchar, prm_fec_prom, 103), 															
out_estado_ult_prom = isnull(prr_nombre,' '),															
out_age = (select age_cod from agencias where age_id in (select top 1 cta_age from cuentas where cta_per = out_per_id))															
From macro_out_TECNOVOZ															
inner join wf_vw_dic_datos_tabla on cta_per = out_per_id and (sob_fec_susp <= @fecha_proceso OR sob_fec_susp IS NULL)  --RM por SocMilitar  and (sob_fec_susp <= @fecha_proceso OR sob_fec_susp IS NULL)															
inner join wf_estados on sob_est = est_id															
inner join wf_escenarios on sob_esc = esc_id															
left join #tmp_ultima_promesa on id_persona = out_per_id															
left join promesas on id_promesa =  prm_id															
left join promesas_result on prm_prr = prr_id and prr_baja_fecha is null															
-----															
---------------------------------------------------------------------  															
#¿NOMBRE?															
#¿NOMBRE?															
--DELETE FROM macro_out_TECNOVOZ WHERE convert(numeric(20,2),out_deuda_venc) <= 0															
---------------------------------------------------------------------  															
															
															
Update macro_out_TECNOVOZ															
set 															
out_documento = ISNULL(LTRIM(RTRIM(tdc_nombre_corto)) + ' ' + LTRIM(RTRIM(pdc_nro)),'')															
from macro_out_TECNOVOZ															
	inner join personas on per_cli = out_per_cli  and per_ent = 1 --Busco por per_cli														
	inner join per_doc on per_id = pdc_per and pdc_default = 'S'  AND pdc_baja_fecha IS NULL  --Al ser inner join, busca el doc de la cartera macro  														
	inner join tipos_documentos on pdc_tdc = tdc_id AND tdc_baja_fecha IS NULL  														
------------------------------------------------------------------------------------------------------------------------------------------------															
drop table #tmp_ultima_promesa															
------------------------------------------------------------------------------------------------------------------------------------------------															
--MLG: Fin Optimización Agosto 2013															
															
#¿NOMBRE?															
#¿NOMBRE?															
INSERT INTO macro_out_TECNOVOZ_aux_TEL															
	SELECT 														
		pte_per,													
		LTRIM(RTRIM(REPLACE(pte_cod_area,' ',''))),													
		LTRIM(RTRIM(REPLACE(pte_telefono,' ',''))),													
		pte_tti,													
		pte_default,													
		left(tti_filler, 2), -- prioridad de los telefonos													
		left(pte_filler,10), -- secuencial de los telefonos													
		0	#¿NOMBRE?												
	FROM per_tel														
    inner join personas on pte_per = per_id and per_baja_fecha is null and per_ent = 1															
	INNER JOIN tipos_telefonos ON pte_tti = tti_id														
	WHERE per_cli IN (SELECT out_per_cli FROM macro_out_TECNOVOZ)														
	AND '' <> 														
-- Saco caracteres "." "," "-" "/" "*" y blancos del telefono															
#¿NOMBRE?															
	(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pte_cod_area, '.',''), ',',''), '-',''), '/',''),'*',''),' ','')))														
    + LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pte_telefono, '.',''), ',',''), '-',''), '/',''),'*',''),' ',''))))															
	AND pte_baja_fecha IS NULL														
#¿NOMBRE?															
    AND pte_default = 'N' and pte_obs <> 'DESESTIMAR'															
	ORDER BY pte_per, tti_filler, pte_filler DESC														
															
---------------------------------------------------------------------  		 													
#¿NOMBRE?															
UPDATE macro_out_TECNOVOZ_aux_TEL SET															
	orden_tel = 1 + id - (SELECT MIN(id) FROM macro_out_TECNOVOZ_aux_TEL AS aux WHERE aux.id_per = macro_out_TECNOVOZ_aux_TEL.id_per) 														
															
															
UPDATE macro_out_TECNOVOZ SET 															
	out_tel_1 = substring(LTRIM(RTRIM(cte_cod_area)) + LTRIM(RTRIM(cte_telefono)),1,20) 														
FROM add_cli_tel															
WHERE cte_baja_fecha is null and rtrim(ltrim(out_per_cli)) = rtrim(ltrim(cte_cliente)) 															
															
UPDATE macro_out_TECNOVOZ SET 															
	out_tel_1 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 														
FROM per_tel inner join personas on per_id = pte_per and per_baja_fecha is null															
WHERE out_per_cli = per_cli and per_ent = 1															
AND pte_default = 'S' and pte_obs <> 'DESESTIMAR'															
and pte_baja_fecha is null															
AND (out_tel_1 = '' or out_tel_1 is null)															
															
delete from macro_out_tecnovoz where out_tel_1 = '' or out_tel_1 is null															
--															
-- Cargo en la tabla OUT el telefono con prioridad 2 para cada cliente															
UPDATE macro_out_TECNOVOZ SET 															
	out_tel_2 = LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)) 														
FROM macro_out_TECNOVOZ_aux_TEL inner join personas on per_id = id_per 															
WHERE out_per_cli = per_cli															
AND orden_tel = 1															
															
-- Cargo en la tabla OUT el telefono con prioridad 3 para cada cliente															
UPDATE macro_out_TECNOVOZ SET 															
	out_tel_3 = LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)) 														
FROM macro_out_TECNOVOZ_aux_TEL inner join personas on per_id = id_per 															
WHERE out_per_cli = per_cli															
AND orden_tel = 2															
															
-- Cargo en la tabla OUT el telefono con prioridad 4 para cada cliente															
UPDATE macro_out_TECNOVOZ SET 															
	out_tel_4 = LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)) 														
FROM macro_out_TECNOVOZ_aux_TEL inner join personas on per_id = id_per 															
WHERE out_per_cli = per_cli															
AND orden_tel = 3															
															
-- Cargo en la tabla OUT el telefono con prioridad 5 para cada cliente															
UPDATE macro_out_TECNOVOZ SET 															
	out_tel_5 = LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)) 														
FROM macro_out_TECNOVOZ_aux_TEL inner join personas on per_id = id_per 															
WHERE out_per_cli = per_cli															
AND orden_tel = 4															
---------------------------------------------------------------------  															
															
INSERT INTO macro_out_TECNOVOZ_aux_LT															
SELECT id_per = out_per_id,															
    score = (select top 1 scd_scr from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    perdida_esperada = (select top 1 scd_esp from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    ciclo = (select top 1 scd_ciclo from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    out_deuda_total = convert(numeric(20,2),out_deuda_total),															
	fecha_hora_trabajada = MAX(sob_fec_hora_trab)														
FROM macro_out_TECNOVOZ															
INNER JOIN cuentas ON out_per_id = cta_per AND cta_baja_fecha IS NULL															
INNER JOIN wf_sit_objetos ON cta_id = sob_id															
WHERE 															
(ISNULL(@car_id,'') = '' OR @car_id LIKE '%,' + convert(varchar,cta_cat) + ',%')															
AND NOT EXISTS(SELECT 1 FROM macro_out_TECNOVOZ_aux_LT WHERE id_per = out_per_id)															
AND (select top 1 scd_ciclo from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat) = 1															
GROUP BY out_per_id,out_deuda_total,cta_cli,cta_cat															
ORDER BY score asc															
															
INSERT INTO macro_out_TECNOVOZ_aux_LT															
SELECT id_per = out_per_id,															
    score = (select top 1 scd_scr from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    perdida_esperada = (select top 1 scd_esp from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    ciclo = (select top 1 scd_ciclo from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    out_deuda_total = convert(numeric(20,2),out_deuda_total),															
	fecha_hora_trabajada = MAX(sob_fec_hora_trab)														
FROM macro_out_TECNOVOZ															
INNER JOIN cuentas ON out_per_id = cta_per AND cta_baja_fecha IS NULL															
INNER JOIN wf_sit_objetos ON cta_id = sob_id															
WHERE 															
(ISNULL(@car_id,'') = '' OR @car_id LIKE '%,' + convert(varchar,cta_cat) + ',%')															
AND NOT EXISTS(SELECT 1 FROM macro_out_TECNOVOZ_aux_LT WHERE id_per = out_per_id)															
AND (select top 1 scd_ciclo from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat) = 2															
GROUP BY out_per_id,out_deuda_total,cta_cli,cta_cat															
ORDER BY perdida_esperada desc															
--															
INSERT INTO macro_out_TECNOVOZ_aux_LT															
SELECT id_per = out_per_id,															
    score = (select top 1 scd_scr from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    perdida_esperada = (select top 1 scd_esp from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    ciclo = (select top 1 scd_ciclo from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat),															
    out_deuda_total = convert(numeric(20,2),out_deuda_total),															
	fecha_hora_trabajada = MAX(sob_fec_hora_trab)														
FROM macro_out_TECNOVOZ															
INNER JOIN cuentas ON out_per_id = cta_per AND cta_baja_fecha IS NULL															
INNER JOIN wf_sit_objetos ON cta_id = sob_id															
WHERE 															
(ISNULL(@car_id,'') = '' OR @car_id LIKE '%,' + convert(varchar,cta_cat) + ',%')															
AND NOT EXISTS(SELECT 1 FROM macro_out_TECNOVOZ_aux_LT WHERE id_per = out_per_id)															
AND (select top 1 scd_ciclo from add_score_diario where scd_cli = cta_cli  and scd_car = cta_cat) not in (1,2)															
GROUP BY out_per_id,out_deuda_total,cta_cli,cta_cat															
ORDER BY convert(numeric(20,2),out_deuda_total) desc															
															
#¿NOMBRE?															
UPDATE macro_out_TECNOVOZ SET															
	out_orden_LT = convert(varchar,1 + id - (SELECT MIN(id) FROM macro_out_TECNOVOZ_aux_LT)),														
	out_score = score,														
    out_perdida_esperada = perdida_esperada,															
    out_ciclo = ciclo,															
    out_fec_hora_trab = CASE WHEN fecha_hora_trabajada IS NULL THEN '' ELSE convert(varchar, fecha_hora_trabajada, 103) + ' ' + convert(varchar, fecha_hora_trabajada, 108) END															
FROM macro_out_TECNOVOZ_aux_LT															
WHERE id_per = out_per_id															
---------------------------------------------------------------------  															
#¿NOMBRE?															
UPDATE macro_out_TECNOVOZ SET 															
	out_fec_ult_contacto = (SELECT convert(varchar,acc_fec_hora,103)														
							FROM acciones 								
							WHERE acc_id = id_acc),								
	out_estado_gestion = (SELECT trp_nombre_corto														
							FROM acciones 								
							INNER JOIN tipos_respuestas ON acc_trp = trp_id								
							WHERE acc_id = id_acc)								
FROM (SELECT acc_per, MAX(acc_id) AS id_acc															
		FROM acciones													
		WHERE acc_tac IN (@tac_LLM, @tac_LLE, @tac_LLAI, @tac_LLAII)													
		AND acc_trp > 0													
		AND acc_per IN (SELECT out_per_id FROM macro_out_TECNOVOZ)													
		AND acc_baja_fecha IS NULL													
		GROUP BY acc_per) AS tabla													
WHERE out_per_id = acc_per															
															
DECLARE @cmb_sob TABLE(															
	cta_per INT,														
	cob_cambio_fecha datetime)														
															
insert into @cmb_sob															
select cta_per, max(cob_cambio_fecha) cob_cambio_fecha															
from cuentas 															
inner join wf_sit_objetos on cta_id = sob_id 															
inner join wf_cmb_objetos on sob_id = cob_sob 															
where 															
cob_tipo = 'sob_est' 															
and cob_dato_nue = @v_est_id_REFIPEN 															
and cta_baja_fecha is null 															
and sob_baja_fecha is null 															
and cob_baja_fecha is null 															
group by cta_per															
															
UPDATE macro_out_TECNOVOZ SET 															
	out_fec_refin_pend = isnull(convert(varchar, cob_cambio_fecha, 103),' ')														
FROM @cmb_sob															
WHERE out_per_id = cta_per															
															
---------------------------------------------------------------------  															
#¿NOMBRE?															
DECLARE @prt_BACKUP VARCHAR(1)															
															
SELECT @prt_BACKUP = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'BackupTVOZ' AND prt_baja_fecha IS NULL															
IF ISNULL(@prt_BACKUP,'') = 'S'															
	BEGIN														
	INSERT INTO add_tecnovoz														
	SELECT	atz_id = @atz_id + out_orden_LT,													
	--atz_id = @atz_id + IIF(out_orden_LT = 'orden_LT', 999999999,convert(int,out_orden_LT)),  sacado 10-4-2024 por overflow en id que es int														
			atz_fec_arch = @fecha_proceso,												
			atz_orden_LT = IIF(out_orden_LT = 'orden_LT', 999999999,convert(int,out_orden_LT)),												
			atz_per = out_per_id,												
			atz_tac = @tac_LLM,												
			atz_trp = 0,												
			atz_atc = 0,												
			atz_cod_discador = '',												
			atz_fec_hora_resp = NULL,												
			atz_fec_proc_resp = NULL,												
			atz_obs = '',												
			atz_alta_fecha = GETDATE(),												
			atz_modi_fecha = NULL,												
			atz_baja_fecha = NULL,												
			atz_usu_id = @usu_id,												
			atz_filler = ''												
	FROM macro_out_TECNOVOZ														
	where out_orden_LT <> 'orden_LT'														
	ORDER BY out_orden_LT														
															
	END														
															
SELECT @atz_id = MAX(atz_id) FROM add_tecnovoz															
UPDATE id_numeracion SET idn_ultimo_id = @atz_id WHERE idn_tabla = 'add_tecnovoz'															
---------------------------------------------------------------------  															
DECLARE @cant INT															
SELECT @cant = COUNT(1) FROM macro_out_TECNOVOZ															
															
--VD--20120613--															
UPDATE macro_out_TECNOVOZ															
SET															
out_fec_archivo = CASE WHEN out_fec_archivo = '' THEN ' ' ELSE out_fec_archivo END,															
out_tipo = CASE WHEN out_tipo = '' THEN ' ' ELSE out_tipo END,															
out_per_id = CASE WHEN out_per_id='' then ' ' else out_per_id END,															
out_per_cli = CASE WHEN out_per_cli = '' THEN ' ' ELSE out_per_cli END,															
out_per_nombre = CASE WHEN out_per_nombre = '' THEN ' ' ELSE out_per_nombre END,															
out_documento = CASE WHEN out_documento = '' THEN ' ' ELSE out_documento END,															
out_tel_1 = CASE WHEN out_tel_1 = '' THEN ' ' ELSE out_tel_1 END,															
out_tel_2 = CASE WHEN out_tel_2 = '' THEN ' ' ELSE out_tel_2 END,															
out_tel_3 = CASE WHEN out_tel_3 = '' THEN ' ' ELSE out_tel_3 END,															
out_tel_4 = CASE WHEN out_tel_4 = '' THEN ' ' ELSE out_tel_4 END,															
out_tel_5 = CASE WHEN out_tel_5 = '' THEN ' ' ELSE out_tel_5 END,															
out_deuda_total = CASE WHEN out_deuda_total = '' THEN ' ' ELSE out_deuda_total END,															
out_deuda_venc = CASE WHEN out_deuda_venc = '' THEN ' ' ELSE out_deuda_venc END,															
out_sucursal = CASE WHEN out_sucursal = '' THEN ' ' ELSE out_sucursal END,															
out_fec_ult_contacto = CASE WHEN out_fec_ult_contacto = '' THEN ' ' ELSE out_fec_ult_contacto END,															
out_estado_gestion = CASE WHEN out_estado_gestion = '' THEN ' ' ELSE out_estado_gestion END,															
out_lista_trab = CASE WHEN out_lista_trab = '' THEN ' ' ELSE out_lista_trab END,															
out_score = CASE WHEN out_score = '' THEN ' ' ELSE out_score END,															
out_perdida_esperada = CASE WHEN out_perdida_esperada = '' THEN ' ' ELSE out_perdida_esperada END,															
out_ciclo = CASE WHEN out_ciclo = '' THEN ' ' ELSE out_ciclo END,															
out_fec_hora_trab = CASE WHEN out_fec_hora_trab = '' THEN ' ' ELSE out_fec_hora_trab END															
--VD--20120613--															
UPDATE macro_out_TECNOVOZ															
SET															
out_per_id = CASE WHEN out_per_id = '0' THEN 'per_id' ELSE out_per_id end															
															
#¿NOMBRE?															
															
/* generar ciclo de creacion del archivo de salida, en funcion de las agencias cargados en el parametro.															
En archivos iguales, una por cada agencia, donde se insertaran los mismos campos de macro_out_tecnovoz.															
*/															
															
declare			@orden int												
declare			@archi varchar(30)												
declare			@chs varchar(5)												
DECLARE			@tab_age TABLE(												
					tta_reg int identity,										
					tta_age varchar(5))										
DECLARE @SQLString NVARCHAR(2000);  															
DECLARE @ParmDefinition NVARCHAR(500);  															
declare @tabla varchar(30);															
DECLARE @v_error NVARCHAR(2047)															
DECLARE @v_path_salida VARCHAR(100)															
DECLARE	@v_query varchar(8000)														
DECLARE	@v_bcp_string varchar(8000)														
DECLARE @v_archivo_salida VARCHAR(100)															
															
SET @v_path_salida = (SELECT prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'EMX_OUT' AND prt_baja_fecha IS NULL)  															
															
insert into @tab_age select * from dbo.emx_f_split_c(@v_mul_age,',')															
															
select out_fec_archivo, out_orden_LT, out_tipo, out_per_id, out_per_cli, out_per_nombre, out_documento, out_tel_1, out_tel_2, 															
out_tel_3, out_tel_4, out_tel_5, out_deuda_total, out_deuda_venc, out_dias_mora, out_sucursal, out_fec_ult_contacto, 															
out_estado_gestion, out_lista_trab, out_fec_hora_trab, out_region, out_division, out_escenario_gestion_cli, 															
out_estado_gestion_cli, out_deuda_contable, out_prevision, out_segmento, out_subsegmento, out_resp_ult_acc_manual, 															
out_fec_ult_prom, out_fec_pago_ult_prom, out_estado_ult_prom, out_fec_refin_pend, out_score, out_perdida_esperada, 															
out_ciclo, out_age															
into #tot_tecno from MACRO_OUT_tecnovoz where out_age <> 'Agen'															
															
set @cant = (select max(tta_reg) from @tab_age) 															
set @orden = 1															
															
while @orden <= @cant															
begin															
	set @chs = (select tta_age from @tab_age where tta_reg = @orden)														
															
	set @archi = 'TECNOVOZ_' + @chs														
	select @archi = '##' + @archi														
															
SET @v_archivo_salida = 'TECNOVOZ_' + @chs 															
															
	SET @SQLString =N'select out_fec_archivo, out_orden_LT, out_tipo, out_per_id, out_per_cli, out_per_nombre, out_documento, out_tel_1, out_tel_2, 														
out_tel_3, out_tel_4, out_tel_5, out_deuda_total, out_deuda_venc, out_dias_mora, out_sucursal, out_fec_ult_contacto, 															
out_estado_gestion, out_lista_trab, out_fec_hora_trab, out_region, out_division, out_escenario_gestion_cli, 															
out_estado_gestion_cli, out_deuda_contable, out_prevision, out_segmento, out_subsegmento, out_resp_ult_acc_manual, 															
out_fec_ult_prom, out_fec_pago_ult_prom, out_estado_ult_prom, out_fec_refin_pend, out_score, out_perdida_esperada, 															
out_ciclo, out_age into ' + @archi + ' from #tot_tecno where 1=2';  															
															
				SET @ParmDefinition = N'@tabla varchar(30)';  											
				EXECUTE sp_executesql  											
			    @SQLString  												
			    ,@ParmDefinition  												
			    ,@tabla = @archi;   												
															
															
	SET @SQLString =N'INSERT INTO ' + @archi + ' values (''fec_arch'' , ''orden_LT'', ''tp'' ,''0'', ''per_cli'', ''per_nombre''  , ''documento'', ''tel_1'', ''tel_2'', ''tel_3'', ''tel_4'', ''tel_5'', 														
''deuda_total'', ''deuda_venc'' , ''dias_mora'', ''sucursal'', ''fec_ult_co'', ''est_gestio'' ,''lista_trab'' ,''fec_hora_trab'', ''region'',															
''division'', ''esc_gestion_cli'',''est_gestion_cli'' , ''deuda_contable'' , ''prevision'', ''segmento'', ''subsegmento'', ''resp_ult_acc_manual'',  															
''fec_ult_pr'', ''fec_p_u_pr'',  ''estado_ult_prom'',  ''fec_refi_p'',  ''score'',  ''perdida_esperada'', ''ciclo'', ''Agen'')' ;															
															
   SET @ParmDefinition = N'@tabla varchar(30)';  															
				EXECUTE sp_executesql  											
			    @SQLString  												
			    ,@ParmDefinition  												
			    ,@tabla = @archi;   												
															
	SET @SQLString =N'INSERT INTO ' + @archi + ' select out_fec_archivo, out_orden_LT, out_tipo, out_per_id, out_per_cli, out_per_nombre, out_documento, out_tel_1, out_tel_2, 														
out_tel_3, out_tel_4, out_tel_5, out_deuda_total, out_deuda_venc, out_dias_mora, out_sucursal, out_fec_ult_contacto, 															
out_estado_gestion, out_lista_trab, out_fec_hora_trab, out_region, out_division, out_escenario_gestion_cli, 															
out_estado_gestion_cli, out_deuda_contable, out_prevision, out_segmento, out_subsegmento, out_resp_ult_acc_manual, 															
out_fec_ult_prom, out_fec_pago_ult_prom, out_estado_ult_prom, out_fec_refin_pend, out_score, out_perdida_esperada, 															
out_ciclo, out_age  from #tot_tecno where out_age = ' +'''' + @chs+ '''' ;															
															
				SET @ParmDefinition = N'@tabla varchar(30)';  											
				EXECUTE sp_executesql  											
			    @SQLString  												
			    ,@ParmDefinition  												
			    ,@tabla = @archi;   												
															
															
SET @v_query = '"select * from ' + @archi + ' order by 1 desc"' 															
															
SET @v_bcp_string  = 'bcp ' + @v_query + ' Queryout ' 															
SET @v_bcp_string = @v_bcp_string + @v_path_salida + @v_archivo_salida															
SET @v_bcp_string = @v_bcp_string + ' -S ' + @@SERVERNAME + ' -w -t";" -r"\n" -T' 															
--SET @v_bcp_string = ''''+ @v_bcp_string + ' -S ' + @@SERVERNAME + ' -w -t";" -r"\n" -T' + ''''															
															
															
	DECLARE @temp TABLE (SomeCol VARCHAR(500))														
	INSERT @temp														
	Exec @v_cod_ret =  master..xp_cmdshell  @v_bcp_string 														
															
	IF @v_cod_ret <> 0														
	BEGIN  														
		SELECT @v_error = @v_error + SomeCol  													
		FROM @temp													
		WHERE SomeCol IS NOT NULL													
															
		INSERT wf_print_out SELECT @prc_nombre_corto, GETDATE(),@fecha_proceso,'A','  No fue posible generar el archivo ' + @v_archivo_salida ,@v_usu_id_in,Null ,0													
		INSERT wf_print_out SELECT @prc_nombre_corto, GETDATE(),@fecha_proceso,'A','  Error:' + convert(varchar,@v_error) + ' ' + @v_error ,@v_usu_id_in,Null ,0													
															
		END													
															
	set @orden = @orden + 1														
															
end															
															
drop table ##TECNOVOZ_AGMC															
drop table ##TECNOVOZ_APRO															
															
/*															
INSERT			wf_print_out												
SELECT			@prc_nombre_corto,												
				GETDATE(),											
				@fecha_proceso,											
				'A',											
				'		Cantidad de clientes enviados: ' + CONVERT(VARCHAR,@cant),									
				@usu_id,											
				NULL,											
				NULL 											
--															
INSERT			wf_print_out												
SELECT			@prc_nombre_corto,												
				GETDATE(),											
				@fecha_proceso,											
				'F',											
				'PROCESO GENERACION ARCHIVO TECNOVOZ x agencia - FINALIZADO. Cartera: ' + @v_cat_nombre_corto + ' ' + CONVERT(CHAR(20),GETDATE(),113),											
				@v_usu_id_in,											
				@v_cod_ret,											
				NULL											
#¿NOMBRE?															
															
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'A','		Cantidad de clientes enviados a Tecnovoz: ' + CONVERT(varchar,@cant), @usu_id, Null, null													
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'F','PROCESO GENERACION ARCHIVO CLIENTES A TECNOVOZ - FINALIZADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@usu_id, @v_cod_ret,null															
*/															
