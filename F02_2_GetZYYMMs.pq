// F02_2_GetZYYMMs



(fldrinfo_tbl as table) as record => let 

Result = let 

	CsvArgs = [Columns = 6, Encoding = TextEncoding.Utf8
		], 

	CsvPeriod_ReaderFunc = (content as binary) as list => let 
		// Specifically: `(content) as {date} => ...`

		Source_Tbl = Table.Range(
			Csv.Document(content, CsvArgs
				), 
			1, // offset - i.e. skipping the 1st row.
			2 // count, i.e. getting only the 2nd & 3rd rows
			), 
		RelevCols = Table.SelectColumns(
			Source_Tbl, {"Column5", "Column6"}
			), 
			// We expect this to get the header values of "From Date" and "To Date" in the 1st row (& located in `RelevCols`'s 1st row). However, we won't use/evaluate this data. We're doing this work/reading-in, simply for easy-access if debugging.
			// Instead of checking the header-values, we'll perform the better check of whether the values below those headers describe either a date or datetime.

		Relev_RowLst = Record.FieldValues(
			RelevCols{1} // i.e. `RelevCols`'s 2nd-row.
			),

		D8Pair_Lst = List.Transform(
			Relev_RowLst, XChecked_D8Getter
			)
			// This will either be a list of x2 date values, or an error (which was accessed via `TryVarbl[Error]`).
	in 
		D8Pair_Lst, 
		// ^ "End" of `CsvPeriod_ReaderFunc` expression / function-defn ...

		// ... Except, we need to define the `XChecked_D8Getter` function:
	XChecked_D8Getter = (txt_val as text) as date => let 
		Try1st = try DateTime.FromText(txt_val
			), 
		Try2nd = if Try1st[HasError] 
			then 
				try Date.FromText(txt_val) 
			else 
				try DateTime.Date(
					Try1st[Value]
					), 
				// Could use `DateTime.Date(Try1st[Value])` without the `try`, but then `Try2nd` could be either a scalar value, or a try-expression/record. 
		
		D8_Val = if Try2nd[HasError] 
			then Try2nd[Error] 
			else Try2nd[Value]
	in 
		D8_Val, 


	// Finanlly, actually getting something / doing something with our source (not just defining functions):
	ContentFName_Tbl = Table.SelectColumns(
		fldrinfo_tbl, 
		{"Content", "Name"}
		), 

	TblW_D8Pairs = Table.TransformColumns(
		ContentFName_Tbl, 
		{"Content", 
			CsvPeriod_ReaderFunc, type list
			}
		),
		// If was serious, would 1st get these as `datetime` pairs, and check that our reports cover a continous period / each neighbouring pair's border items have a difference of 0.

	// Getting there! (I.e. Now we've gotten the [Content] column to contain the x2 `type date` values in each cell.)
	// Now we need to get from our date pairs/lists to 0.YYMM values:
	D8Pair2YY_MM = (d8_pair as list) as list => let 

		DD_Pair = List.Transform(
			d8_pair, Date.Day
			),
		DDs_Same = (DD_Pair{0} = DD_Pair{1}
			),

		RtrnVal = if DDs_Same 
			then SimpleVal 
			else MidVal,

		MidVal = Calc_YY_MM(d8_pair), 

		// Now, just need to get `SimpleVal`:

		D8_From = d8_pair{0}, 
		D8_To = d8_pair{1},

		D8To_Less1Mth = Date.AddMonths(
			D8_To, -1
			),
			// NB: This `Date.AddMonths` will correctly deal with when our TRR reports on a January month :)

		DecremdPair = {D8_From, D8To_Less1Mth}, 

		Decrem_MM_Pair = List.Transform(
			DecremdPair, Date.Month
			),
		From_Mth = Decrem_MM_Pair{0}, // DRY since also used by `SimpleYYMM`
		
		MMs_Increment = (From_Mth = Decrem_MM_Pair{1}
			), // Recall: `Decrem_MM_Pair{1}` is re `D8To_Less1Mth`.

		SimpleVal = if MMs_Increment 
			then SimpleYYMM 
			else MidVal,

		SimpleYYMM = {
			Date.Year(D8_From), 
			From_Mth
			}
	in 
		RtrnVal,

	// Cool. Now, finishing off `D8Pair2YY_MM`-func by defining the `Calc_YY_MM` function:
	Calc_YY_MM = (d8_pair as list) as list => let 

		HalfPeriod = Duration.TotalDays(
			(d8_pair{1} - d8_pair{0}) / 2
			), 
			// NB: `Duration.TotalDays` will return `n.5` if report's total days is an odd number. (Ergo, below, we round to an integer.)
		MidPoint = Date.AddDays(
			d8_pair{0}, 
			Number.Round(HalfPeriod, 0)
			),
		
		YY_Val = Date.Year(MidPoint),
		MM_Val = Date.Month(MidPoint
			), 
		Calcd_YY_MM = {YY_Val, MM_Val} 
	in 
		Calcd_YY_MM, 

	// Okay, we have a function (i.e. `D8Pair2YY_MM`) for getting our YY & MM integers. However, we want 0.YYMM. So let's wrap `D8Pair2YY_MM` in a function that does that for us. 
	D8Pair2_ZYYMM = (d8_pair as list) as number => let 

		YY_MM = D8Pair2YY_MM(d8_pair), // The above-mentioned 'wrapping'.
		YY = YY_MM{0},
		MM = YY_MM{1},
		
		Z_YYMM = Number.Round(
			(YY - 2000)/100 + MM/1e4, 
			// Recall: 1e4 = 10,000. (i.e. 1 * 10^4.)
			4, 
			RoundingMode.AwayFromZero
			)
	in 
		Z_YYMM,

	// Again, finally done defining functions, let's get our Z_YYMM values! :)
	TblW_Z_YYMM_s = Table.TransformColumns(
		TblW_D8Pairs, 
		{"Content", 
			D8Pair2_ZYYMM, type number
			}
		), 


	// If any reports have the same YYMM, then their tables will use the same indexes. I.e. It won't be unique, and so it won't be an index!
		// We better have a cross-check for this ...
	
	All_YYMMs_Different = List.IsDistinct(
		TblW_Z_YYMM_s[Content]
		), 
	
	Tested_YYMMs = try (
		if All_YYMMs_Different 
			then FName_ZYYMM_Rcrd 
				// ^ NB: Calling this `Tested_YYMMs`, but we sneak a column-renaming-&-to-record operation in it as well (via this `FName_ZYYMM_Rcrd` variable).
			else error DuplicYYMMs_ErrMsg
		), 

	DuplicYYMMs_ErrMsg = "TODO: DuplicYYMMs_ErrMsg / `All_YYMMs_Different` error.", 

	// Let's get our desired output: 
		// (Assuming the `Tested_YYMMs`-condition was satisfied.) 
	FName_ZYYMM_Rcrd = let 
		
		ReNme = Table.RenameColumns(
			TblW_Z_YYMM_s, 
			{"Content", "Value"} // Coincidentally, [Name] is already what `Record.FromTable` wants for the field-names column.
			),
			// I.e. [Name] contains file-name strings, and [Value] contains corresponding 0.YYMM values.

		Rslt_Rcrd = Record.FromTable(ReNme
			)
	in 
		Rslt_Rcrd, 

	XChecked_Output = if Tested_YYMMs[HasError] 
		then Tested_YYMMs[Error] 
		else Tested_YYMMs[Value] 
in 
	XChecked_Output 

in 
	Result


