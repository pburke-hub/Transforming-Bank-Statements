// F02_1_InitCSVsReadIn

// Recall: table will have columns of "Content", "Name", & "HasX29Cols".

(fldrinfo_tbl as table) => let 

Result = let 

	Tform2ColOfCSVs_s_Tbls = Table.TransformColumns(
		fldrinfo_tbl, 
		{"Content", 
			Init_Reader_Func, type table
			}
		),

	CsvArgs = [Columns = 29, Encoding = TextEncoding.Utf8
		], 
		// Re `29`: Of course, there may be some x28-column .csv files. However, since this is the 1st time reading them, we don't know which of the files they are. 
			// We'll just bluntly read-in x29 columns. This causes a 29th column of "" for the x28-column files. (If, e.g. it caused the 2nd row's 1st value to be in the 1st row's 29th column etc., then that would be an issue!) 

	Init_Reader_Func = (content as binary) as list => let 
		// ^ This is basically `Csv.Document`, with noticeable bolt-ons of: (i) filtering out the non-"Settled" rows, and (ii) adding an index-column.

		Source_Tbl = Csv.Document(content, CsvArgs
			), 
		Only_Settled_Ts = Table.SelectRows(
			Source_Tbl, each [Column10] = "Settled"
			), 
			// ^ Doing this asap, because it filters out a lot of data. 
				// (Including the header-row, & the report-title/info 1st-5-rows.) 
			// Chose this over `Table.RemoveMatchingRows` with multiple filters to remove "", "Column10", "Pending", & "Settled". Proba more efficient, however, some unexpected value (e.g. `null`) is too risky.
		
		AddMthlyIdxInt = Table.AddIndexColumn(
			Only_Settled_Ts, 
			"IdxByMth_Txt", 
			0, 1, type number
			), 
			// Calling this "ByMth" because expecting/requiring each file to cover a 1-month long period. 
	
		Tform2LstOfColLsts = Table.ToColumns(
			AddMthlyIdxInt
			)

	in 
		Tform2LstOfColLsts, 
		// ^ End of `Init_Reader_Func` expression / func-defn.

	// Ergo, at `Tform2ColOfCSVs_s_Tbls`, we still have a table of: [Content], [Name], & [HasX29Cols].
		// Except, now, thanks to `Table.ToColumns`, each [Content] cell contains a list of lists, that's useful for constructing the tables of our .csv-files.

	TformFName2RptsLst = Table.ReplaceValue(
		Tform2ColOfCSVs_s_Tbls, 
		each let // old-value arg.
			SampleCol = List.First([Content]), 
			Ttl_Rows = List.Count(SampleCol) 
		in 
			Ttl_Rows, // I.e. Each file's table length.
		
		null, // new-value arg. Won't be eval'd here. 

		(subj, oldv, newv) as list => List.Repeat(
			{subj}, oldv
			), 
		{"Name"} // subject arg.
		), 


	// Query: Should I ensure [Name] is properly typed? (i.e. as type `list`.)
		// Well, the only practical difference is whether we have the appropriate symbol in the column-header of the PQ-Editor GUI. And, using `Table.TransformColumnTypes` causes an error (seems it requires a scalar type that has a `EgType.From` function). ...
		// I like a nice preview, so I'm going to hardcode the type & use `Value.ReplaceType`. (Very extravagant and naughty!)

	CastNme2Lst = Value.ReplaceType(
		TformFName2RptsLst, 
		type table [
			Content = list, Name = list, HasX29Cols = logical
			]
		)

in 
	CastNme2Lst 

in 
Result
