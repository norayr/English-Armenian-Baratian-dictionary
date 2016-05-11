MODULE conv;

IMPORT Files, Out := Console, Strings, ArmsciiUTF;

CONST ucsText          = "baratian.txt";
      outputText       = "baratian.tab";
      utfText          = "baratian-utf8.txt";
      wordsCount       = 27053; (*25473*)

TYPE str = ARRAY 255 OF CHAR;
     lstr = ARRAY 2000 OF CHAR;

      word = RECORD
      name : str;
      trns : str;
      desc : lstr; 
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

PROCEDURE WriteStaticString(VAR r : Files.Rider; str0 : str);
BEGIN
  Files.WriteBytes(r, str0, Strings.Length(str0));
  Out.String(str0);
END WriteStaticString;

PROCEDURE WriteString(VAR r : Files.Rider; str : ArmsciiUTF.string);
BEGIN
  Files.WriteBytes(r, str^, LEN(str^)-1);
  Out.String(str^);
END WriteString;

PROCEDURE getEnglishWord(VAR r : Files.Rider; VAR f : Files.File; VAR tmp: str);
VAR
  ch : CHAR;
  tmpstr : str;
  i, pos : LONGINT;
  enough: BOOLEAN;
BEGIN
  i := 0;
  enough := FALSE;
  REPEAT
    ReadChar(r, ch);
    IF (ch # 0AX) & (ch # '[') THEN
      tmpstr[i] := ch;
      INC(i);
    ELSIF ch = '[' THEN
       enough := TRUE;
       pos := Files.Pos(r);
       Files.Set(r, f, pos-1);
       IF tmpstr[i-1] = ' ' THEN tmpstr[i-1] := 0X ELSE tmpstr[i] := 0X END
    END; 
  UNTIL enough;
END getEnglishWord;

PROCEDURE toTab;
VAR
  utfFile, ucsFile, outFile : Files.File;
  utfRider, ucsRider, outRider : Files.Rider;
  words : ARRAY wordsCount OF word; 
  wrd : word;
  i : LONGINT;
  tmp : str;
BEGIN
  utfFile := Files.Old(utfText);
  ucsFile := Files.Old(ucsText);
  Files.Set(utfRider, utfFile, 0);
  Files.Set(ucsRider, ucsFile, 0); 
  outFile := Files.New(outputText);
  Files.Set(outRider, outFile, 0);
  i := 0;
  REPEAT
    getEnglishWord(utfRider, utfFile, tmp);
    Out.Int(i, 0); Out.Char(' ');    
    Out.String(tmp); Out.Ln;
    wrd.name := tmp;

    getEnglishWord(ucsRider, ucsFile, tmp);
    Out.Int(i, 0); Out.Char(' ');    
    Out.String(tmp); Out.Ln;
    
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
 
  Files.Register(utfFile);
  Files.Close(ucsFile);
  Files.Register(utfFile);
  Files.Close(ucsFile);
END fix;

BEGIN
  fix;
  toTab;

END conv.
