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
          (*Files.Read(R, ch); (* if 0A 0A 0C number, which happens *)
          IF isNumber(ch) THEN
    	    skipTill(R, 0AX);
		    skipTill(R, 0AX);
		    skipTill(R, 0AX);
          ELSE*)
            (* need to read till next 0A *)
		    skipTill(R, 0AX);
          (*END;*)
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

PROCEDURE fixNonRegularChars;
VAR
  i, j : LONGINT;
  tmp, tmp1 : ARRAY 32 OF CHAR;
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

  (* replace 0C before baggy word, because it's indeed an english word *)
  replaceChar(ucsText, 236234, 020X);
  replaceChar(utfText, 344567, 020X);

  (* same, replace 0C before the second "bargain" word *)
  replaceChar(ucsText, 249798, 020X);
  replaceChar(utfText, 364337, 020X);

  (* same, replace 0C before "bat III" word *)
  (* 0c is at 256474 and we need to eliminate previous 0a as well *)
  replaceChar(ucsText, 256473, 062X); (* b *)
  replaceChar(ucsText, 256474, 061X); (* a *)
  replaceChar(ucsText, 256475, 074X); (* t *)
  replaceChar(ucsText, 256476, 020X); (* ' ' *)
  replaceChar(ucsText, 256477, 049X); (* I *)
  replaceChar(ucsText, 256478, 049X); (* I *)
  replaceChar(ucsText, 256479, 049X); (* I *)
  replaceChar(ucsText, 256480, 020X); (* ' ' *)
  replaceChar(ucsText, 256481, 020X); (* ' ' *)
  replaceChar(ucsText, 256482, 020X); (* ' ' *)

  (*replaceChar(utfText, 374009, 020X);*)
  replaceChar(utfText, 374008, 062X); (* b *)
  replaceChar(utfText, 374009, 061X); (* a *)
  replaceChar(utfText, 374010, 074X); (* t *)
  replaceChar(utfText, 374011, 020X); (* ' ' *)
  replaceChar(utfText, 374012, 049X); (* I *)
  replaceChar(utfText, 374013, 049X); (* I *)
  replaceChar(utfText, 374014, 049X); (* I *)
  replaceChar(utfText, 374015, 020X); (* ' ' *)
  replaceChar(utfText, 374016, 020X); (* ' ' *)
  replaceChar(utfText, 374017, 020X); (* ' ' *)

 
  (* set as number to match the 0A, 0A, number, 0A, 0A, 0A pattern *)
  (* there is 0A 0A bat III 0A 0A number which becomes 0A 0A number *)
  i := 258138;
  REPEAT
  replaceChar(ucsText, i, 31X);
  INC(i)
  UNTIL i = 258148;

  i := 376437;
  REPEAT
  replaceChar(utfText, i, 31X);
  INC(i)
  UNTIL i = 376446;

  (* battle-plane word looks like
  0A
  0A
  0C
  86 - number
  0A
  0A
  battle-plane
  0A
  battle-plane
  0A
  նաթիռ։
  0A
  0A
  [] - transcription
  n գրոհային ինք֊
  *)
  (* first fix that 0C with number *)
  replaceChar(ucsText, 259719, 031X);
  replaceChar(utfText, 378763, 031X);

  (* now replace 0A after word with 20 *)
  replaceChar(ucsText, 259749, 020X);
  replaceChar(utfText, 378793, 020X);

  (* now fix the text, bring transcription after the word *)
  (* write transcription, does not matter what inside [] *)
  replaceChar(ucsText, 259750, 020X);
  replaceChar(ucsText, 259751, 020X);
  replaceChar(ucsText, 259752, 020X);
  replaceChar(ucsText, 259753, 020X);
  replaceChar(ucsText, 259754, 020X);
  replaceChar(ucsText, 259755, 5BX);
  replaceChar(ucsText, 259756, 020X);
  replaceChar(ucsText, 259757, 020X);
  replaceChar(ucsText, 259758, 020X);
  replaceChar(ucsText, 259759, 020X);
  replaceChar(ucsText, 259760, 020X);
  replaceChar(ucsText, 259761, 020X);
  replaceChar(ucsText, 259762, 020X);
  replaceChar(ucsText, 259763, 020X);
  replaceChar(ucsText, 259764, 020X);
  replaceChar(ucsText, 259765, 020X);
  replaceChar(ucsText, 259766, 5DX);

  (* description *)
  (* 20, 6E, 20, B7, F1, E1, D1, B3, DB, C7, DD, 20, C7 DD F9 2D *)
  replaceChar(ucsText, 259767, 020X);
  replaceChar(ucsText, 259768, 06EX);
  replaceChar(ucsText, 259769, 020X);
  replaceChar(ucsText, 259770, 0B7X); (* գրոհային ինք *)
  replaceChar(ucsText, 259771, 0F1X);
  replaceChar(ucsText, 259772, 0E1X);
  replaceChar(ucsText, 259773, 0D1X);
  replaceChar(ucsText, 259774, 0B3X);
  replaceChar(ucsText, 259775, 0DBX);
  replaceChar(ucsText, 259776, 0C7X);
  replaceChar(ucsText, 259777, 0DDX);
  replaceChar(ucsText, 259778, 020X);
  replaceChar(ucsText, 259779, 0C7X);
  replaceChar(ucsText, 259780, 0DDX);
  replaceChar(ucsText, 259781, 0F9X);
  replaceChar(ucsText, 259782, 0DDX); (* նաթիռ: *)
  replaceChar(ucsText, 259783, 0B3X);
  replaceChar(ucsText, 259784, 0C3X);
  replaceChar(ucsText, 259785, 0C7X);
  replaceChar(ucsText, 259786, 0E9X);
  replaceChar(ucsText, 259787, 03AX);
  replaceChar(ucsText, 259788, 0AX);

  (* last 2D is hyphen, needs to be replaced with colon *)
  (* end of article *)
  (* DD, B3, C3, C7, E9, 3A *)   

  (* now fix transcription in utf file *)
  i := 378794;
  REPEAT
    replaceChar(utfText, i, 020X);
    INC(i)
  UNTIL i = 378807; 

  i := 378823; (* write something as description *)
  REPEAT
    replaceChar(utfText, i, 06EX);
    INC(i)
  UNTIL i = 378848;  
  
  replaceChar(utfText, 378848, 03AX);
  replaceChar(utfText, 378849, 0AX);

  (* bent word is absent in pdf output *)
  replaceChar(ucsText, 282694, 0AX);
  replaceChar(ucsText, 282695, 'b');
  replaceChar(ucsText, 282696, 'e');
  replaceChar(ucsText, 282697, 'n');
  replaceChar(ucsText, 282698, 't');
  replaceChar(ucsText, 282699, ' ');
  replaceChar(ucsText, 282700, ' ');

  replaceChar(utfText, 412037, 0AX);
  replaceChar(utfText, 412038, 'b');
  replaceChar(utfText, 412039, 'e');
  replaceChar(utfText, 412040, 'n');
  replaceChar(utfText, 412041, 't');
  replaceChar(utfText, 412042, 020X);
  replaceChar(utfText, 412043, 020X);

END fixNonRegularChars;

BEGIN

fixNonRegularChars;

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

