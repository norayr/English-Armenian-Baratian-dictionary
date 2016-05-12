MODULE conv;

IMPORT Files, Out := Console, Strings, s, ArmsciiUTF;

CONST ucsText          = "baratian_fixed.txt";
      outputText       = "baratian.tab";
      utfText          = "baratian-utf8_fixed.txt";
      wordsCount       = 27053; (*25473*)

TYPE 
      word = POINTER TO wordDesc;
      wordDesc = RECORD
          name : s.shortstring;
          trns : s.shortstring;
          desc : s.longstring; 
		  next : word;
     END;

PROCEDURE isLatin(ch : CHAR): BOOLEAN;
VAR
  o : LONGINT;
BEGIN
  o := ORD(ch);
  IF ((o >= 65) & (o <= 90)) OR ((o >= 97) & (o <= 122)) THEN 
    RETURN TRUE 
  ELSE 
    RETURN FALSE
  END
END isLatin;

PROCEDURE isArmscii(VAR ch : CHAR) : BOOLEAN;
BEGIN
IF (ORD(ch) >= 162) & (ORD(ch) <= 254) THEN RETURN TRUE ELSE RETURN FALSE END
END isArmscii;

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

PROCEDURE WriteConvertLongString(VAR r : Files.Rider; lstr: s.longstring);
VAR
  i : LONGINT;
  str : s.string;
BEGIN
  i := 0;
  REPEAT
    IF isArmscii(lstr[i]) THEN
      str := ArmsciiUTF.A2U(lstr[i]);
	  WriteString(r, str);
	ELSE
	  (*IF lstr[i] = 01CX THEN 
	    WriteChar(r, '"')
	  (*ELSIF lstr[i] = 03X THEN
		str := ArmsciiUTF.A2U(
		*)
	  ELSE
	  *)
	  WriteChar(r, lstr[i]);
	  (*END*)
	END;
	INC(i)
  UNTIL (lstr[i] = 0X) OR (i = LEN(lstr));
END WriteConvertLongString;

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

PROCEDURE getDescription(VAR r : Files.Rider; VAR f : Files.File; VAR tmp: s.longstring);
VAR 
  ch: CHAR;
  i: LONGINT;
  enough: BOOLEAN;
BEGIN
  i := 0;
  enough := FALSE;
  REPEAT
    Files.Read(r, ch);
	IF (ch # 0AX) THEN
	  tmp[i] := ch;
	  INC(i);
    ELSIF ch = 0AX THEN
	  enough := TRUE;
	  tmp[i] := 0X;
	END
  UNTIL enough;
END getDescription;

PROCEDURE getTranscription(VAR r : Files.Rider; VAR tmp: s.shortstring);
VAR
  ch : CHAR;
   i : INTEGER;
BEGIN
  (* read till get '[' *)
  REPEAT
    Files.Read(r, ch);
  UNTIL ch = '[';
  i := 0;
  tmp[i] := ch;
  INC(i);
  (* read till get ']' *)
  REPEAT
    Files.Read(r, ch);
    tmp[i] := ch;
	INC(i)
  UNTIL ch = ']';
  tmp[i] := 0X
END getTranscription;

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
  ltmp, ltmp2: s.longstring;
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
    Out.Ln; Out.String("getting English word"); Out.Ln;
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
	ELSE
	  Out.String("something went wrong!"); Out.Ln;
	  HALT(1)
	END;

	Out.Ln; Out.String("getting transcription"); Out.Ln;
    getTranscription(utfRider, tmp);
    getTranscription(ucsRider, tmp2);
	Out.String(utfText); Out.String(': "'); Out.String(tmp); Out.Char('"'); Out.Ln;
    Out.String(ucsText); Out.String(':      "'); Out.String(tmp2); Out.Char('"'); Out.Ln;
    wrd.trns := tmp;
	Out.Ln; Out.String("getting description"); Out.Ln;

    getDescription(ucsRider, ucsFile, ltmp);
    getDescription(utfRider, utfFile, ltmp2);
    
	Out.String("writing to tab file"); Out.Ln;
    WriteStaticString(outRider, wrd.name);
	WriteChar(outRider, 09X);
	WriteStaticString(outRider, wrd.trns);
	WriteConvertLongString(outRider, ltmp);
    WriteChar(outRider, 0AX);
    INC(i); 
  UNTIL (i = 5) OR utfRider.eof OR ucsRider.eof;

  Files.Close(utfFile);
  Files.Close(ucsFile);
  Files.Register(outFile);
  Files.Close(outFile);
END toTab;

BEGIN

  toTab;

END conv.
