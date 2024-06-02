// F03_4_AddUID_CsvOrder_Cols

// Recall, we've still got the duplicate info of [File_Name] and [Z_YYMM] in our table. We'll remove [File_Name], so that [Z_YYMM] is the only column identifying which file the data came from.
// We'll also create a new column, [UID], which is `[IdxByMth] + [Z_YYMM]`. We could replace [IdxByMth] with [UID]. However, we'll keep [IdxByMth] because it can be handy/lightwieght for if we want/need to re-sort the table-rows.

(cln_stlmtamt_tbl) as table => let 

Result = let 

	Remove_FNme = Table.RemoveColumns(
		cln_stlmtamt_tbl, {"File_Name"}
		),

	Add_UID = Table.AddColumn(
		Remove_FNme, 
		"UID", 
		each Number.Round(
			[IdxByMth] + [Z_YYMM], 4, RoundingMode.AwayFromZero
			), 
		type number
		), 

	AddCsvOrderIdx = Table.AddIndexColumn(
		Add_UID, 
		"CsvOrderIdx", 
		0, 1, 
		type number
		)

in 
	AddCsvOrderIdx 

in 
Result
