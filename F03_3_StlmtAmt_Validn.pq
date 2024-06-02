// F03_3_StlmtAmt_Validn

// On data without any 'suss-rows', this works fine (even previewing the plan-b variables). 

(tbl_w_D8nZYYMM_arg as table) as table => let 

Result = let 

	Tbl_AddLstCol = "",

	// Get a mask of whether [Settlement Amount] is a worrying value:
		// In fact, one that more specifically tells us whether the worrying value is `0` vs. `null`.

	SttlmtAmt_ColLst = tbl_w_D8nZYYMM_arg[Settlement Amount
		], 

	Mask_Maker = (val) as number => Number.Abs(
		Number.Sign(val)
		), 

	Null_0_Or_1_Lst = List.Transform(
		SttlmtAmt_ColLst, 
		Mask_Maker
		), 


	// Now, initial testing of [S-Amt]-introspection-results:

	R_No_0s_NOR_Nulls = List.MatchesAll( // TODO - swap to `List.ContainsAll` - it tells the computer that an equality operation will be used.
		Null_0_Or_1_Lst, 
		each _ = 1
		),

	RtrnVal = if R_No_0s_NOR_Nulls 
		then 
			tbl_w_D8nZYYMM_arg 
		else 
			PlanB_RtrnVal, 


	// Define Plan B's x3 Cases:
	Case_Key = if R_0_SmtAmts then 
			"Some_0_SAmts" 
		else if R_Null_AND_0_SmtAmts then 
			"Null_AND_0_SAmts" 
		else if R_Null_SmtAmts then 
			"Some_Null_SAmts" 
		else 
			error "TODO: `Case_Key` error message.", 

	FoundA_0_SmtAmt = List.Contains(
		Null_0_Or_1_Lst, 0
		),
	FoundA_Null_SmtAmt = List.Contains(
		Null_0_Or_1_Lst, null
		), 


	R_0_SmtAmts = (not FoundA_Null_SmtAmt
		) and FoundA_0_SmtAmt,
	
	R_Null_SmtAmts = (not FoundA_0_SmtAmt
		) and FoundA_Null_SmtAmt,
	
	R_Null_AND_0_SmtAmts = (
		FoundA_0_SmtAmt and FoundA_Null_SmtAmt
		),

	// Now done `Case_Key`'s code.

	// So let's use it!
	Relev_ValOrVals = let 
		Vals_Rcrd = [
			Some_0_SAmts = 0, 
			Null_AND_0_SAmts = {0, null}, 
			Some_Null_SAmts = null
			], 
		
		Relev_Val = Record.Field(
			Vals_Rcrd, Case_Key
			) 
	in 
		Relev_Val,


	Get_SussSmtAmt_RowIdxs = if R_Null_AND_0_SmtAmts 
		then 
			List.PositionOfAny(
				Null_0_Or_1_Lst, Relev_ValOrVals, 
				Occurrence.All
				) 
		else 
			List.PositionOf(
				Null_0_Or_1_Lst, Relev_ValOrVals, 
				Occurrence.All
				),


	NATA_Cols = {"Net Amount", "Transaction Amount"}, 

	Get_Suss_NATA_Tbl = let 

		NATA_Tbl = Table.SelectColumns(
			tbl_w_D8nZYYMM_arg, NATA_Cols
			), 

		NATA_Null01Mask_Tbl = Tbl_AddLstCol(
			NATA_Tbl, 
			Null_0_Or_1_Lst, 
			"SussMask", 
			type number
			), 

		OnlySussRows = Table.RemoveMatchingRows(
			NATA_Null01Mask_Tbl, 
			{[SussMask = 1]}, 
			"SussMask"
			) 
	in 
		OnlySussRows,


	// Now we want to introspect the corresponding NATA-rows.

	SussNATA_Masks_Tbl = let 

		Tformns_Lst = List.Transform(
			NATA_Cols, each {_, Mask_Maker, type number}
			), 

		MasksTbl = Table.TransformColumns(
			Get_Suss_NATA_Tbl, Tformns_Lst
			) 
	in 
		MasksTbl, 


	// If any suss-[N-Amt] or suss-[T-Amt] is a non-zero number, then that's quite expected given that [S-Amt] is `null`/`0` ...

	Init_Unexpected_Found = Table.ContainsAny(
		SussNATA_Masks_Tbl, 
		{
			[Net Amount = 1], 
			[Transaction Amount = 1]
			}, 
		NATA_Cols
		),

	// If `Init_Unexpected_Found`, then things are looking pretty grim ...
		// However, if so, then let's check that it isn't a case of perfectly offsetting [Net Amount] & [Fee] causing [Settlement Amount] to correctly be `0`.

	MustRaiseError = Init_Unexpected_Found and (
		NotCuredByOffsettingFee
		), 

		// Such an offset can only be if: (i) [SussMask] is `0` (c/w its other possible value of `null`); AND (ii) `SussNATA_Masks_Tbl`'s [Net Amount] is `1`.

	NotCuredByOffsettingFee = let 

		Rslt = if R_0_SmtAmts // I.e. Of the offending [S-Amt]'s, they're ONLY/ALL `0`. (NB: A `null` [S-Amt] can't be offset.)
			then 
				AnalysisBool 
			else 
				true,

		// NB: If we're eval'ing `AnalysisBool`, then we know that all unexpected [S-Amt] values are `0` (i.e. never `null`).

		// V = Unnecessary, but gives good hint at how `AnalysisBool` infers/deduces our desired info:
			// Ttl_Unexpctds = Table.RowCount(Get_Suss_NATA_Tbl), 

		All_MightBeOffset = Table.ContainsAll(
			Get_Suss_NATA_Tbl, 
			{[Net Amount = 1]}, 
			"Net Amount"
			), 

		AnalysisBool = not All_MightBeOffset
			// Should be more thorough. (I.e. In this case, go on to confirm that `[N-Amt]=[Fee]`, for all relevant rows). 
			// However, I'll leave that as a TODO atm.

	in 
		Rslt,
		// End of `NotCuredByOffsettingFee` expression.


	PlanB_RtrnVal = if MustRaiseError 
		then 
			error "TODO: `PlanB_RtrnVal` Error message." 
		else 
			Tbl_Remove_Null0_Rows(
				tbl_w_D8nZYYMM_arg
				), 
	
	// NB: If eval'ing `Tbl_RemoveNull0Rows` (i.e. `MustRaiseError` is `false`), then for all rows with [S-Amt]=`null`/`0`, we observed that [N-Amt] & [T-Amt] were also meaningless (i.e. `null`/`0`). 
	// I.e. All of the 'Suss-rows' turned out to be so-called "Expecteds".

	Tbl_Remove_Null0_Rows = (src_tbl) as table => let 
	
		Add_InitSussMask = Tbl_AddLstCol(
			src_tbl, 
			Null_0_Or_1_Lst, 
			"SussMask", 
			type number
			), 
	
		Get_BoolSussMask = Table.TransformColumns(
			Add_InitSussMask, 
			{"SussMask", 
				each (_ <> 1), // Recall: even `null <> 1` is `true`. (ie not `null`.)
				type logical
				}
			),	

		RemoveSussRows = Table.RemoveMatchingRows(
			Get_BoolSussMask, 
			{[SussMask = true]}, 
			"SussMask"
			),
	
		RemoveMask = Table.RemoveColumns(
			RemoveSussRows, 
			{"SussMask"}
			)
	in 
		RemoveMask, 
		// End of `Tbl_Remove_Null0_Rows` expression.

	// Finally done !!!


	KeepGUI = RtrnVal 
		// Also to refresh memory of `RtrnVal`'s creation way above.

in 
	KeepGUI


in 
Result











// OLD: 
		// each let 
		// 	Null_0_1_Or1Negv = Number.Sign(_ // returns `null` from `null`.
		// 		), 
		// 	Null_0_Or_One = Number.Abs(
		// 		Null_0_1_Or1Negv
		// 		) 
		// in 
		// 	Null_0_Or_One