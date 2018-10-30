------ PROYECTO DERIVACIONES ------

CREATE SCHEMA Derivaciones

---PARAMETRICAS ATENCIONES AREA---

CREATE TABLE Derivaciones.AREA_IT
(ID_AREA    SMALLINT IDENTITY PRIMARY KEY,
 NOMBRE_AREA VARCHAR(50),
 ESTADO	BIT NOT NULL,
)

BULK INSERT Derivaciones.AREA_IT FROM 'Y:\DERIVACIONES\AREA_IT.CSV'
WITH(FIELDTERMINATOR = ';',
ROWTERMINATOR = '\n',
FIRSTROW = 2,
CODEPAGE = 'ACP');
GO

CREATE TABLE Derivaciones.CLA_GS
(ID_TP_Clasificacion SMALLINT,
 Clasificacion       VARCHAR(50),
 ID_TP_GrupoServicio SMALLINT,
 GS_Principal        VARCHAR(50),
 ID_AREA             SMALLINT NOT NULL
 CONSTRAINT PK_CLA_GS PRIMARY KEY CLUSTERED (ID_TP_Clasificacion, ID_TP_GrupoServicio),
 CONSTRAINT FK_AREA FOREIGN KEY (ID_AREA) REFERENCES Derivaciones.AREA_IT(ID_AREA)
)

ALTER TABLE Derivaciones.CLA_GS ADD CONSTRAINT FK_AREA FOREIGN KEY (ID_AREA) REFERENCES Derivaciones.AREA_IT(ID_AREA)

BULK INSERT Derivaciones.CLA_GS FROM 'Y:\DERIVACIONES\CLA_GS.CSV'
WITH(FIELDTERMINATOR = ';',
ROWTERMINATOR = '\n',
FIRSTROW = 2,
CODEPAGE = 'ACP');
GO


---CREACION TABLA ATENCIONES---

CREATE TABLE Derivaciones.ATENCIONES
(NAP               VARCHAR(20) PRIMARY KEY,
 SUCURSAL          SMALLINT,
 AÑO               SMALLINT,
 MES               SMALLINT,
 CONTRATO          SMALLINT,
 CODIGOIPS         VARCHAR(10),
 CODIGOPROFESIONAL VARCHAR(20),
 ID_AREA           SMALLINT,
 CODIGO_IT         VARCHAR(20),
 FECHA             DATETIME,
 DOCUMENTO         VARCHAR(20),
 CodigoIpsPrimaria VARCHAR(10)
)


---CREACION TABLA ATENCIONES_DX---

CREATE TABLE Derivaciones.ATENCIONES_DX
(NAP               VARCHAR(20),
 COD_DX          VARCHAR(10),
 DXPRINCIPAL SMALLINT,
 CONSTRAINT PK_NAP_DX PRIMARY KEY (NAP, COD_DX, DXPRINCIPAL)
)

ALTER TABLE Derivaciones.ATENCIONES_DX
ADD CONSTRAINT FK_NAP_DX FOREIGN KEY(NAP) REFERENCES Derivaciones.ATENCIONES (NAP)


---CREACION TABLA ATENCIONES_DX---

CREATE TABLE Derivaciones.DERIVACIONES
(ID_TM_RESULTADOTRAMITESOLICITUD VARCHAR(20),
 CODIGO_IT                       VARCHAR(20),
 NAP_ANTERIOR                    VARCHAR(20),
 AÑO                             SMALLINT,
 MES                             SMALLINT,
 ID_AREA_DESTINO                 SMALLINT,
 COSTO                           DECIMAL(18, 2),
 FECHA                           DATETIME,
 CONSTRAINT PK_ID_CODIGO PRIMARY KEY(CODIGO_IT, ID_TM_RESULTADOTRAMITESOLICITUD)
)

ALTER TABLE Derivaciones.DERIVACIONES
ADD CONSTRAINT FK_NAP FOREIGN KEY(NAP_ANTERIOR) REFERENCES Derivaciones.ATENCIONES (NAP)

---CREACION TABLA FINAL CONSOLIDADO---
--CREATE TABLE Derivaciones.DERIVACIONES_CONSOLIDADO_SUCURSAL
--(AÑO                   SMALLINT,
-- MES                   SMALLINT,
-- SUCURSAL              SMALLINT,
-- CONTRATO              SMALLINT,
-- AREA_REMITE           SMALLINT,
-- ATENCIONES            INT,
-- [Consulta Externa]    INT,
-- Ecografía             INT,
-- [Laboratorio Clinico] INT,
-- Medicamentos          INT,
-- [Rayos X]             INT,
-- CONSTRAINT PK_CONSOLIDADO PRIMARY KEY(AÑO, MES, SUCURSAL, CONTRATO, AREA_REMITE)
--);

