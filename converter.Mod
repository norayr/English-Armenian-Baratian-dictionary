MODULE converter;

IMPORT Files, Out := Console, Strings, s, ArmsciiUTF;

CONST
  inputText  = "baratian.txt";
  outputText = "baratian.tab";
  wordsCount       = 27053;

PROCEDURE errNotFound(name: ARRAY OF CHAR);
BEGIN
  Out.String("The file "); Out.String(name); Out.String(" not found."); Out.Ln;
  HALT(1)
END errNotFound;

PROCEDURE fixWord(VAR str : s.shortstring);
VAR
  i : LONGINT;
BEGIN
  i := Strings.Length(str);
  REPEAT
    DEC(i)
  UNTIL str[i] # 020X;
  str[i+1] := 0X
END fixWord;

PROCEDURE getEnglishWord(VAR R: Files.Rider; VAR str: s.shortstring);
VAR
  ch: CHAR;
  i : LONGINT;
BEGIN
   i := 0;
   REPEAT
     Files.Read(R, ch);
	 str[i] := ch;
	 INC(i)
   UNTIL ch = '[';
   str[i-1] := 0X;
END getEnglishWord;

PROCEDURE getTranscription(VAR R: Files.Rider; str: s.shortstring);
VAR
  i : LONGINT;
  ch : CHAR;
BEGIN
  str[0] := '[';
  i := 1;
  REPEAT
    Files.Read(R, ch);
    str[i] := ch;
    INC(i)
  UNTIL ch = ']';
  str[i] := 0X;
END getTranscription;

PROCEDURE isNumber(ch : CHAR): BOOLEAN;
VAR
  o : LONGINT;
BEGIN
  o := ORD(ch);
  IF ((o > 47) & (o < 58)) THEN RETURN TRUE ELSE RETURN FALSE END
END isNumber;

PROCEDURE skipLine(VAR R: Files.Rider);
VAR
  ch : CHAR;
BEGIN
  REPEAT
    Files.Read(R, ch)
  UNTIL ch = 0AX
END skipLine;

PROCEDURE contains(R: Files.Rider; pt: CHAR): BOOLEAN;
VAR
  ch : CHAR;
  b  : BOOLEAN;
BEGIN
  b := FALSE;
  REPEAT
    Files.Read(R, ch);
    IF ch = pt THEN b := TRUE END;
  UNTIL b OR (ch = 0AX);
  IF b THEN RETURN TRUE ELSE RETURN FALSE END
END contains;

PROCEDURE getDescription(VAR R: Files.Rider; VAR F: Files.File; VAR str: s.longstring);
VAR
  enough: BOOLEAN;
  i, j : LONGINT;
  ch : CHAR;
BEGIN
  enough := FALSE;
  i := 0;
  REPEAT
    Files.Read(R, ch);
    IF ch # 0AX THEN
      str[i] := ch;
      INC(i)
    ELSE
      IF str[i-1] = ':' THEN
        str[i] := 0X;
        enough := TRUE
      ELSE
		Files.Read(R, ch);
		IF isNumber(ch) THEN
		  (* check if the next line contains ^L *)
		  j := Files.Pos(R);
		  skipLine(R);
		  IF contains(R, 0CX) THEN
			(* skip second lines *)
			skipLine(R)
		  ELSE
			(* regular text, continue reading *)
			Files.Set(R, F, j);
			str[i] := ch;
			INC(i)  
		  END
		ELSE (* not number *)
		  (* check if it contains  ^L *)
		  IF contains(R, 0CX) THEN
			skipLine(R);
		  ELSE
			(* regular text, continue reading *)
			str[i] := ch;
			INC(i)
		  END
		END
      END (* if str[i-1] = ':' *)
    END; (* if ch # 0AX *)
  UNTIL enough;
END getDescription;

PROCEDURE Run;
VAR
  FS, FD : Files.File;
  RS, RD : Files.Rider;

  i : LONGINT;
  tmp, tmp2 : s.shortstring;
  ltmp: s.longstring;
BEGIN
  FS := Files.Old(inputText);
  IF FS = NIL THEN errNotFound(inputText) END;

  FD := Files.Old(outputText);
  IF FS = NIL THEN errNotFound(outputText) END;

  Files.Set(RS, FS, 0);
  Files.Set(RD, FD, 0);

  i := 0;
  REPEAT
    IF contains(RS, '[') THEN
       getEnglishWord(RS, tmp); 
	   fixWord(tmp);
       getTranscription(RS, tmp2);
       getDescription(RS, FS, ltmp);
    ELSE
      skipLine(RS)
    END
  UNTIL RS.eof OR (i = wordsCount);
END Run;

BEGIN
Run;

END converter.
