SHELL := /bin/bash
VOC = /opt/voc/bin/voc
LOC = http://www.armin.am/images/menus/1720
SRC = Angleren_bararan.pdf
NAME = baratian
SRC = Angleren_bararan.txt
DST0 = $(NAME).txt
DST = $(NAME).tab
AGENT = 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4'

all: fix converter maketab fix2 makedict

almost_all: fix maketab fix2 makedict


# if we don't use -U option to spoof the site then it does not return the file but returns 403 forbidden error.
# not in this case. but will not harm. (:
get:
	#wget  -U $(AGENT)  -c $(LOC)/$(SRC)

totext:
	#list encodings with pdftotext -listenc
	#pdftotext -layout $(SRC) $(DST0)
	pdftotext -enc UCS-2 $(SRC) $(DST0)
	pdftotext -enc UTF-8 $(SRC) $(DST1)

converter:
	$(VOC) -s s.Mod ArmsciiUTF.Mod converter.Mod -m
	#$(VOC) -s s.Mod ArmsciiUTF.Mod conv.Mod -m

fix:
	cp $(SRC) $(DST0)
	#remove first 297 lines
	sed -i -e 1,297d $(DST0)
	#remove last 125 lines
	sed -i -n -e :a -e '1,128!{P;N;D;};N;ba' $(DST0)
	#fix ability word
	sed -i 's/abilitl\/y/ability/g' $(DST0)
	#fix tran sposition word
	sed -i 's/tran sposition/transposition/g' $(DST0)
	#replace ':', ' ', with ':'
	sed -i 's/: /:/g' $(DST0)
maketab:
	./converter

fix2:
	#replace ' ֊ ' with nothing
	sed -i 's/ ֊ //g' $(DST)
	#replace 'μ' with 'բ'
	sed -i 's/μ/բ/g' $(DST)
	#replace '—' with 'և'
	sed -i 's/—/և/g' $(DST)

makedict:
	stardict_tabfile $(DST)
	mkdir -p $(NAME)
	mv $(NAME).dict $(NAME).idx $(NAME).ifo $(NAME) 

clean:
	rm *.o
	rm *.c
	rm *.h
	#rm $(DST0)
	rm .tmp*
	rm fixer
	rm conv
