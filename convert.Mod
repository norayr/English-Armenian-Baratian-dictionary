MODULE convert;

IMPORT Files, Out := Console, Strings, ArmsciiUTF;

CONST inputFile        = "baratian.txt";
      outputFile       = "baratian.tab";
      transIn          = "baratian-utf8.txt";
      wordsCount       = 27053; (*25473*)

TYPE str = ARRAY 255 OF CHAR;

VAR trans : ARRAY wordsCount OF str;  

(*
PROCEDURE ReadTill(VAR r: Files.Rider; till: CHAR; VAR line: ARRAY OF CHAR);
VAR ch : CHAR;
i : LONGINT;
BEGIN
i := 0;
REPEAT
   Files.Read(r, ch);
   line[i] := ch;
   INC(i);
   IF i = LEN(line) THEN Out.String("Warning: array lenght reached"); Out.Ln END;
UNTIL (ch = till) OR r.eof;
line[i-1] := 0X;
line [i] := 0X;
END ReadTill;


PROCEDURE ReadLine(VAR r: Files.Rider; VAR line: ARRAY OF CHAR);
VAR ch : CHAR;
i : LONGINT;
eol : BOOLEAN;
BEGIN
i := 0;
eol := FALSE;
REPEAT
   Files.Read(r, ch);
   line[i] := ch;
   IF (i > 1) THEN
      IF ((line[i] = 0DX) & (line[i-1]=0AX)) OR ((line[i]=0AX) & (line[i-1]=0DX)) THEN eol := TRUE END;
   END;
   INC(i);
   IF i = LEN(line) THEN 
      Out.String("Warning: array lenght reached"); Out.Ln;
	  Out.String("line = "); Out.String(line); Out.Ln;
   END;
UNTIL eol OR r.eof;
line[i-1] := 0X;
line [i] := 0X;
END ReadLine;

PROCEDURE WriteLine(VAR outrider: Files.Rider; line : ARRAY OF CHAR);
VAR i : INTEGER;
BEGIN
   i := 0;
   REPEAT
      
	  IF line[i] = 0AX THEN
         Files.WriteByte(outrider, 05CX); (* \n *)
		 Files.WriteByte(outrider, 06EX);
	  ELSIF line[i] = 0X THEN
	     (* do nothing *)
      ELSE
         Files.WriteByte(outrider, S.VAL(S.BYTE, line[i]))
      END;
	  INC(i);
   UNTIL (line[i] = 0X) OR (i=LEN(line));
END WriteLine;
*)

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

PROCEDURE readTill(VAR r, ro : Files.Rider; ch : CHAR);
VAR s : CHAR;
BEGIN
   REPEAT 
      (*Files.Read(r, s);*)
	  ReadChar(r, s);
      IF s >= 20X THEN
         IF s # ch THEN WriteChar(ro, s) END
      END
   UNTIL (ch = s) OR r.eof;
END readTill;

PROCEDURE readTillLatin(VAR r : Files.Rider; f : Files.File);
VAR 
  s : CHAR;
  i : LONGINT;
BEGIN
   REPEAT 
      (*Files.Read(r, s);*)
	  ReadChar(r, s);
      (*IF s >= 20X THEN
         IF s # ch THEN Out.Char(s) END
      END*)
	  i := ORD(s)
   UNTIL  (i >= 65) & (i <= 122) OR r.eof;
   IF ~r.eof THEN
     i := Files.Pos(r);
     IF i > 0 THEN
       Files.Set(r, f, i-1)
     END
   END
END readTillLatin;

