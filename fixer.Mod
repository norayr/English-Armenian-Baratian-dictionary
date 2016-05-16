MODULE fixer;
IMPORT Files, Out := Console;
CONST 
      ucsText          = "baratian.txt";
      ucsOutText          = "baratian_fixed.txt";
      ucsOutText1          = "baratian_fixed_.txt";
      utfText          = "baratian-utf8.txt";
      utfOutText          = "baratian-utf8_fixed.txt";
      utfOutText1          = "baratian-utf8_fixed_.txt";
      
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

PROCEDURE replaceChar(fileName: ARRAY OF CHAR; pos: LONGINT; ch : CHAR);
VAR
  r : Files.Rider;
  f : Files.File;
BEGIN
  f := Files.Old(fileName);
  IF f = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(r, f, pos);
  Files.WriteByte(r, ch);
  Files.Register(f);
  Files.Close(f);
END replaceChar;

PROCEDURE isNumber(ch : CHAR): BOOLEAN;
VAR
  o : LONGINT;
BEGIN
  o := ORD(ch);
  IF ((o > 47) & (o < 58)) THEN RETURN TRUE ELSE RETURN FALSE END
END isNumber;

PROCEDURE skipTill (VAR R : Files.Rider; ch : CHAR);
BEGIN
  REPEAT
    Files.Read(R, ch) 
  UNTIL ch = 0AX;
END skipTill;

PROCEDURE skipIf0A(VAR R : Files.Rider; VAR F: Files.File);
VAR
  ch : CHAR;
  pos : LONGINT;
BEGIN
  pos := Files.Pos(R);
  Files.Read(R, ch);
  IF ch # 0AX THEN Files.Set(R, F, pos - 1) END
END skipIf0A;

PROCEDURE lineContains(VAR R : Files.Rider; VAR F: Files.File; st : CHAR): BOOLEAN;
VAR
  ch : CHAR;
BEGIN
    REPEAT
        Files.Read(R, ch);
        IF ch = st THEN RETURN TRUE END;
    UNTIL (ch = 0AX) OR R.eof;
    RETURN FALSE
END lineContains;

PROCEDURE isPrev(R : Files.Rider; F : Files.File; ch : CHAR): BOOLEAN;
VAR p : LONGINT;
    c : CHAR;
BEGIN
  p := Files.Pos(R);
  Files.Set(R, F, p-1);
  Files.Read(R, c);
  IF c = ch THEN RETURN TRUE ELSE RETURN FALSE END
END isPrev;

PROCEDURE checkWriteNext(VAR R, outR: Files.Rider; F, outF: Files.File);
VAR pos: LONGINT;
BEGIN
  (* leave 0A only if the following line contains '[' *)
  pos := Files.Pos(R);
  IF lineContains(R, F, '[') THEN
    Files.WriteByte(outR, 0AX);
  ELSE
    IF isPrev(outR, outF, 3AX) (* : *) THEN
      Files.WriteByte(outR, 0AX);
    ELSE
      Files.WriteByte(outR, 020X);
    END;
  END;
  Files.Set(R, F, pos);
END checkWriteNext;

PROCEDURE readWriteTill(VAR R, outR: Files.Rider; st: CHAR);
VAR
  ch : CHAR;
BEGIN
    REPEAT
      Files.Read(R, ch);
      IF ch # st THEN Files.WriteByte(outR, ch) END
    UNTIL ch = st;
	(*IF isPrev(outR, outF, 3AX) THEN*)
END readWriteTill;

PROCEDURE Eliminate(fileName, outName : ARRAY OF CHAR);
VAR
  R, outR : Files.Rider;
  F, outF : Files.File;
  ch, ch1: CHAR;
  pos : LONGINT;
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
		  skipTill(R, 0AX);
		  checkWriteNext(R, outR, F, outF);
		ELSIF isNumber(ch) THEN (* page number found *)
		   ch1 := ch;
           Files.Read(R, ch); 
           IF isNumber(ch) THEN
			 skipTill(R, 0AX);
			 skipTill(R, 0AX);
			 skipTill(R, 0AX);
		     checkWriteNext(R, outR, F, outF);
		   ELSE (* second is not number *)
			 Files.WriteByte(outR, 020X);
			 Files.WriteByte(outR, ch1);
			 Files.WriteByte(outR, 020X);
		   END
        ELSE (* not form feed, not number *)
		  (*Files.WriteByte(outR, 0AX);*)
		  Files.WriteByte(outR, ch);
		  readWriteTill(R, outR, 0AX);
		  Files.WriteByte(outR, 020X);
		  Files.Read(R, ch);
		  IF ch = 0AX THEN
            readWriteTill(R, outR, 0AX);		    
			(*skipIf0A(R, F);*)
			IF isPrev(R, F, 03AX) THEN
			  Files.WriteByte(outR, 0AX);
			END;
		  END
		END;
	  ELSE (* no second 0A *)
       (* leave 0A only if the following line contains '[' *)
		IF lineContains(R, F, '[') THEN
		  Files.WriteByte(outR, 0AX);
		ELSE
		   Files.WriteByte(outR, 020X);
		END;
        Files.Set(R, F, pos);
	  END;
	ELSE (* not 0A *)
	  Files.WriteByte(outR, ch)
	END;
  UNTIL R.eof;
  Files.Close(F);
  Files.Register(outF);
  Files.Close(outF);
END Eliminate;
(*
PROCEDURE fixLines(fileName, outName: ARRAY OF CHAR);
VAR
  R, outR : Files.Rider;
  F, outF : Files.File;
  ch: CHAR;
BEGIN
  F := Files.Old(fileName);
  IF F = NIL THEN Out.String(fileName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(R, F, 0);
  outF := Files.New(outName);
  IF outF = NIL THEN Out.String(outName); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(outR, outF, 0);
  REPEAT
    Files.Read(R, ch);
    IF ch = 
  
  UNTIL R.eof;
END fixLines;
*)
BEGIN
  (* fix absent ']' at the end of the transcription of the word "desertion" *)
  replaceChar(utfText, 1090503, 05DX);
  replaceChar(ucsText, 747847, 05DX);

  (* replace eol after bagger word *)
  (*replaceChar(utfText, 341791, 020X);
  replaceChar(ucsText, 234390, 020X);*) (* no it should not be replaced because this is not a word, but a page header *)

  (* fix double eol after bagger word description *)
  replaceChar(ucsText, 234426, 020X);
  replaceChar(utfText, 341856, 020X);

  (* fix double eol after abominate word *)
  (*replaceChar(utfText, 11512, 020X);
  replaceChar(utfText, 11513, 020X);
  replaceChar(ucsText, 7780, 020X);
  replaceChar(ucsText, 7781, 020X);*)





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

  (* replace 20X with 0AX before abomination word *)
  replaceChar(ucsOutText,7774 (* 7777 *), 0AX);
  replaceChar(utfOutText, 11523  (*11526*), 0AX);
  (* replace 0A in the middle of agglutinate word description *) 
  replaceChar(ucsOutText, 78800, 020X);
  replaceChar(utfOutText, 116068, 020X);

  (* replace 0A with 020 before badge word *)
  (*replaceChar(ucsOutText, 234426, 020X);*)
  (*replaceChar(utfOutText, *)

  (*fixLines(ucsOutText, ucsOutText1);
  fixLines(utfOutText, utfOutText1);*)
END fixer.

