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
  ch : CHAR;
  pos, pos1 : LONGINT;
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
		    Files.WriteByte(outR, 0AX);
		ELSIF isNumber(ch) THEN (* page number found *)
		   pos1 := Files.Pos(R);
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
		   ELSE (* second is not number *)
             Files.Set(R, F, pos-1);
			 Files.Read(R, ch);
			 Files.WriteByte(outR, ch);
             Files.Read(R, ch);
			 Files.WriteByte(outR, ch);
             Files.Read(R, ch);
			 Files.WriteByte(outR, ch);
             (*Files.Read(R, ch);
			 Files.WriteByte(outR, ch);*)
		   END
        ELSE (* not form feed, not number *)
		  Files.WriteByte(outR, 0AX); (* writing just double eol and char *)
		  Files.WriteByte(outR, 0AX);
		  Files.WriteByte(outR, ch);
		END;
	  ELSE (* no second 0A *)
        Files.Set(R, F, pos-1);
	    Files.Read(R, ch);
	    Files.WriteByte(outR, ch);
	  END;
	ELSE (* not 0A *)
	  Files.WriteByte(outR, ch);
	END;
  UNTIL R.eof;
  Files.Close(F);
  Files.Register(outF);
  Files.Close(outF);
END Eliminate;
(*
PROCEDURE fixLines(fileName: ARRAY OF CHAR);
VAR
  F : Files.File;
  R : Files.Rider;
  ch : CHAR;
BEGIN
  F := Files.Old(fileName);
  IF f = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(R, F, 0);
  REPEAT
    Files.Read(R, ch);
	IF ch = 0AX THEN
	  if isNextLineWord(R) THEN
	END;
  UNTIL R.eof;
END fixLines;
*)
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

  (* replace eols with ' ' if next line does not contain '[' *)
  (*fixLines(utfOutText);*)
END fixer.

