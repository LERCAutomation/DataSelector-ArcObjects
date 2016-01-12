USE [NBNData_TVERC]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[AFHLSelectSppSubset]
		@Schema = N'dbo',
		@SpeciesTable = N'TVERC_Spp_Full',
		@ColumnNames = N'TaxonGroup, TaxonName, CommonName',
		@WhereClause = N'TaxonGroup = ''Birds''',
		@GroupByClause = N'CommonName, TaxonName, TaxonGroup',
		@OrderByClause = N'CommonName',
		@UserId = N'Hester'

SELECT	'Return Value' = @return_value

GO
