// Tbl_AddLstCol


(
	subj_tbl as table, col_Lst as list, 
	col_name as text, col_type as nullable type
) as table => let 


	Subj_s_ColNme_TypOptnal_Rcrd = Type.RecordFields(
		Type.TableRow(
			Value.Type(subj_tbl)
			)
		),

	NewTbl_s_TypOptnal_Rcrd = Record.AddField(
		Subj_s_ColNme_TypOptnal_Rcrd, 
		col_name, 
		[Type = col_type, Optional = false]
		),

	NewTbl_s_RowTyp = Type.ForRecord(
		NewTbl_s_TypOptnal_Rcrd, false
		),

	NewTbl_ColLsts = (
		Table.ToColumns(subj_tbl) & {col_Lst}
		),

	NewTbl = Table.FromColumns(
		NewTbl_ColLsts, 
		type table NewTbl_s_RowTyp
		)

in 
	NewTbl 