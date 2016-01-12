USE [NBNData_TVERC]
GO
/****** Object:  StoredProcedure [dbo].[AFSelectSppSubset]    Script Date: 12/01/2016 11:03:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create the stored procedure
ALTER PROCEDURE [dbo].[AFHLSelectSppSubset] @Schema varchar(50),
	@SpeciesTable varchar(50),
	@ColumnNames varchar(1000),
	@WhereClause varchar(1000),
	@GroupByClause varchar(1000),
	@OrderByClause varchar(1000),
	@UserId varchar(50)
AS
BEGIN

	SET NOCOUNT ON

	IF @UserId IS NULL
		SET @UserId = 'temp'

	DECLARE @debug int
	Set @debug = 1

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)
	DECLARE @params nvarchar(2000)

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	-- Drop the index on the sequential primary key of the temporary table if it already exists
	If EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable AND COLUMN_NAME = 'MI_PRINX' AND CONSTRAINT_NAME = 'PK_' + @TempTable + '_MI_PRINX')
	BEGIN
		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable +
			' DROP CONSTRAINT PK_' + @TempTable + '_MI_PRINX'
		EXEC (@sqlcommand)
	END
	
	-- Drop the temporary table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
	END

	-- Lookup table column names and spatial variables from Spatial_Tables
	DECLARE @IsSpatial bit
	DECLARE @XColumn varchar(32), @YColumn varchar(32), @SizeColumn varchar(32), @SpatialColumn varchar(32)
	DECLARE @CoordSystem varchar(254)
	
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Retrieving table spatial details ...'

	DECLARE @SpatialTable varchar(100)
	SET @SpatialTable ='Spatial_Tables'

	-- Retrieve the table column names and spatial variables
	SET @sqlcommand = 'SELECT @O1 = XColumn, ' +
							 '@O2 = YColumn, ' +
							 '@O3 = SizeColumn, ' +
							 '@O4 = IsSpatial, ' +
							 '@O5 = SpatialColumn, ' +
							 '@O6 = CoordSystem ' +
						'FROM ' + @Schema + '.' + @SpatialTable + ' ' +
						'WHERE TableName = ''' + @SpeciesTable + ''' AND OwnerName = ''' + @Schema + ''''

	SET @params =	'@O1 varchar(32) OUTPUT, ' +
					'@O2 varchar(32) OUTPUT, ' +
					'@O3 varchar(32) OUTPUT, ' +
					'@O4 bit OUTPUT, ' +
					'@O5 varchar(32) OUTPUT, ' +
					'@O6 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @XColumn OUTPUT, @O2 = @YColumn OUTPUT, @O3 = @SizeColumn OUTPUT, @O4 = @IsSpatial OUTPUT, 
		@O5 = @SpatialColumn OUTPUT, @O6 = @CoordSystem OUTPUT
		
	If @ColumnNames = ''
		SET @ColumnNames = '*'

	If @IsSpatial = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is spatial'

		If @WhereClause = ''
			SET @WhereClause = 'Spp.' + @SpatialColumn + ' IS NOT NULL'
		Else
			SET @WhereClause = @WhereClause + ' AND Spp.' + @SpatialColumn + ' IS NOT NULL'
	END

	If @GroupByClause <> ''
		SET @GroupByClause = ' GROUP BY ' + @GroupByClause

	If @OrderByClause <> ''
		SET @OrderByClause = ' ORDER BY ' + @OrderByClause

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection ...'

	-- Select the species records into the temporary table
	SET @sqlcommand = 
		'SELECT ' + @ColumnNames +
		' INTO ' + @Schema + '.' + @TempTable +
		' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
		' WHERE ' + @WhereClause +
		@GroupByClause +
		@OrderByClause
	EXEC (@sqlcommand)

	DECLARE @RecCnt Int
	Set @RecCnt = @@ROWCOUNT

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
