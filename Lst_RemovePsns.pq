// Lst_RemovePsns

let 

Lst_RemovePsns = (inputLst as list, posns as list) as list => let 
	
	RtrnVal = if List.IsEmpty(posns) // Each iter's condition / rcursn's break condition.
		then inputLst 
		else Recursv_Rslt, 

	Recursv_Rslt = let 
		
		RelevIdx = List.First(posns
			), 
		
		ShortenedLst = List.RemoveRange(
			inputLst, RelevIdx, 1
			), 
		
		RemainderIdxs = List.Skip(posns // Will eventually return an empty list.
			), 
		Adjstd_Posns = List.Transform(
			RemainderIdxs, 
			each Number.Round(
				(_ - 1), 0
				)
			), 

		// `@` is for referencing the variable we're defining/assigning to. I.e. In PQFLang, `@` is for recursion.
		DoItAgain = @Lst_RemovePsns(
			ShortenedLst, 
			Adjstd_Posns
			) 
	in 
		DoItAgain 
in 
	RtrnVal

in 
Lst_RemovePsns 