---CREACION TABLA AREA_DESTINO---
CREATE TABLE Derivaciones.AREA_DESTINO
(ID           SMALLINT PRIMARY KEY,
 AREA_DESTINO VARCHAR(30)
);

INSERT INTO Derivaciones.AREA_DESTINO VALUES
(1, 'CONSULTA ESPECIALIZADA'),
(2, 'ECOGRAFIA'),
(3, 'LABORATORIO CLINICO'),
(4, 'MEDICAMENTOS'),
(5, 'RAYOS X')

---CREACION TABLA CONTRATO---
CREATE TABLE Derivaciones.CONTRATO
(ID_CONTRATO SMALLINT PRIMARY KEY IDENTITY(1, 1),
 CONTRATO    VARCHAR(30)
);

INSERT INTO Derivaciones.CONTRATO VALUES
('SALUD TOTAL EPS'),
('CAPITAL SALUD EPSS SAS')

---CREACION TABLA SUCURSAL_CONTRATO---
CREATE TABLE Derivaciones.SUCURSAL_CONTRATO
(SUCURSAL SMALLINT,
 CONTRATO SMALLINT
 CONSTRAINT PK_SUC_CONT PRIMARY KEY(SUCURSAL, CONTRATO)
);

INSERT INTO Derivaciones.SUCURSAL_CONTRATO VALUES
(1, 1),
(1, 2),
(2, 1),
(3, 1),
(4, 1),
(5, 1),
(6, 1),
(7, 1),
(8, 1)


---INSERTS TABLAS---

ALTER PROCEDURE PAVS.DERIVACIONES_PAO

AS

DECLARE @AÑO INT, @MESINI INT, @MESFIN INT
SET @MESINI = 1
SET @AÑO = (SELECT YEAR(DATEADD(MONTH, -1, GETDATE())))
SET @MESFIN = (SELECT MONTH(DATEADD(MONTH, -1, GETDATE())))

--PRINT @MESINI
--PRINT @MESFIN
--PRINT @AÑO

BEGIN

--DELETE Derivaciones.DERIVACIONES_CONSOLIDADO_SUCURSAL
--WHERE AÑO = @AÑO
--      AND MES BETWEEN @MESINI AND @MESFIN

--DELETE Derivaciones.ATENCIONES
--WHERE AÑO = @AÑO
--      AND MES BETWEEN @MESINI AND @MESFIN

--DELETE Derivaciones.DERIVACIONES
--WHERE AÑO = @AÑO
--      AND MES BETWEEN @MESINI AND @MESFIN


TRUNCATE TABLE Derivaciones.ATENCIONES
TRUNCATE TABLE Derivaciones.ATENCIONES_DX
TRUNCATE TABLE Derivaciones.DERIVACIONES


---ATENCIONES HC

INSERT INTO Derivaciones.ATENCIONES
       SELECT NAP, SUCURSAL, AÑO, MES, CONTRATO, CODIGOIPS, CODIGOPROFESIONAL, ID_AREA, CODIGO_IT, FECHA, DOCUMENTO, CodigoIpsPrimaria
       FROM
(
    SELECT DISTINCT
           H.NAP, H.SUCURSAL, H.AÑO, H.MES,
                                       CASE H.EmpresaUsuario
                                           WHEN 'CAPITAL SALUD EPSS SAS'
                                           THEN 2
                                           ELSE 1
                                       END AS CONTRATO, H.CODIGOIPS, H.CODIGOPROFESIONAL,
                                                                       CASE
                                                                           WHEN H.DESCRIPCION = '8902013400'
                                                                           THEN 6
                                                                           ELSE A.ID_AREA
                                                                       END AS ID_AREA, RTRIM(H.DESCRIPCION) AS CODIGO_IT, H.FECHA, H.DocIden AS DOCUMENTO, H.CodigoIpsPrimaria, ROW_NUMBER() OVER(PARTITION BY H.nap ORDER BY H.FECHA) AS muestra
    FROM HISTORIACLINICA H
         INNER JOIN BDInformacionVS.Parametrico.TP_Servicio SE ON H.DESCRIPCION = SE.Codigo COLLATE SQL_Latin1_General_CP1_CI_AS
         INNER JOIN Derivaciones.CLA_GS C ON SE.ID_TP_ClasificacionServicio = C.ID_TP_Clasificacion
                                             AND SE.ID_TP_GrupoServicio = C.ID_TP_GrupoServicio
         INNER JOIN Derivaciones.AREA_IT A ON C.ID_AREA = A.ID_AREA
    WHERE H.año = @AÑO
          AND H.mes BETWEEN @MESINI AND @MESFIN
          AND H.EmpresaUsuario IN('Salud Total EPS', 'CAPITAL SALUD EPSS SAS')
         AND A.ESTADO = 1
         AND H.NAP IS NOT NULL
) SOURCE
       WHERE muestra = 1
	   OPTION(MAXDOP 04)

