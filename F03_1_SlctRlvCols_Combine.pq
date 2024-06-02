// F03_1_SlctRlvCols_Combine



// Re the x28 columns case:
	/* 
	Irrelevant columns to remove: 
		Obviously, the (artificially read-in/created) 29th column needs to be removed. 
		8th column: "Estimated settled At" (lower-case "s" not a typo.) 
		18th column: "Settlement Type"
		21st column: "Payment Attempt Id" 
		24th column: "Reason" 
		26th column: "Beneficiary Bank Account Number" 
		27th column: "Remitting Bank" 
	I.e. The from-0 index-positions of: {7, 17, 20, 23, 25, 26, 28}.
	*/ 

// Re the x29 columns case:
	/* 
	Irrelevant columns to remove: 
		8th column: "Estimated settled At" (lower-case "s" not a typo.) 
		18th column: "Settlement Type" 
		21st column: "Payment Attempt Id" 
		22nd column: "Payment Intent Id" 
		25th column: "Reason" 
		27th column: "Beneficiary Bank Account Number" 
		28th column: "Remitting Bank"
	I.e. The from-0 index-positions of: {7, 17, 20, 21, 24, 26, 27}.
	*/

let 
	Lst_RemovePsns = "", // Intending for this to be a shared func / its own query.

	ScriptFunc = 

(cntnt_nme_hasx29_tbl as table) => let 

Result = let 

	X28_Irrelevs = {7, 17, 20, 
		23, 25, 26, 28
		}, 
	X29_Irrelevs = {7, 17, 20, 
		21, 24, 26, 27
		},

	LstOfSubTblColLsts_OnlyRelevs = let 
		X28_ToGos = List.Buffer(X28_Irrelevs),
		X29_ToGos = List.Buffer(X29_Irrelevs),
			// Presuming that let-statements cause garbage-collection on completion, the burden of having these lists in-memory should be temporary :) 

		RowProcessor = (ct_nm_h29_rcrd) as list => let 

			IrrelevIdxs = if ct_nm_h29_rcrd[HasX29Cols] 
				then X29_ToGos 
				else X28_ToGos, 
			
			SubTblCols_IrrelevsGone = Lst_RemovePsns(
				ct_nm_h29_rcrd[Content], 
				IrrelevIdxs
				), 

			AddFNameCol = SubTblCols_IrrelevsGone & {
				ct_nm_h29_rcrd[Name]
				} 
		in 
			AddFNameCol, 
			// End of `RowProcessor` expression/func-defn.

		RelevColsLsts = Table.TransformRows(
			cntnt_nme_hasx29_tbl,
			RowProcessor
			)
	in 
		RelevColsLsts, 
		// ^ End of `LstOfSubTblColLsts_Wout_IrrelevCols` expression.

	// NB: Despite being a `Table`-method, `Table.TransformRows` returns a `list`. 
		// In this case, a list of each file's list of column-lists.
	// Now, we'll rearrange this list to be a list = {{col1-lists}, {col2-lists}, ...}. 

	Matching_Col_Lsts = List.Zip(
		LstOfSubTblColLsts_OnlyRelevs 
		// This object/variable already has our nested lists wrapped in a list, so no need to nest it in a `{}`.
		), 

	FullTbl_ColsLst = List.Transform(
		Matching_Col_Lsts, List.Combine
		), 

	MostlyTxtCols_Tbl = Table.FromColumns(
		FullTbl_ColsLst, 
		type table rowTyp
		),

	// Re the `Table.FromColumns(lists, columns)` syntax /& `MostlyTxtCols_Tbl` above:
		// We've got `lists` (i.e. `FullTbl_ColsLst`). 
		// However, we still need `columns` (i.e. `RowTyp` for `type table rowTyp`) ...

	Tbl_ColNmes = {
		"Type", "Transaction Id", "Financial Transaction Type", 
		"Source Id", "Source Entity", "Request Id", 
		"Created At", "Settled At", "Status", 
		"Settlement Currency", "Settlement Amount", "Fee", 
		"Net Amount", "Transaction Currency", "Transaction Amount", 
		"Exchange Rate", "Batch Id", 
		"Payment Method", "Order Id", "Reference", 
		"Beneficiary Bank Account Name", "Remitter Name", // Here = x22 col's so far.  
		"IdxByMth", "File_Name"
		}, 
		// Also NB: [Status] & [Source Id] are lucky to be extracted at all. Just figure it's nice to be able to view/peview them. However, we won't keep them for long.

	TxtColTyp = [Type = type text, Optional = false
		], 
	// Re v: I Am hardcoding a total of x24 columns here. (However, could take a more robust approach of using `List.Count(Tbl_ColNmes)`).
	ColTyps_Lst = List.Repeat({TxtColTyp}, 22) & {
		[Type = type number, Optional = false], TxtColTyp
		}, 

	rowTyp = Type.ForRecord(
		Record.FromList(
			ColTyps_Lst, 
			Tbl_ColNmes
			), 
		false
		), 

	// Cool. Now we've got all the code for `MostlyTxtCols_Tbl`.

	RemoveSrcID_Status = Table.RemoveColumns(
		MostlyTxtCols_Tbl, 
		{"Source Id", "Status"}
		), 

	Uniq_Trnsn_IDs = List.IsDistinct(
		RemoveSrcID_Status[Transaction Id]
		), 
		
	Combod_Tbl = if Uniq_Trnsn_IDs 
		then 
			RemoveSrcID_Status 
		else 
			error "The [Transaction ID]'s aren't unique."

in 
	Combod_Tbl

in 
Result

in 
ScriptFunc