PROCEDURE readTill0(VAR r, ro : Files.Rider; ch : CHAR; VAR eol : BOOLEAN);
VAR s : CHAR;
BEGIN
   REPEAT 
      (*Files.Read(r, s);*)
	  ReadChar(r, s);
      IF s # ch THEN WriteChar(ro, s) END;
      IF s = 0AX THEN
         (*Files.Read(r, s);*)
		 ReadChar(r, s);
	 IF (ORD(s) < 128) & (s # '(') THEN 
	    WriteChar(ro, 0AX); WriteChar(ro, s); eol := TRUE;
	 ELSE
            WriteChar(ro, ' '); WriteChar(ro, s); readTill0(r, ro, ch, eol);
	 END
      END
   UNTIL eol OR r.eof(*(ch = s) OR r.eof*);
END readTill0;


PROCEDURE readTillNot(VAR r, ro : Files.Rider; ch : CHAR);
VAR s : CHAR;
BEGIN
   REPEAT 
      (*Files.Read(r, s)*)
	  ReadChar(r, s)
   UNTIL (ch # s) OR r.eof;
      WriteChar(ro, s)
END readTillNot;

PROCEDURE readTillTranscription(VAR r, ro : Files.Rider);
VAR
  ch : CHAR;
BEGIN
  REPEAT
    (*Files.Read(r, ch);*)
	ReadChar(r, ch);
  UNTIL (ch = '[') OR r.eof;
  WriteChar(ro, ch);
END readTillTranscription;

PROCEDURE readTillTranscriptionIsOver(VAR r : Files.Rider);
VAR
  ch : CHAR;
BEGIN
  REPEAT
    Files.Read(r, ch);
	(*ReadChar(r, ch);*)
  UNTIL (ch = ']') OR r.eof;
END readTillTranscriptionIsOver;

PROCEDURE readEnglishWord(VAR r, ro : Files.Rider; VAR f : Files.File);
VAR
  ord : INTEGER;
  ch  : CHAR;
  spaceCount: INTEGER;
  enough : BOOLEAN;
  i : LONGINT;
  (*tmp : str; ind : LONGINT;*)
BEGIN
  spaceCount := 0;
  enough := FALSE;
  (*ind := 0;*)
  REPEAT
    (*Files.Read(r, ch);*)
	ReadChar(r, ch);
    ord := ORD(ch);
    IF ord = 32 THEN 
	  WriteChar(ro, ' '); 
	  (*tmp[ind] := ' '; INC(ind);*)
	  INC(spaceCount);
	  IF spaceCount = 2 THEN enough := TRUE END  
	(*ELSIF ord = 10 THEN ind := 0*)
	ELSIF (ord # 91) & ((ord = 44) OR ((ord >=65) & (ord <= 122))) THEN
      WriteChar(ro, ch); (*tmp[ind] := ch; INC(ind);*)
	ELSIF (ch = 0AX) THEN enough := TRUE 
	ELSIF (ch = '[') THEN
	   i := Files.Pos(r);
	   Files.Set(r, f, i-1);
	   enough := TRUE
	END;

  UNTIL enough OR r.eof;
  (*tmp[ind] := 0X;
  WriteStaticString(ro, tmp);*)
END readEnglishWord;

PROCEDURE isInArmsciiRange(VAR ch : CHAR) : BOOLEAN;
BEGIN
IF (ORD(ch) >= 162) & (ORD(ch) <= 254) THEN RETURN TRUE ELSE RETURN FALSE END
END isInArmsciiRange;

PROCEDURE Go;
   VAR f, fo : Files.File;
       r, ro : Files.Rider;
       ch : CHAR;
       ord, i: INTEGER;
	   nextWord: BOOLEAN;
	   str : ArmsciiUTF.string;
	   l: LONGINT;
BEGIN
   f := Files.Old(inputFile);
   IF f # NIL THEN
      Files.Set(r, f, 0);

      fo := Files.New(outputFile);
      IF fo # NIL THEN
         Files.Set(ro, fo, 0);
		 l := 0;
         WHILE ~r.eof DO
           (*REPEAT
             Files.Read(r, ch);
		   UNTIL r.eof;
            *)
              (* expecting English word *)
              readTillLatin(r, f);
			  readEnglishWord(r, ro, f);
			  WriteChar(ro, 9X); (* write tab *)
			  readTillTranscription(r, ro);
			  (*readTillTranscriptionIsOver(r);*)
			  WriteStaticString(ro, trans[l]);
			  INC(l);
			  (* reading description *)
			  nextWord := FALSE;
			  REPEAT
                (*Files.Read(r, ch);*)
				ReadChar(r, ch);
				IF isInArmsciiRange(ch) THEN
				  str := ArmsciiUTF.A2U(ch);
				  WriteString(ro, str)
				ELSIF ORD(ch) = 10 THEN
                  WriteChar(ro, ' ');
				ELSIF  (ch # 03AX) & ((ORD(ch) >= 32) OR (ORD(ch) <= 126)) THEN
				  WriteChar(ro, ch);
                ELSIF (ch = 03AX) THEN
				   str := ArmsciiUTF.A2U(023X);
				   WriteString(ro, str);
				   (*Files.Read(r, ch);*)
				   ReadChar(r, ch);
				   IF ch = 0AX THEN WriteChar(ro, 0AX); nextWord := TRUE END
                ELSIF ch = 00X THEN
				   Out.Ln;
				ELSE IF ORD(ch) > 32 THEN WriteChar(ro, ch) END
				END
			  UNTIL nextWord OR r.eof;
         END; (* while *)

		 WriteChar(ro, 0AX);
		 WriteChar(ro, 0AX);
		 Files.Register(fo);
		 Files.Close(fo);
	  ELSE
         Out.String(outputFile); Out.String(" cannot be created, check permissions"); Out.Ln
      END
   ELSE
         Out.String(inputFile); Out.String (" not found in current directory"); Out.Ln
   END
END Go;

PROCEDURE ExtractTranscriptions;
VAR
  f : Files.File;
  r : Files.Rider;
  ch : CHAR;
  i, j : LONGINT;
  tmp : str;
BEGIN
  f := Files.Old(transIn);
  Files.Set(r, f, 0);
  i := 0;
  REPEAT
    Files.Read(r, ch);
	IF ch = '[' THEN
      j := 0;
	  REPEAT
	    (*Out.Char(ch);*)
	    IF i = 6521 THEN Out.Char('!'); END;
        tmp[j] := ch;
		Files.Read(r, ch);
		INC(j);
	  UNTIL ch = ']';
	  tmp[j] := ch;
	  INC(j);
	  tmp[j] := 0X;
	  COPY(tmp, trans[i]);
	  INC(i);
	  (*Out.Int(i, 0); Out.Char (' '); Out.String(trans[i]); Out.Ln;*)
	END;
  UNTIL (i = wordsCount - 1) OR r.eof;
  Files.Close(f);
END ExtractTranscriptions;

PROCEDURE Fix;
VAR
  f : Files.File;
  r : Files.Rider;
BEGIN
  f := Files.Old(transIn);
  Files.Set(r, f, 1090505);
  Files.WriteByte(r, 93); (* absent ']' at the end of the transcription of the word "desertion" *)
  Files.Register(f);
  Files.Close(f);
END Fix;

BEGIN
  Fix;
  (*ExtractTranscriptions;*)
  Go;

END convert.