---ATENCIONES_DX---

INSERT INTO Derivaciones.ATENCIONES_DX
       SELECT DISTINCT
              H.NAP, H.CODDIAGNOST, H.DXPRINCIPAL
       FROM HISTORIACLINICA H
            INNER JOIN BDInformacionVS.Parametrico.TP_Servicio SE ON H.DESCRIPCION = SE.Codigo COLLATE SQL_Latin1_General_CP1_CI_AS
            INNER JOIN Derivaciones.CLA_GS C ON SE.ID_TP_ClasificacionServicio = C.ID_TP_Clasificacion
                                                AND SE.ID_TP_GrupoServicio = C.ID_TP_GrupoServicio
            INNER JOIN Derivaciones.AREA_IT A ON C.ID_AREA = A.ID_AREA
       WHERE H.año = @AÑO
             AND H.mes BETWEEN @MESINI AND @MESFIN
             AND H.EmpresaUsuario IN('Salud Total EPS', 'CAPITAL SALUD EPSS SAS')
            AND A.ESTADO = 1
            AND H.NAP IS NOT NULL
            AND H.CODDIAGNOST IS NOT NULL
			OPTION(MAXDOP 04)


---DERIVACIONES

INSERT INTO Derivaciones.DERIVACIONES
       SELECT A.ID_TM_ResultadoTramiteSolicitud, A.CODIGO_IT, A.Nap_Anterior, A.AÑO, A.MES, A.ID_AREA_DESTINO, A.COSTO, A.FECHA
       FROM Derivaciones.ATENCIONES H
            INNER JOIN
(
    SELECT ID_TM_ResultadoTramiteSolicitud, CODIGO_IT, Nap_Anterior, AÑO, MES, ID_AREA_DESTINO, COSTO, FECHA
    FROM
(
    SELECT DISTINCT
           Año, Mes, CONVERT(DATETIME, fecha_in + hora_in) AS Fecha, nap_anterior, id_tm_resultadotramitesolicitud,
                                                                                   CASE
                                                                                       WHEN AREA = 'Consulta Externa'
                                                                                       THEN 1
                                                                                       WHEN AREA = 'Ecografía'
                                                                                       THEN 2
                                                                                       WHEN AREA = 'Laboratorio Clinico'
                                                                                       THEN 3
                                                                                       WHEN AREA = 'Medicamentos'
                                                                                       THEN 4
                                                                                       ELSE 5
                                                                                   END AS ID_AREA_DESTINO, DESCRIPCION AS CODIGO_IT, CONVERT(DECIMAL(18, 2), costopublico) AS COSTO,
																				   ROW_NUMBER() OVER(PARTITION BY ID_TM_ResultadoTramiteSolicitud, DESCRIPCION ORDER BY ID_TM_ResultadoTramiteSolicitud) MUESTRA
    FROM autorizacion
    WHERE año = @AÑO
          AND mes BETWEEN @MESINI AND @MESFIN
          AND (AREA IN('Ecografía', 'Laboratorio Clinico', 'Medicamentos', 'Rayos X')
    OR (area = 'Consulta Externa'
        AND GrupoServicioPrincipal = 'CONSULTA ESPECIALIZADA'))
		AND whoautoriz = 6
) SOURCE
    WHERE MUESTRA = 1
) A ON H.NAP = A.Nap_Anterior
OPTION(MAXDOP 4);
END
GO

EXEC PAVS.DERIVACIONES_PAO


---PARAMETRICAS

