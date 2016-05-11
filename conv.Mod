MODULE conv;

IMPORT Files, Out := Console, Strings, s, ArmsciiUTF;

CONST ucsText          = "baratian.txt";
      outputText       = "baratian.tab";
      utfText          = "baratian-utf8.txt";
      wordsCount       = 27053; (*25473*)

TYPE 
      word = POINTER TO wordDesc;
      wordDesc = RECORD
          name : s.shortstring;
          trns : s.shortstring;
          desc : s.longstring; 
		  next : word;
     END;

PROCEDURE ReadChar(VAR r : Files.Rider; VAR ch: CHAR);
BEGIN
  REPEAT
    Files.Read(r, ch);
  UNTIL (ch # 0X) OR r.eof
END ReadChar;

PROCEDURE WriteChar(VAR r : Files.Rider; ch : CHAR);
BEGIN
   Files.WriteByte(r, SHORT(ORD(ch))); (* write ascii character *)
   Out.Char(ch);
END WriteChar;

PROCEDURE WriteStaticString(VAR r : Files.Rider; str0 : s.shortstring);
BEGIN
  Files.WriteBytes(r, str0, Strings.Length(str0));
  Out.String(str0);
END WriteStaticString;

PROCEDURE WriteString(VAR r : Files.Rider; str : s.string);
BEGIN
  Files.WriteBytes(r, str^, LEN(str^)-1);
  Out.String(str^);
END WriteString;

PROCEDURE dumpString(VAR str: s.shortstring);
VAR
  ch : CHAR;
  i, j  : INTEGER;
BEGIN
j := LEN(str);;
i := 0;
REPEAT
  Out.Char(str[i]);
  INC(i)
UNTIL (ch = 0X) OR (i = j - 1);
END dumpString;

PROCEDURE getEnglishWord(VAR r : Files.Rider; VAR f : Files.File; VAR tmp: s.shortstring);
VAR
  ch : CHAR;
  i, pos : LONGINT;
  enough: BOOLEAN;
BEGIN
  i := 0;
  enough := FALSE;
  REPEAT
    ReadChar(r, ch);
    IF ch # '[' THEN
      IF ch = 0AX THEN
	    tmp[i] := ' '
	  ELSE
	    tmp[i] := ch
	  END;
      INC(i);
    ELSIF ch = '[' THEN
       enough := TRUE;
       pos := Files.Pos(r);
       Files.Set(r, f, pos-1);
       IF tmp[i-1] = ' ' THEN tmp[i-1] := 0X ELSE tmp[i] := 0X END
    END; 
  UNTIL enough;
END getEnglishWord;

PROCEDURE toTab;
VAR
  utfFile, ucsFile, outFile : Files.File;
  utfRider, ucsRider, outRider : Files.Rider;
  wrd : word;
  i : LONGINT;
  tmp, tmp2 : s.shortstring;
BEGIN
  utfFile := Files.Old(utfText);
  IF utfFile = NIL THEN Out.String(utfText); Out.String(" not found."); Out.Ln; HALT(1); END;
  ucsFile := Files.Old(ucsText);
  IF ucsFile = NIL THEN Out.String(ucsText); Out.String(" not found."); Out.Ln; HALT(1) END;
  Files.Set(utfRider, utfFile, 0);
  Files.Set(ucsRider, ucsFile, 0); 
  outFile := Files.New(outputText);
  Files.Set(outRider, outFile, 0);
  i := 0;
  NEW(wrd);
  REPEAT
    Out.String("getting English word"); Out.Ln;
    getEnglishWord(utfRider, utfFile, tmp);
    Out.Int(i, 0); Out.Char(' '); Out.String(utfText); Out.String(': "');    
    Out.String(tmp); Out.Char('"'); Out.Ln;
    getEnglishWord(ucsRider, ucsFile, tmp2);
    Out.Int(i, 0); Out.Char(' '); Out.String(ucsText); Out.String(':      "');    
    Out.String(tmp2); Out.Char('"'); Out.Ln;
    IF tmp = tmp2 THEN
	  Out.String("Bingo!"); Out.Ln;
	  Out.String("Using this word"); Out.Ln;
	  wrd.name := tmp;
	END;
    INC(i); 
  UNTIL (i = 1) OR utfRider.eof OR ucsRider.eof;

  Files.Close(utfFile);
  Files.Close(ucsFile);
  Files.Register(outFile);
  Files.Close(outFile);
END toTab;

PROCEDURE fix;
VAR
  utfFile, ucsFile : Files.File;
  utfRider, ucsRider : Files.Rider;
BEGIN
  utfFile := Files.Old(utfText);
  ucsFile := Files.Old(ucsText);
  (* fix absent ']' at the end of the transcription of the word "desertion" *)
  Files.Set(utfRider, utfFile, 1090503);
  Files.WriteByte(utfRider, 93);
  Files.Set(ucsRider, ucsFile, 747847);
  Files.WriteByte(ucsRider, 93);
 
  (*Files.Register(utfFile);*)
  Files.Close(utfFile);
  (*Files.Register(ucsFile);*)
  Files.Close(ucsFile);
END fix;

BEGIN
  (*fix;*)
  toTab;

END conv.
