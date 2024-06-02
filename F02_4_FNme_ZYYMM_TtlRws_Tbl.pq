// F02_4_FNme_ZYYMM_TtlRws_Tbl



(FNme2ZYYMM_rcrd, FNme2TtlRws_rcrd) as table => let 

Result = let 

	// NB: This process is totally dependent on `FNme2YZZMM_rcrd` & `FNme2TtlRws_rcrd` records having their file-name field-names in the same order (not just having the same file-name field-names).
	// It'd be easy to cross-check this, but for efficiency (and since both records are constructed in a similar way & from same source - i.e. low risk here) we won't.
		// In fact, the reason `F02_2` & `F02_3` don't return simply `ZYYMM_ColLst` and `TtlRws_ColLst` below, is so that we can easily X-check that the results of the 2, are indeed re the files in the same order.
		// Although there's not really much defense for why they're records, and not each x2 lists nested in a list. ...

	FNmes_ColLst = Record.FieldNames(FNme2ZYYMM_rcrd), 

	ZYYMM_ColLst = Record.FieldValues(FNme2ZYYMM_rcrd), 

	TtlRws_ColLst = Record.FieldValues(FNme2TtlRws_rcrd),

	Tbl_Typ = type table [
		FNme = text, ZYYMM = number, TtlRws = number
		],

	Rtrn_Tbl = Table.FromColumns(
		{FNmes_ColLst, ZYYMM_ColLst, TtlRws_ColLst
			}, 
		Tbl_Typ
		)
in 
	Rtrn_Tbl 

in 
Result


