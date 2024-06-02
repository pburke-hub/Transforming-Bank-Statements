// F02_3_Get_SubTbls_TtlRows



let 

LstOfLsts_Tbl = "", 
	// = `F02_1_InitCSVsReadIn(FolderInfo_Tbl)`.

ScriptFunc = 

(tbl_w_LstCols) as record => let 

Result = let 

	LstOf_FNmeColLsts = tbl_w_LstCols[Name], 
		// This is a list of lists. Each nested-list contains a file-name that's repeated as many times as there are rows in the file's table.

	FNmes_Lst = List.Transform(
		LstOf_FNmeColLsts, 
		List.First
		), 

	Tbl_Lens_Lst = List.Transform(
		LstOf_FNmeColLsts, 
		List.Count
		),

	FNme2TtlRows_Rcrd = Record.FromList(
		Tbl_Lens_Lst, // data / values
		FNmes_Lst // field names
		)

in 
	FNme2TtlRows_Rcrd 
	// End of `Result` expression/definition.

in 
	Result
	// End of `ScriptFunc` definition/expression.

in 
	ScriptFunc
	// End of this script's `let`-statement.