SELECT ID, AREA_DESTINO
FROM Derivaciones.AREA_DESTINO
OPTION (MAXDOP 04)

SELECT ID_CONTRATO, CONTRATO
FROM Derivaciones.CONTRATO
OPTION (MAXDOP 04)


------RPT CONSOLIDADO SUCURSAL------

DECLARE @AÑO INT, @MES INT, @SUCURSAL INT
DECLARE @AREA_REMITE INT, @CONTRATO INT, @AREA_DESTINO INT
SET @AÑO = 2018;
SET @MES = 8;
SET @SUCURSAL = 1
SET @AREA_REMITE = 1
SET @CONTRATO = 1
SET @AREA_DESTINO = 3

---DENOMINADOR

IF OBJECT_ID('tempdb..#ATENCIONES') IS NOT NULL
    BEGIN
        DROP TABLE #ATENCIONES
    END

SELECT SUCURSAL, AÑO, MES, /*CONTRATO, ID_AREA,*/COUNT(NAP) ATENCIONES
INTO #ATENCIONES
FROM Derivaciones.ATENCIONES
WHERE AÑO = @AÑO
      AND MES IN (@MES)
      AND SUCURSAL IN (@SUCURSAL)
      AND CONTRATO = @CONTRATO
      AND ID_AREA = @AREA_REMITE
GROUP BY SUCURSAL, AÑO, MES--, CONTRATO, ID_AREA
OPTION(MAXDOP 04)


---NUMERADOR

IF OBJECT_ID('tempdb..#DERIVACIONES') IS NOT NULL
    BEGIN
        DROP TABLE #DERIVACIONES
    END

SELECT H.AÑO, H.MES, H.SUCURSAL, /*H.CONTRATO, H.ID_AREA,*/COUNT(DISTINCT H.NAP) DERIVACIONES
INTO #DERIVACIONES
FROM Derivaciones.ATENCIONES H
     INNER JOIN
(
    SELECT DISTINCT
           NAP_ANTERIOR, ID_TM_RESULTADOTRAMITESOLICITUD, CODIGO_IT
    FROM Derivaciones.DERIVACIONES
    WHERE AÑO = @AÑO
          AND MES IN (@MES)
          AND ID_AREA_DESTINO = @AREA_DESTINO
) A ON H.NAP = A.NAP_ANTERIOR
WHERE H.AÑO = @AÑO
      AND MES IN (@MES)
      AND SUCURSAL IN (@SUCURSAL)
      AND CONTRATO = @CONTRATO
      AND ID_AREA = @AREA_REMITE
GROUP BY H.AÑO, H.MES, H.SUCURSAL--, H.CONTRATO, H.ID_AREA
OPTION(MAXDOP 4);

SELECT A.AÑO, A.MES, A.SUCURSAL, A.ATENCIONES, D.DERIVACIONES
FROM #ATENCIONES A
     LEFT JOIN #DERIVACIONES D ON A.AÑO = D.AÑO
                                  AND A.MES = D.MES
                                  AND A.SUCURSAL = D.SUCURSAL
								  OPTION(MAXDOP 04)



------PARAMETRICAS

---AREA
SELECT ID_AREA, NOMBRE_AREA
FROM Derivaciones.AREA_IT
WHERE ESTADO = 1
OPTION (MAXDOP 04)


USE BDInformacionVS
SELECT DISTINCT
       codProfesional, UPPER(NomProfesional) Nombre_Profesional
FROM BDInformacionVS.Parametrico.TP_Profesional
OPTION(MAXDOP 04)

USE BDInformacionVS
SELECT DISTINCT
       CodigoST, UPPER(Nombre) Nombre_DX
FROM BDInformacionVS.Parametrico.TP_Diagnostico
OPTION(MAXDOP 04)

USE BDInformacionVS
SELECT DISTINCT
       Codigo, RTRIM(NombreServicio) NombreServicio
FROM BDInformacionVS.Parametrico.TP_Servicio
OPTION(MAXDOP 04)

SELECT DISTINCT
       COD_IPS, NOMBRE_IPS
FROM BDAsistencial.dbo.UNIDADES_VS
OPTION(MAXDOP 04)

SELECT DISTINCT
       D.DESCRIPCION_DESTINO, S.Codigo, S.NombreServicio
FROM #derivaciones_cg D
     LEFT JOIN BDInformacionVS.Parametrico.TP_Servicio S ON D.DESCRIPCION_DESTINO = S.Codigo COLLATE SQL_Latin1_General_CP1_CI_AS

