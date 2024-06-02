```fs

// F01_FolderProcessing

(dir as text) as table => let 

Result = let 

	FldrPath = Text.Trim(dir),

	FolderInfo = Folder.Contents(FldrPath
		),
		// NB: C/w `Folder.Files`, `Folder.Contents` ignores sub-directories' contents/files.

	// NB: The columns of the `Folder.Contents` table includes: "Content", "Name", "Folder Path", "Date accessed", "Date modified", "Date created", & "Extension".
	// Also NB: "Extension" and "Name" will be of `type text`.

	OnlyCsvs = Table.SelectRows(
		FolderInfo,
		each [Extension] = ".csv"
		),

	RemoveHiddenFileRows = let 

		GetHiddenAttrib = Table.TransformColumns(
			OnlyCsvs,
			{
				"Attributes", 
				(rcrd) as logical => rcrd[Hidden], 
				type logical // Strangely, `Table.ExpandRecordColumn` expands [Hidden] as `type any`. However, if we transform the record-column, then we can typecast the [Hidden] column. 
				}
			), 
		ReNme = Table.RenameColumns(
			GetHiddenAttrib, {"Attributes", "Hidden"}
			), 
		OnlyNonHidden_s = Table.RemoveMatchingRows(
			ReNme, 
			{[Hidden = true]}, 
			"Hidden"
			)
	in 
		OnlyNonHidden_s,


	AddBase4Future_HasX29Cols_Col = let 
	
		Add_Duplic = Table.DuplicateColumn(
				RemoveHiddenFileRows, 
				"Content", "HasX29Cols", 
				type binary
				),  

		Csv_Args = [Columns = 29, Encoding = TextEncoding.Utf8
			], 
		ReadCSV = (csv_file) => Csv.Document(csv_file, Csv_Args // Recall: `Csv.Document` returns a table.
			), 

		HasX29Cols_InfoGetter = (csv_file as binary) as text => let 
				Header28th = ReadCSV(csv_file){5}[Column28],
					// Re `{5}`: Recall: Headers are in the csv-files' 6th row.
				Last4Chars = Text.End(
					Header28th, 4)
			in 
				Last4Chars,

		GetHdr28th_4Chrs = Table.TransformColumns(
			Add_Duplic, 
			{"HasX29Cols", 
				HasX29Cols_InfoGetter,
				type text
				}
			) 
		
	in 
		GetHdr28th_4Chrs, 
		// End of `AddBase4Future_HasX29Cols_Col` expression / let-statement.


	Add_Hasx29Cols = Table.TransformColumns(
		AddBase4Future_HasX29Cols_Col, 
		{"HasX29Cols", 
			each if (_ = "Bank") then true 
				else if (_ = "Name") then false 
				else error ErrMsg & _,
			type logical}
		), 
		// Could have easily made a user-defined-func so that `GetHdr28th_4Chrs` & `Add_Hasx29Cols` are combined / performed by x1 `Table.TransformColumns` statement. However, `GetHdr28th_4Chrs` is potentially useful for debugging.

	ErrMsg = "Header of 28th column is inconsistent with both of [Remitter Name] & [Remitting Bank]. Ergo, unsure if this is a 28/29-column version of the TRR format. The header value was: ", 

	RemoveIrrelevs = Table.SelectColumns(
		Add_Hasx29Cols, 
		{"Content", "Name", "HasX29Cols"}
		), 

	// If there's a/any .csv-file whose [HasX29Cols] error'ed, then unless we scan through the column, lazy PQFLang won't raise the error. 
		// Test-driven development says it's better to be alerted to errors when they happen (c/w e.g. much later in x4 scripts' time). Ergo, we'll force any errors to be raised now.
	HasX29_ErrorCheck = let 
	
		ErrorRows = Table.SelectRowsWithErrors(
			RemoveIrrelevs, 
			{"HasX29Cols"}
			), 

		Error1st = try Table.FirstValue( // NB: break condition :)
			ErrorRows, 
			true // `true` is an arbitrary default-value (given the `try` statement below).
			)
	in 
		Error1st,

	Output_Tbl = if HasX29_ErrorCheck[HasError] 
		then 
			HasX29_ErrorCheck[Error] 
		else 
			RemoveIrrelevs

in 
	Output_Tbl 

in 
Result

```

