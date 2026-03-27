USE [emt_desarrollo]						
GO						
/****** Object:  StoredProcedure [dbo].[wf_p_out_COTELEPF]    Script Date: 09/02/2026 10:52:22 ******/						
SET ANSI_NULLS ON						
GO						
SET QUOTED_IDENTIFIER OFF						
GO						
ALTER PROCEDURE  [dbo].[wf_p_out_COTELEPF] (  						
   @fecha_proceso  DATETIME,   						
   @v_usu_id_in INT,  						
   @v_cat_nombre_corto VARCHAR(10),  						
   @cod_ret        INT OUT   						
) 						
AS 						
						
--SP 20201216 Se modifica para enviar el cuit en lugar del nombre y apellido						
--VDO 20151217 PAQ_204_Ajuste Telefono Macro						
--RM se mdifica para que sea multi agencia 11/2024						
						
 --SET NOCOUNT ON  						
 BEGIN						
-- DECLARE @v_moneda_pais  VARCHAR(10)  						
-- DECLARE @mon_dolar   INT  						
 DECLARE @v_fec_cierre  DATETIME  						
 DECLARE @cant_registros  INT  						
 declare @cant     int 						
  						
 DECLARE @prc_nombre_corto varchar(10)  						
 SET @prc_nombre_corto = 'OUT_COTEL'  						
   						
 SET @cod_ret = 0  						
 						
 DECLARE @v_acc_tac varchar(255) 						
 SELECT @v_acc_tac= prt_valor from wf_parametros where prt_nombre_corto='COTELACC'   --1,2,42,43,45						
						
 declare @v_mul_age varchar(255)						
 select @v_mul_age = prt_valor from wf_parametros where prt_nombre_corto='c.agencia'   						
						
						
  /* Obtencion del par?metro @v_fec_proceso */  						
 --SELECT @fecha_proceso = prt_valor FROM wf_parametros where prt_baja_fecha is null and prt_nombre_corto='FECPRO'  						
   						
 IF @fecha_proceso IS NULL OR ISDATE(@fecha_proceso)=0  						
 BEGIN  						
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'I','PROCESO DE GENERACION DE ARCHIVO LLAMADAS - INICIADO. ' ,@v_usu_id_in, Null,0  						
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'A','PROCESO ABORTADO - No existe parametro fecha de proceso ' ,@v_usu_id_in, Null,0  						
  SELECT @cod_ret = -1000  						
  RETURN  						
 END  						
 /* Fin Obtencion del par?metro @v_fec_proceso */  						
  						
 /* Obtencion del par?metro @@v_fec_cierre */  						
 SELECT @v_fec_cierre = prt_valor FROM wf_parametros where prt_baja_fecha is null and prt_nombre_corto='FECCIE'  						
     						
 IF @v_fec_cierre IS NULL OR ISDATE(@v_fec_cierre)=0  						
 BEGIN  						
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'I','PROCESO DE GENERACION DE ARCHIVO LLAMADAS - INICIADO. ' ,@v_usu_id_in, Null,0  						
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'A','PROCESO ABORTADO - No existe parametro fecha de cierre ' ,@v_usu_id_in, Null,0  						
  SELECT @cod_ret = -1000  						
  RETURN  						
 END  						
 /* Fin Obtencion del par?metro @@v_fec_cierre */  						
   						
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'I','PROCESO DE GENERACION DE ARCHIVO LLAMADAS - INICIADO. ' ,@v_usu_id_in, Null,0  						
  						
 TRUNCATE TABLE macro_out_cotel						
 TRUNCATE TABLE macro_out_COTEL_aux_TEL						
						
 --Agrego titulos de columnas						
 Insert into macro_out_cotel						
 select 						
