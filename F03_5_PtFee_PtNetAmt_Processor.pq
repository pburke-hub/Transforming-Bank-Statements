// F03_5_PtFee_PtNetAmt_Processor



(tbl_widxsadded_arg) => let 

Result = let 

	// Check if there's any rows for which [Fee] is > or < 0, AND [Net Amount] is is also >/< 0.

	OnlyNullFees = let 
		Fee_Col = tbl_widxsadded_arg[Fee], 
		IsNullMask = List.Transform(
			Fee_Col, each (_ = null)
			),
		BoolRslt = List.AllTrue(IsNullMask // `List.AllTrue`, ergo a break condition for 1st `false` value encountered.
			) 
	in 
		BoolRslt,
		// ^ Due to eager-eval of `or` expressions/operations, `OnlyNullFees` is a break-condition :)

	InfoTbl = Table.SelectColumns(
		tbl_widxsadded_arg, 
		{"Settlement Amount", "Fee", "Net Amount", "Transaction Amount", "IdxByMth", "UID", "CsvOrderIdx"} // Will maybe want to add more later 
		),

	// Because we expect most rows to have `[Fee]=null`, let's use a specialised/efficient function to remove them:
	InfoTbl_NoNullFees = Table.RemoveMatchingRows(
		InfoTbl, 
		{[Fee = null]}, 
		"Fee"
		), 

	// Now, if we observe no [Net Amount] <> null, then we appear to have part-Fee part-remainder/tfer transactions. 
		// However, this is still aimed at quickly catching the no-work-to-do cases. NOT on robust analysis (e.g. we haven't ruled out the `[Fee]=0` case atm).
	Defs_NO_PtFeePtTrnsn_Rows = let 
		NAmt_Col = InfoTbl_NoNullFees[Net Amount],
		Is0NullMask = List.Transform(
			NAmt_Col, each (_ = 0) or (_ = null) // If so, then the [Fee] component appears to be 100% of the transaction.
			),
		BoolRslt = List.AllTrue(Is0NullMask // `List.AllTrue`, ergo a break condition for 1st `false` value encountered.
			) 
	in 
		BoolRslt,

	RtrnVal = if (OnlyNullFees or Defs_NO_PtFeePtTrnsn_Rows) 
		then 
			tbl_widxsadded_arg 
		else 
			ComplexRtrnVal, 

	ComplexRtrnVal = "TODO - via another function", 


	KeepGUI = RtrnVal 
in 
	KeepGUI 

in 
Result