SELECT DISTINCT
       D.CODIGOPROFESIONAL, P.codProfesional, P.NomProfesional
FROM #derivaciones_cg D
     LEFT JOIN BDInformacionVS.Parametrico.TP_Profesional P ON D.CODIGOPROFESIONAL = P.codProfesional COLLATE SQL_Latin1_General_CP1_CI_AS


SELECT DISTINCT
       D.CODDIAGNOST, DX.CodigoST, DX.Nombre
FROM #derivaciones_cg D
     LEFT JOIN BDInformacionVS.Parametrico.TP_Diagnostico DX ON D.CODDIAGNOST = DX.CodigoST COLLATE SQL_Latin1_General_CP1_CI_AS
GO



-----RPT DERIVACIONES SERVICIO-----

DECLARE @AÑO INT, @MES INT, @SUCURSAL INT
DECLARE @AREA_REMITE INT, @CONTRATO INT, @AREA_DESTINO INT
SET @AÑO = 2018;
SET @MES = 9;
SET @SUCURSAL = 1
SET @AREA_REMITE = 1
SET @CONTRATO = 1
SET @AREA_DESTINO = 3

---DENOMINADOR

IF OBJECT_ID('tempdb..#ATENCIONES') IS NOT NULL
    BEGIN
        DROP TABLE #ATENCIONES
    END

SELECT AÑO, MES, SUCURSAL, CODIGOPROFESIONAL, CODIGOIPS, COUNT(NAP) ATENCIONES
INTO #ATENCIONES
FROM Derivaciones.ATENCIONES
WHERE AÑO = @AÑO
      AND MES IN(@MES)
      AND SUCURSAL = @SUCURSAL
      AND CONTRATO = @CONTRATO
      AND ID_AREA = @AREA_REMITE
GROUP BY AÑO, MES, SUCURSAL, CODIGOPROFESIONAL, CODIGOIPS
OPTION(MAXDOP 04)


IF OBJECT_ID('tempdb..#ATENCIONES_P') IS NOT NULL
    BEGIN
        DROP TABLE #ATENCIONES_P
    END

SELECT A.SUCURSAL, A.AÑO, A.MES, A.CODIGOPROFESIONAL, B.CODIGOIPS, SUM(A.ATENCIONES) ATENCIONES
INTO #ATENCIONES_P
FROM #ATENCIONES A
     INNER JOIN
(
    SELECT SUCURSAL, AÑO, CODIGOPROFESIONAL, CODIGOIPS
    FROM
(
    SELECT SUCURSAL, AÑO, CODIGOPROFESIONAL, CODIGOIPS, ROW_NUMBER() OVER(PARTITION BY SUCURSAL, AÑO, CODIGOPROFESIONAL ORDER BY MES DESC, ATENCIONES DESC) MUESTRA
    FROM #ATENCIONES
) SOURCE
    WHERE MUESTRA = 1
) B ON A.SUCURSAL = B.SUCURSAL
       AND A.AÑO = B.AÑO
       AND A.CODIGOPROFESIONAL = B.CODIGOPROFESIONAL
GROUP BY A.SUCURSAL, A.AÑO, A.MES, A.CODIGOPROFESIONAL, B.CODIGOIPS
OPTION(MAXDOP 04)


IF OBJECT_ID('tempdb..#ATENCIONES_S') IS NOT NULL
    BEGIN
        DROP TABLE #ATENCIONES_S
    END

SELECT AÑO, MES, SUCURSAL, SUM(ATENCIONES) ATENCIONES
INTO #ATENCIONES_S
FROM #ATENCIONES
GROUP BY AÑO, MES, SUCURSAL
OPTION(MAXDOP 04)

---NUMERADOR

IF OBJECT_ID('tempdb..#DERIVACIONES') IS NOT NULL
    BEGIN
        DROP TABLE #DERIVACIONES
    END

SELECT H.AÑO, H.MES, H.SUCURSAL, H.CODIGOPROFESIONAL, A.CODIGO_IT, COUNT(A.CODIGO_IT) DERIVACIONES, SUM(A.COSTO) AS COSTO
INTO #DERIVACIONES
FROM Derivaciones.ATENCIONES H
     INNER JOIN
