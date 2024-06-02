// F03_2_TypCast_AddD8_ZYYMM 



let 

Tbl_AddLstCol = "", 

ScriptFunc = 
(combod_tbl as table, fnmeZYYMMTtlRws_tbl as table) => let 

Result = let 

	D8ColNmes = {"Created At", "Settled At"}, 
	NumColNmes = {
		"Settlement Amount", "Fee", "Net Amount", "Transaction Amount", "Exchange Rate"
		},
		// NB: "IdxByMth" is indeed a `type number` column. However, we've already/originally typecasted it as such.
	D8TfrmerFunc = (val) as nullable date => DateTime.Date(DateTime.FromText(val)
		), 

	D8Tformns = List.Transform(
		D8ColNmes, 
		(col_nme) as list => {col_nme, D8TfrmerFunc, type date}
		), 
	NumTformns = List.Transform(
		NumColNmes, 
		(col_nme) as list => {col_nme, Number.FromText, type number}
		),

	TypedTbl = Table.TransformColumns(
		combod_tbl, 
		D8Tformns & NumTformns
		), 

	// Now, any `type text` column in `TypedTbl` is genuinely best represented/communicated in text form. 

	// Next, let's clean our text columns:

	TxtColNames = Table.ColumnsOfType(
		TypedTbl, {type text}
		), 
		// Might expect `Table.ColumnsOfType` to return a table, however, it actually returns a list of the relevant column names.

	TblOfClnTxt = let 
		TxtTfrmer = (val) as text => Text.Clean(Text.Trim(val)), 

		CleaningOps = List.Transform(
			TxtColNames, 
			(col_nme) as list => {col_nme, TxtTfrmer, type text}
			),

		ClnTbl = Table.TransformColumns(
			TypedTbl, 
			CleaningOps
			)
	in 
		ClnTbl, 


	// Now, let's reduce the [Created At] & [Settled At] columns into x1 column.
		// If we have a [Settled At] value, then we'll use it. Otherwise, (i.e. if `[Settled At]=null`) we'll use [Created At].
	Add_D8_Col = Table.CombineColumns(
		TblOfClnTxt, 
		{"Created At", "Settled At"}, // NB: `Combine_CAt_SAt` relies on this order.
		Combine_CAt_SAt, 
		"Date"
		), 

	Combine_CAt_SAt = (catsat_lst) as date => Expression.Evaluate(
		"s_at ?? c_at", 
		[c_at = catsat_lst{0}, s_at = catsat_lst{1}]
		), 
		// Recall: `??` is the null-coalesce operator. 
		// ^ Rationale = 
			/* Since the combiner-function receives only x1 list-argument, it's nice for readability to unpack the list to variables. One way to do that is to use `Expression.Evaluate`'s `environment` argument. 
			And a benefit of doing so, is that our computer then gets to 'do the work' of making our [Date] column/values in an uncluttered environment (i.e. where the only possible variables are `c_at` & `s_at`. Not even any of the standard functions like `List.Transform` or `Text.Trim`).
			*/


	// Okay. Now finally time to add in the `Z_YYMM` column.

	// NB: To get our `Z_YYMM` column-list, we assume/rely-on that `fnmeZYYMMTtlRws_tbl`'s order of file-names, is the same as `Add_D8_Col`'s order of file-names.
	ZYYMM_TtlRws_Tbl = Table.SelectColumns(
		fnmeZYYMMTtlRws_tbl, 
		{"ZYYMM", "TtlRws"} // i.e. remove "FNme" col.
		), 

	ZYYMM_TtlRws_RowLsts = Table.ToRows(
		ZYYMM_TtlRws_Tbl
		), 
	
	LstOf_RptdZYYMMLsts = List.Transform(
		ZYYMM_TtlRws_RowLsts, 
		each let 
			ZYYMM = _{0}, 
			TtlRws = _{1}, 
			RptdZYYMMLst = List.Repeat({ZYYMM}, TtlRws)
		in 
			RptdZYYMMLst
		),

	ZYYMM_ColLst = List.Combine(
		LstOf_RptdZYYMMLsts
		), 

	AddIn_ZYYMMCol = Tbl_AddLstCol(
		Add_D8_Col, 
		ZYYMM_ColLst, 
		"Z_YYMM", type number
		)
		// Cool. That's all this script's name has promised to do. And it seems long enough!

in 
	AddIn_ZYYMMCol 
	// ^ End of `Result` expression/definition.
in 
Result
	// ^ End of `ScriptFunc` expression/definition.

in 
ScriptFunc
	// ^ End of script's `let`-statement. (Which allowed us to introduce variables like `Tbl_AddLstCol`).

