MODULE fixer;
IMPORT Files, Out := Console;
CONST 
      ucsText          = "baratian.txt";
      ucsOutText          = "baratian_fixed.txt";
      utfText          = "baratian-utf8.txt";
      utfOutText          = "baratian-utf8_fixed.txt";
      
PROCEDURE fixAbsentSB(fileName: ARRAY OF CHAR; pos: LONGINT);
VAR
  r : Files.Rider;
  f : Files.File;
BEGIN
  f := Files.Old(fileName);
  IF f = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(r, f, pos);
  Files.WriteByte(r, 93); (* write ']' at given position *)
  Files.Register(f);
  Files.Close(f);
END fixAbsentSB;

PROCEDURE isNumber(ch : CHAR): BOOLEAN;
VAR
  o : LONGINT;
BEGIN
  o := ORD(ch);
  IF ((o > 47) & (o < 58)) THEN RETURN TRUE ELSE RETURN FALSE END
END isNumber;

PROCEDURE Eliminate(fileName, outName : ARRAY OF CHAR);
VAR
  R, outR : Files.Rider;
  F, outF : Files.File;
  ch, ch1 : CHAR;
  pos, pos1 : LONGINT;
  found: BOOLEAN;
BEGIN
  F := Files.Old(fileName);
  IF F = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(R, F, 0);
  outF := Files.New(outName);
  IF outF = NIL THEN Out.String(outName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(outR, outF, 0);
  REPEAT
    Files.Read(R, ch);
	IF ch = 0AX THEN
	  pos := Files.Pos(R);
      Files.Read(R, ch);
	  IF ch = 0AX THEN (* second 0A *)
        Files.Read(R, ch);
		IF ch = 0CX THEN (* form feed found, read till next 0A *)
          (* need to read till next 0A *)
		  REPEAT
            Files.Read(R, ch);
		  UNTIL ch = 0AX;
		  (*Files.WriteByte(outR, 0AX);*)
          (* leave 0A only if the following line contains '[' *)
			 pos1 := Files.Pos(R);
                found := FALSE;
	         REPEAT
               Files.Read(R, ch);
		       IF ch = '[' THEN found := TRUE END;
		     UNTIL (ch = 0AX) OR R.eof;
		     IF ~found THEN
(*		       Files.WriteByte(outR, 020X);*)
		     ELSE
		       Files.WriteByte(outR, 0AX);
		     END;
             Files.Set(R, F, pos1);

		ELSIF isNumber(ch) THEN (* page number found *)
		   ch1 := ch;
           Files.Read(R, ch); 
           IF isNumber(ch) THEN
		     REPEAT
               Files.Read(R, ch) 
		     UNTIL ch = 0AX;
             REPEAT
               Files.Read(R, ch) 
		     UNTIL ch = 0AX;
             REPEAT
               Files.Read(R, ch) 
		     UNTIL ch = 0AX;
          (* leave 0A only if the following line contains '[' *)
			 pos1 := Files.Pos(R);
                found := FALSE;
	         REPEAT
               Files.Read(R, ch);
		       IF ch = '[' THEN found := TRUE END;
		     UNTIL (ch = 0AX) OR R.eof;
		     IF ~found THEN
		       (*Files.WriteByte(outR, 020X);*)
		     ELSE
		       Files.WriteByte(outR, 0AX);
		     END;
             Files.Set(R, F, pos1);
		   ELSE (* second is not number *)
			 Files.WriteByte(outR, 020X);
			 Files.WriteByte(outR, ch1);
			 Files.WriteByte(outR, 020X);
		   END
        ELSE (* not form feed, not number *)
		  Files.WriteByte(outR, 0AX);
		  Files.WriteByte(outR, ch);
		  REPEAT
            Files.Read(R, ch);
			IF ch # 0AX THEN Files.WriteByte(outR, ch) END
		  UNTIL ch = 0AX;
		  Files.WriteByte(outR, 020X);
		  Files.Read(R, ch);
		  IF ch = 0AX THEN
		    REPEAT
		      Files.Read(R, ch);
		      IF ch # 0AX THEN Files.WriteByte(outR, ch) END
		    UNTIL ch = 0AX;
		  END
		END;
	  ELSE (* no second 0A *)
        found := FALSE; (* leave 0A only if the following line contains '[' *)
		REPEAT
          Files.Read(R, ch);
		  IF ch = '[' THEN found := TRUE END;
		UNTIL (ch = 0AX) OR R.eof;
		IF ~found THEN
		  Files.WriteByte(outR, 020X);
		ELSE
		   Files.WriteByte(outR, 0AX);
		END;
        Files.Set(R, F, pos);
	  END;
	ELSE (* not 0A *)
	  (*IF ch = 03X THEN
        Files.WriteByte(outR, 0B5X); (* բ looks broken in text *)
		Files.Read(R, ch);
	  ELSIF (ch = 01CX) THEN
	    Files.WriteByte(outR, 022X); (* quotation mark *)
	  ELSIF (ch = 0A8X) THEN (* this is somehow և in the text *)
	    Files.WriteByte(outR, 0A2X);
	  (*ELSIF (ch = 02DX) THEN (* hyphen *)
	    Files.WriteByte(outR, 0ADX);*)
	  (*ELSIF (ch = 03AX) THEN (* : *)
	    Files.WriteByte(outR, 0A3X);*)
	  ELSIF (ch = 020X) THEN
	    pos := Files.Pos(R);
		Files.Read(R, ch);
		IF ch = 019X (* should be ' in text *) THEN
          Files.WriteByte(outR, 027X);
		ELSIF ch = 01DX THEN
         (* Files.WriteByte(outR, 0A6X);*) (*  »  *)
          Files.WriteByte(outR, 022X); (*  "  *)
		ELSIF ch = 01CX THEN
		  (*Files.WriteByte(outR, 0A7X);*) (*  «  *)
		  Files.WriteByte(outR, 022X); (*  "  *)
		ELSE
		*)
        (*  Files.Set(R, F, pos);
		  Files.WriteByte(outR, 020X);
		END*)
	 (* ELSE*)
	    Files.WriteByte(outR, ch)
	  (*END*)
	END;
  UNTIL R.eof;
  Files.Close(F);
  Files.Register(outF);
  Files.Close(outF);
END Eliminate;

PROCEDURE fixLines(fileName: ARRAY OF CHAR);
VAR
  F : Files.File;
  R : Files.Rider;
  ch : CHAR;
  pos : LONGINT;
BEGIN
  F := Files.Old(fileName);
  IF F = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(R, F, 0);
  REPEAT
    Files.Read(R, ch);
	IF ch = 0AX THEN
	   pos := Files.Pos(R);
	   Files.Read(R, ch);
	   IF ch = 0AX THEN
         Files.Set(R, F, pos-1);
		 Files.WriteByte(R, 020X);
		 Files.WriteByte(R, 020X);
	   END;
	END;
  UNTIL R.eof;
  Files.Register(F);
  Files.Close(F);
END fixLines;

PROCEDURE fixLineEndings(fileName: ARRAY OF CHAR);
VAR
  F : Files.File;
  R : Files.Rider;
  ch : CHAR;
  pos : LONGINT;
  found : BOOLEAN;
BEGIN
  F := Files.Old(fileName);
  IF F = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(R, F, 0);
  REPEAT
    Files.Read(R, ch);
    IF ch = 0AX THEN
      pos := Files.Pos(R);
      (* check if next line contains '[' character *)
      found := FALSE;
      REPEAT
        Files.Read(R, ch);
        IF ch = '[' THEN found := TRUE END 
      UNTIL (ch = 0AX) OR R.eof;
      IF ~found THEN
        Files.Set(R, F, pos-1);
        Files.WriteByte(R, 020X);
      END
    END;
  UNTIL R.eof;
  Files.Register(F);
  Files.Close(F);
END fixLineEndings;

BEGIN
  (* fix absent ']' at the end of the transcription of the word "desertion" *)

  fixAbsentSB(utfText, 1090503);
  fixAbsentSB(ucsText, 747847);

(* now need to eliminate following sequences
   ---
   0A
   0A
   0C (^L, Form Feed, FF)
   someword
   0A
   ---
   now text continues

   and
   ---
   0A
   0A
   number from two or three digits
   0A
   0A
   someword
   0A
   -----
   now text continues

*)
 
  Eliminate(utfText, utfOutText);  
  Eliminate(ucsText, ucsOutText);  
(*
  (* replace  all double eols with ' ' *)
  fixLines(utfOutText);
  fixLines(ucsOutText);
  (* replace all eols with ' ' if there is a '[' at the next line *)
  fixLineEndings(utfOutText);
  fixLineEndings(ucsOutText);
*)  
END fixer.