(
    SELECT DISTINCT
           NAP_ANTERIOR, ID_TM_RESULTADOTRAMITESOLICITUD, CODIGO_IT, COSTO
    FROM Derivaciones.DERIVACIONES --WITH (INDEX(IDX_SERVICIO))
    WHERE AÑO = @AÑO
          AND MES IN(@MES)
    AND ID_AREA_DESTINO = @AREA_DESTINO
) A ON H.NAP = A.NAP_ANTERIOR
WHERE H.AÑO = @AÑO
      AND MES IN(@MES)
AND SUCURSAL = @SUCURSAL
AND CONTRATO = @CONTRATO
AND ID_AREA = @AREA_REMITE
GROUP BY H.AÑO, H.MES, H.SUCURSAL, H.CODIGOPROFESIONAL, A.CODIGO_IT
OPTION(MAXDOP 4)

SELECT A.AÑO, A.MES, A.SUCURSAL, S.ATENCIONES AS ATENCIONES_S, A.CODIGOPROFESIONAL, A.CODIGOIPS, A.ATENCIONES, D.CODIGO_IT, D.DERIVACIONES, D.COSTO
FROM #ATENCIONES_P A
     LEFT JOIN #DERIVACIONES D ON A.AÑO = D.AÑO
                                  AND A.MES = D.MES
                                  AND A.SUCURSAL = D.SUCURSAL
                                  AND A.CODIGOPROFESIONAL = D.CODIGOPROFESIONAL
     INNER JOIN #ATENCIONES_S S ON A.AÑO = S.AÑO
                                   AND A.MES = S.MES
                                   AND A.SUCURSAL = S.SUCURSAL
								   OPTION(MAXDOP 04)


---FORMA TABLA CON CONTEOS PARA JOB

--DECLARE @AÑO INT, @MESINI INT, @MESFIN INT, @SUCURSAL INT
--DECLARE @AREA_REMITE VARCHAR(50), @EMPRESA VARCHAR(50), @AREA_DESTINO VARCHAR(50)
--SET @AÑO = 2018;
--SET @MESINI = 1;
--SET @MESFIN = 9;
--SET @SUCURSAL = 1
--SET @AREA_REMITE = 1
--SET @EMPRESA = 'Salud Total EPS'
--SET @AREA_DESTINO = 'Laboratorio Clinico'

--DELETE Derivaciones.DERIVACIONES_CONSOLIDADO_SUCURSAL
--WHERE AÑO = @AÑO
--      AND MES BETWEEN @MESINI AND @MESFIN

-----DENOMINADOR

--IF OBJECT_ID('tempdb..#ATENCIONES') IS NOT NULL
--    BEGIN
--        DROP TABLE #ATENCIONES
--    END

----CREATE TABLE #ATENCIONES
--CREATE TABLE #ATENCIONES
--(SUCURSAL SMALLINT,
-- AÑO      SMALLINT,
-- MES      SMALLINT,
-- CONTRATO  SMALLINT,
-- ID_AREA  SMALLINT,
-- NAP      VARCHAR(20) PRIMARY KEY
--)


-----DENOMINADOR

--INSERT INTO #ATENCIONES
--       SELECT SUCURSAL, AÑO, MES, EMPRESA, ID_AREA, NAP
--       FROM
--(
--    SELECT DISTINCT
--           H.SUCURSAL, H.AÑO, H.MES, H.EmpresaUsuario AS EMPRESA,
--                                                                CASE
--                                                                    WHEN H.DESCRIPCION = '8902013400'
--                                                                    THEN 6
--                                                                    ELSE A.ID_AREA
--                                                                END AS ID_AREA, H.NAP, ROW_NUMBER() OVER(PARTITION BY H.nap ORDER BY H.FECHA) AS muestra
--    FROM HISTORIACLINICA H
--         INNER JOIN BDInformacionVS.Parametrico.TP_Servicio SE ON H.DESCRIPCION = SE.Codigo COLLATE SQL_Latin1_General_CP1_CI_AS
--         INNER JOIN Derivaciones.CLA_GS C ON SE.ID_TP_ClasificacionServicio = C.ID_TP_Clasificacion
--                                             AND SE.ID_TP_GrupoServicio = C.ID_TP_GrupoServicio
--         INNER JOIN Derivaciones.AREA_IT A ON C.ID_AREA = A.ID_AREA
--    WHERE H.año = @AÑO
--          AND H.mes BETWEEN @MESINI AND @MESFIN
--          AND H.EmpresaUsuario IN('Salud Total EPS', 'CAPITAL SALUD EPSS SAS')
--         AND A.ESTADO = 1
--         AND H.NAP IS NOT NULL
--) SOURCE
--       WHERE muestra = 1
--	   OPTION(MAXDOP 04)