TLLAM             =  'TL'    ,						
NRCLI             =  'NRCLI',						
APRZS             =  'APRZS',						
CUIT              =  'CUIT' ,						
DOTEL1            =  'DOTEL1',						
DOTEL2            =  'DOTEL2',						
DOTEL3            =  'DOTEL3',						
DOTEL4            =  'DOTEL4',						
DOTEL5            =  'DOTEL5',						
MOVDA             =  'MOVDA' ,						
AUAEM             =  'AUAEM' ,						
SCORE             =  'SCORE' ,						
PERDIDA_ESPERADA  =  'PERD_ESP',						
CICLO             =  'CICLO',						
Agencia           =  'AGENCIA'			#¿NOMBRE?			
						
  						
 /*						
 SELECT @v_moneda_pais = ltrim(rtrim(mon_nombre_corto))   						
 FROM wf_parametros Inner Join monedas on mon_id = prt_valor   						
 WHERE prt_nombre_corto = 'MonedaPais'   						
  						
 SELECT @mon_dolar = mon_id FROM monedas WHERE mon_nombre_corto = 'USD' AND mon_baja_fecha IS NULL  						
 */						
  						
    INSERT INTO macro_out_cotel						
    SELECT	distinct 					
			right('00' + left(acc_tac,2),2), 			
			per_cli,                                     --NR$CLI TEL:NRO.CLIENTE 15  			
			left(per_apellido + ' ' + per_nombre ,40) as per_apellido,    --AP$RZS TEL:APELLIDO/NOMBRES 40  			
			(select top 1  format(convert(bigint,pdc_nro),'##-########-#') from per_doc where pdc_per = per_id and pdc_tdc in (35,36,37)) as cuit,			
			'',			
            '',						
            '',						
            '',						
            '',						
            right('0000000000000' + convert(varchar, convert(BIGINT,sum(cta_deuda_venc*100))),13), --MO$VDA            T EL:OPERACION_DEUDA_VDA 13  						
			convert(varchar,acc_id),                --AU$AEM            T EL:AUD_EMISOR_ID_COD 10    			
            (select scd_scr from add_score_diario where cta_cli = scd_cli and cta_cat = scd_car),						
            (select scd_esp from add_score_diario where cta_cli = scd_cli and cta_cat = scd_car),						
            (select scd_ciclo from add_score_diario where cta_cli = scd_cli and cta_cat = scd_car),						
			age_cod 			
    FROM	acciones   					
    inner join personas          on acc_per = per_id  						
    inner join cuentas           on cta_per = per_id   						
	inner join agencias          on cta_age = age_id					
    WHERE						
    acc_tac in (select * from dbo.split(@v_acc_tac,','))						
    AND age_cod in (select * from dbo.split(@v_mul_age,','))						
    AND acc_fec_hora = @fecha_proceso  						
    AND cta_baja_fecha is null     						
	AND cta_pro not in (4,13)					
	and cta_deuda_venc > 0					
	and cta_deuda_a_venc >= 0--AL saldos a favor					
	--and datediff (d,cta_fec_vto,@fecha_proceso) > 5					
--	group by acc_tac,per_cli, per_apellido, per_nombre, acc_per, acc_id,cta_cli,cta_cat					
	group by acc_tac,per_cli, per_id, per_nombre , per_apellido, acc_per, acc_id,cta_cli,cta_cat, age_cod					
	order by 11 asc					
  						
    SET @cant_registros = @@ROWCOUNT  						
						
#¿NOMBRE?						
#¿NOMBRE?						
						
INSERT INTO macro_out_COTEL_aux_TEL						
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
    inner join personas on per_id = pte_per and per_ent = 1						
   	INNER JOIN tipos_telefonos ON pte_tti = tti_id					
	WHERE per_cli IN (SELECT per.per_cli FROM acciones,macro_out_cotel,personas per where acc_per = per.per_id and convert(varchar,acc_id) = rtrim(ltrim(AUAEM)))					
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
UPDATE macro_out_COTEL_aux_TEL SET						
	orden_tel = 1 + id - (SELECT MIN(id) FROM macro_out_COTEL_aux_TEL AS aux WHERE aux.id_per = macro_out_COTEL_aux_TEL.id_per) 					
						
#¿NOMBRE?						
UPDATE macro_out_COTEL SET 						
	DOTEL1 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 					