--IF OBJECT_ID('tempdb..#ATENCIONES_C') IS NOT NULL
--    BEGIN
--        DROP TABLE #ATENCIONES_C
--    END

--SELECT AÑO, MES, SUCURSAL, EMPRESA, ID_AREA, COUNT(NAP) ATENCIONES
--INTO #ATENCIONES_C
--FROM #ATENCIONES
--GROUP BY AÑO, MES, SUCURSAL, EMPRESA, ID_AREA OPTION(MAXDOP 04)


-----NUMERADOR

--IF OBJECT_ID('tempdb..#DERIVACIONES') IS NOT NULL
--    BEGIN
--        DROP TABLE #DERIVACIONES
--    END

--SELECT H.AÑO, H.MES, H.SUCURSAL, H.EMPRESA, H.ID_AREA, A.AREA, COUNT(DISTINCT H.NAP) DERIVACIONES
--INTO #DERIVACIONES
--FROM #ATENCIONES H
--     INNER JOIN
--(
--    SELECT DISTINCT
--           nap_anterior, id_tm_resultadotramitesolicitud, AREA, RTRIM(DESCRIPCION) DESCRIPCION
--    FROM autorizacion --WITH (INDEX(IDX_DERIVACIONES))
--    WHERE año = @AÑO
--          AND mes BETWEEN @MESINI AND @MESFIN
--          AND (AREA IN('Laboratorio Clinico', 'Ecografía', 'Rayos X', 'Medicamentos')
--    OR (area = 'Consulta Externa'
--        AND GrupoServicioPrincipal = 'CONSULTA ESPECIALIZADA'))
--) a ON h.nap = a.Nap_Anterior
--GROUP BY H.AÑO, H.MES, H.SUCURSAL, H.EMPRESA, H.ID_AREA, A.AREA
--OPTION(MAXDOP 4);


-----CONSOLIDADO

--INSERT INTO Derivaciones.DERIVACIONES_CONSOLIDADO_SUCURSAL
--       SELECT AÑO, MES, SUCURSAL, EMPRESA, ID_AREA, ATENCIONES,
--                                                    CASE
--                                                        WHEN CE IS NULL
--                                                        THEN '0'
--                                                        ELSE CE
--                                                    END AS 'CE',
--                                                           CASE
--                                                               WHEN EC IS NULL
--                                                               THEN '0'
--                                                               ELSE EC
--                                                           END AS 'EC',
--                                                                  CASE
--                                                                      WHEN LC IS NULL
--                                                                      THEN '0'
--                                                                      ELSE LC
--                                                                  END AS 'LC',
--                                                                         CASE
--                                                                             WHEN MC IS NULL
--                                                                             THEN '0'
--                                                                             ELSE MC
--                                                                         END AS 'MC',
--                                                                                CASE
--                                                                                    WHEN RX IS NULL
--                                                                                    THEN '0'
--                                                                                    ELSE RX
--                                                                                END AS 'RX'
--       FROM
--(
--    SELECT AT.AÑO, AT.MES, AT.SUCURSAL, AT.EMPRESA, AT.ID_AREA, AT.ATENCIONES, SUM(CASE
--                                                                                       WHEN D.AREA = 'Consulta Externa'
--                                                                                       THEN D.DERIVACIONES
--                                                                                   END) AS CE, SUM(CASE
--                                                                                                       WHEN D.AREA = 'Ecografía'
--                                                                                                       THEN D.DERIVACIONES
--                                                                                                   END) AS EC, SUM(CASE
--                                                                                                                       WHEN D.AREA = 'Laboratorio Clinico'
--                                                                                                                       THEN D.DERIVACIONES
--                                                                                                                   END) AS LC, SUM(CASE
--                                                                                                                                       WHEN D.AREA = 'Medicamentos'
--                                                                                                                                       THEN D.DERIVACIONES
--                                                                                                                                   END) AS MC, SUM(CASE
--                                                                                                                                                       WHEN D.AREA = 'Rayos X'
--                                                                                                                                                       THEN D.DERIVACIONES
--                                                                                                                                                   END) AS RX
--    FROM #ATENCIONES_C AT
--         LEFT JOIN #DERIVACIONES D ON AT.AÑO = D.AÑO
--                                      AND AT.MES = D.MES
--                                      AND AT.SUCURSAL = D.SUCURSAL
--                                      AND AT.EMPRESA = D.EMPRESA
--                                      AND AT.ID_AREA = D.ID_AREA
--    GROUP BY AT.AÑO, AT.MES, AT.SUCURSAL, AT.EMPRESA, AT.ID_AREA, AT.ATENCIONES
--) SOURCE OPTION(MAXDOP 4)
--END
--GO


-----RPT CONSOLIDADO---

--DECLARE @AÑO INT, @MES INT, @SUCURSAL INT
--DECLARE @AREA_REMITE VARCHAR(50), @EMPRESA VARCHAR(50), @AREA_DESTINO VARCHAR(50)
--SET @AÑO = 2018;
--SET @MES = 8;
--SET @SUCURSAL = 1
--SET @AREA_REMITE = 1
--SET @EMPRESA = 'Salud Total EPS'
--SET @AREA_DESTINO = 'Consulta Externa'

--DECLARE @sql NVARCHAR(MAX)
--DECLARE @TB VARCHAR(50)
--SET @TB = 'tempdb..#DERIVACIONES'
--SET @sql = N'

--		  IF OBJECT_ID('''+@TB+''') IS NOT NULL
--    BEGIN
--        DROP TABLE #DERIVACIONES
--END

--		SELECT AÑO, MES, SUCURSAL, EMPRESA, AREA_REMITE, ATENCIONES, ['+CONVERT(VARCHAR(255), @AREA_DESTINO)+'] AS DERIVACIONES
--		INTO #DERIVACIONES
--		FROM Derivaciones.DERIVACIONES_CONSOLIDADO_SUCURSAL
--		WHERE AÑO = '+CONVERT(VARCHAR(255), @AÑO)+'
--          AND MES IN ('+CONVERT(VARCHAR(255), @MES)+')
--          AND SUCURSAL IN ('+CONVERT(VARCHAR(255), @SUCURSAL)+')
--         AND EMPRESA = '''+@EMPRESA+'''
--		 AND AREA_REMITE = '+CONVERT(VARCHAR(255), @AREA_REMITE)+'

--		 SELECT * FROM #DERIVACIONES
--		 '
--		 PRINT @SQL
--EXEC sp_executesql
--     @sql;

-----CREACION SP

--CREATE PROCEDURE RPT.DERIVACIONES_CONSOLIDADO_SUCURSAL
--(@AÑO          INT,
-- @MES          VARCHAR(50),
-- @SUCURSAL     VARCHAR(50),
-- @EMPRESA      VARCHAR(50),
-- @AREA_REMITE  VARCHAR(50),
-- @AREA_DESTINO VARCHAR(50)
--)
--AS
--     BEGIN
--         DECLARE @sql NVARCHAR(MAX)
--         DECLARE @TB VARCHAR(50)
--         SET @TB = 'tempdb..#DERIVACIONES'
--         SET @sql = N'
--		 SET NOCOUNT ON;
--	     SET FMTONLY OFF;

--		 IF OBJECT_ID('''+@TB+''') IS NOT NULL
--	     BEGIN
--         DROP TABLE #DERIVACIONES
--		 END

--		 SELECT AÑO, MES, SUCURSAL, EMPRESA, AREA_REMITE, ATENCIONES, ['+CONVERT(VARCHAR(255), @AREA_DESTINO)+'] AS DERIVACIONES
--		 INTO #DERIVACIONES
--		 FROM Derivaciones.DERIVACIONES_CONSOLIDADO_SUCURSAL
--		 WHERE AÑO = '+CONVERT(VARCHAR(255), @AÑO)+'
--           AND MES IN ('+@MES+')
--           AND SUCURSAL IN ('+@SUCURSAL+')
--         AND EMPRESA = '''+@EMPRESA+'''
--		 AND AREA_REMITE = '+CONVERT(VARCHAR(255), @AREA_REMITE)+'

--		 SELECT * FROM #DERIVACIONES
--		 '
--         EXEC sp_executesql
--              @sql
--     END
--GO


--EXEC RPT.DERIVACIONES_CONSOLIDADO_SUCURSAL 2018,9,1,'Salud Total EPS', 1, 'Consulta Externa';