FROM per_tel						
    inner join personas on per_id = pte_per and per_ent = 1						
   	INNER JOIN tipos_telefonos ON pte_tti = tti_id					
WHERE  '' <> 						
	(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pte_cod_area, '.',''), ',',''), '-',''), '/',''),'*',''),' ','')))					
    + LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pte_telefono, '.',''), ',',''), '-',''), '/',''),'*',''),' ',''))))						
	AND pte_baja_fecha IS NULL					
    and per_cli = RTRIM(LTRIM(NRCLI))						
    AND pte_tti = 2 and TLLAM = '45' and pte_obs <> 'DESESTIMAR'						
    and exists (select 1 from acciones,personas per where acc_per = per.per_id and convert(varchar,acc_id) = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
						
						
-- Cargo en la tabla OUT el telefono con prioridad 1 para cada cliente de acciones distintas de SMS						
						
UPDATE macro_out_COTEL SET 						
	DOTEL1 = substring(LTRIM(RTRIM(cte_cod_area)) + LTRIM(RTRIM(cte_telefono)),1,20) 					
FROM add_cli_tel						
WHERE rtrim(ltrim(nrcli)) = rtrim(ltrim(cte_cliente)) 						
and cte_baja_fecha is null						
AND TLLAM <> '45'						
						
UPDATE macro_out_COTEL SET 						
	DOTEL1 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 					
FROM per_tel						
    inner join personas on per_id = pte_per and per_ent = 1						
   	INNER JOIN tipos_telefonos ON pte_tti = tti_id					
where						
pte_default = 'S' and TLLAM <> '45' and pte_obs <> 'DESESTIMAR'						
and pte_baja_fecha is null						
AND (DOTEL1 = '' or DOTEL1 is null)						
and per_cli = RTRIM(LTRIM(NRCLI))						
and per_baja_fecha is null						
and exists (select 1 from acciones,personas per where acc_id = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
						
-- Cargo en la tabla OUT el telefono con prioridad 2 para cada cliente de acciones distintas de SMS						
UPDATE macro_out_COTEL SET 						
	DOTEL2 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 					
FROM macro_out_COTEL_aux_TEL,personas						
WHERE id_per = per_id and per_cli = RTRIM(LTRIM(NRCLI))						
--and convert(varchar,acc_id) = rtrim(ltrim(AUAEM))						
and per_baja_fecha is null						
--and exists (select 1 from acciones,personas per where convert(varchar,acc_id) = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
and exists (select 1 from acciones,personas per where acc_id = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
AND orden_tel = 1 and TLLAM <> '45'						
						
-- Cargo en la tabla OUT el telefono con prioridad 3 para cada cliente de acciones distintas de SMS						
UPDATE macro_out_COTEL SET 						
	DOTEL3 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 					
FROM macro_out_COTEL_aux_TEL,personas						
WHERE id_per = per_id and per_cli = RTRIM(LTRIM(NRCLI))						
and per_baja_fecha is null						
--and convert(varchar,acc_id) = rtrim(ltrim(AUAEM))						
--and exists (select 1 from acciones,personas per where convert(varchar,acc_id) = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
and exists (select 1 from acciones,personas per where acc_id = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
AND orden_tel = 2 and TLLAM <> '45'						
						
-- Cargo en la tabla OUT el telefono con prioridad 4 para cada cliente de acciones distintas de SMS						
UPDATE macro_out_COTEL SET 						
	DOTEL4 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 					
FROM macro_out_COTEL_aux_TEL,personas						
WHERE id_per = per_id and per_cli = RTRIM(LTRIM(NRCLI))						
--and convert(varchar,acc_id) = rtrim(ltrim(AUAEM))						
and per_baja_fecha is null						
--and exists (select 1 from acciones,personas per where per_baja_fecha is null and convert(varchar,acc_id) = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
and exists (select 1 from acciones,personas per where per_baja_fecha is null and acc_id = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
AND orden_tel = 3 and TLLAM <> '45'						
						
-- Cargo en la tabla OUT el telefono con prioridad 5 para cada cliente de acciones distintas de SMS						
UPDATE macro_out_COTEL SET 						
	DOTEL5 = substring(LTRIM(RTRIM(pte_cod_area)) + LTRIM(RTRIM(pte_telefono)),1,20) 					
FROM macro_out_COTEL_aux_TEL,personas						
WHERE id_per = per_id and per_cli = RTRIM(LTRIM(NRCLI))						
and per_baja_fecha is null						
--and convert(varchar,acc_id) = rtrim(ltrim(AUAEM))						
--and exists (select 1 from acciones,personas per where convert(varchar,acc_id) = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
and exists (select 1 from acciones,personas per where acc_id = rtrim(ltrim(AUAEM)) and PER.per_cli = RTRIM(LTRIM(NRCLI)))						
AND orden_tel = 4 and TLLAM <> '45'						
---------------------------------------------------------------------  						
#¿NOMBRE?						
						
/* generar ciclo de creacion del archivo de salida, en funcion de los age_cod cargados en el parametro.						
En archivos iguales, una por cada age_cod, donde se insertaran los mismos campos de macro_out_cotel.						
*/						
						
declare			@orden int			
declare			@archi varchar(30)			
declare			@chs varchar(5)			
DECLARE			@tab_age TABLE(			
					tta_reg int identity,	
					tta_age varchar(5))	
DECLARE @SQLString NVARCHAR(500);  						
DECLARE @ParmDefinition NVARCHAR(500);  						
declare @tabla varchar(30);						
DECLARE @v_error NVARCHAR(2047)						
DECLARE @v_path_salida VARCHAR(100)						
DECLARE	@v_query varchar(8000)					
DECLARE	@v_bcp_string varchar(8000)					
DECLARE @v_archivo_salida VARCHAR(100)						
						
SET @v_path_salida = (SELECT prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'EMX_OUT' AND prt_baja_fecha IS NULL)  						
						
insert into @tab_age select * from dbo.emx_f_split_c(@v_mul_age,',')						
						
select * into #tot_cotel from macro_out_cotel where 1 = 2 						
						
insert into #tot_cotel 						
select TLLAM, NRCLI, APRZS, CUIT, DOTEL1, DOTEL2, DOTEL3, DOTEL4, DOTEL5, MOVDA,  AUAEM, SCORE, PERDIDA_ESPERADA, CICLO, Agencia						
from MACRO_OUT_cotel where agencia <> 'AGENCIA'						
						
set @cant = (select max(tta_reg) from @tab_age) 						
set @orden = 1						
						
while @orden <= @cant						
begin						
	set @chs = (select tta_age from @tab_age where tta_reg = @orden)					
	set @archi = 'COTELEPF_' + @chs					
	select @archi = '##' + @archi					
	SET @v_archivo_salida = 'COTELEPF_' + @chs 					
						
	SET @SQLString =N'select TLLAM, NRCLI, APRZS, CUIT, DOTEL1, DOTEL2, DOTEL3, DOTEL4, DOTEL5, MOVDA,  AUAEM, SCORE, PERDIDA_ESPERADA, CICLO, agencia into ' + @archi + ' from #tot_cotel 					
	where 1=2';  					
						
				SET @ParmDefinition = N'@tabla varchar(30)';  		
				EXECUTE sp_executesql  		
			    @SQLString  			
			    ,@ParmDefinition  			
			    ,@tabla = @archi;   			
						
	SET @SQLString =N'INSERT INTO ' + @archi + ' values (''TL'', ''NRCLI'', ''APRZS'', ''CUIT'', ''DOTEL1'', ''DOTEL2'', ''DOTEL3'', ''DOTEL4'', ''DOTEL5'', ''MOVDA'',  ''AUAEM'', ''SCORE'', ''PERD_ESP'', ''CICLO'', ''agencia'')' ;					
   SET @ParmDefinition = N'@tabla varchar(30)';  						
				EXECUTE sp_executesql  		
			    @SQLString  			
			    ,@ParmDefinition  			
			    ,@tabla = @archi;   			
						
						
	SET @SQLString =N'INSERT INTO ' + @archi + ' select TLLAM, NRCLI, APRZS, CUIT, DOTEL1, DOTEL2, DOTEL3, DOTEL4, DOTEL5, MOVDA,  AUAEM, SCORE, PERDIDA_ESPERADA, CICLO, agencia  from #tot_cotel MA					
			where Agencia ='+'"' + @chs+ '"'  ;			
						
				SET @ParmDefinition = N'@tabla varchar(30)';  		
				EXECUTE sp_executesql  		
			    @SQLString  			
			    ,@ParmDefinition  			
			    ,@tabla = @archi;   			
						
SET @v_query = '"select TLLAM, NRCLI, APRZS, CUIT, DOTEL1, DOTEL2, DOTEL3, DOTEL4, DOTEL5, MOVDA,  AUAEM, SCORE, PERDIDA_ESPERADA, CICLO, agencia  from ' + @archi + ' order by 1 desc"' 						
--select 'query' , @v_query		#¿NOMBRE?				
SET @v_bcp_string  = 'bcp ' + @v_query + ' Queryout ' 						
SET @v_bcp_string = @v_bcp_string + @v_path_salida + @v_archivo_salida						
SET @v_bcp_string = @v_bcp_string + ' -S ' + @@SERVERNAME + ' -w -t";" -r"\n" -T' 						
						
--select 'bcp', @v_bcp_string		#¿NOMBRE?				
						
	DECLARE @temp TABLE (SomeCol VARCHAR(500))					
	INSERT @temp					
	Exec @cod_ret =  master..xp_cmdshell @v_bcp_string					
						
	IF @cod_ret <> 0					
	BEGIN  					
		SELECT @v_error = @v_error + SomeCol  				
		FROM @temp				
		WHERE SomeCol IS NOT NULL				
--		select 'error', @v_error , @cod_ret		#¿NOMBRE?		
						
		INSERT wf_print_out SELECT @prc_nombre_corto, GETDATE(),@fecha_proceso,'A','  No fue posible generar el archivo ' + @v_archivo_salida ,@v_usu_id_in,Null ,0				
		INSERT wf_print_out SELECT @prc_nombre_corto, GETDATE(),@fecha_proceso,'A','  Error:' + convert(varchar,@cod_ret) + ' ' + @v_error ,@v_usu_id_in,Null ,0				
						
		END				
						
--drop table @archi						
						
	set @orden = @orden + 1					
						
end						
						
drop table ##COTELEPF_AGMC						
drop table ##COTELEPF_APRO						
						
						
/*VER DE PONER ALGUNA SALIDA DE ERROR PARA QUE EL PROBATCH NOS AVISE QUE ALGUN ARCHIVO NO SALIO						
INSERT			wf_print_out			
SELECT			@prc_nombre_corto,			
				GETDATE(),		
				@fecha_proceso,		
				'A',		
				'		Cantidad de clientes enviados: ' + CONVERT(VARCHAR,@cant),
				@usu_id,		
				NULL,		
				NULL */		
--						
INSERT			wf_print_out			
SELECT			@prc_nombre_corto,			
				GETDATE(),		
				@fecha_proceso,		
				'F',		
				'PROCESO GENERACION ARCHIVO Cotel x agencia - FINALIZADO. Cartera: ' + @v_cat_nombre_corto + ' ' + CONVERT(CHAR(20),GETDATE(),113),		
				@v_usu_id_in,		
				@cod_ret,		
				NULL		
#¿NOMBRE?						
						
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'A','REGISTROS INSERTADOS: ' + convert(varchar,@cant_registros) ,@v_usu_id_in, Null,0  						
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@fecha_proceso,'A','PROCESO DE GENERACION DE ARCHIVO LLAMADAS - FINALIZADO ' ,@v_usu_id_in, Null,0  						
  						
 SET NOCOUNT OFF  						
   						
END  						
