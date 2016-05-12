SHELL := /bin/bash
VOC = /opt/voc/bin/voc
LOC = http://www.armin.am/images/menus/1720
SRC = Angleren_bararan.pdf
NAME = baratian
DST0 = $(NAME).txt
DST1 = $(NAME)-utf8.txt
DST0f = $(NAME)_fixed.txt
DST1f = $(NAME)-utf8_fixed.txt
DST = $(NAME).tab
AGENT = 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4'

all: get totext fix fixer fix2 converter maketab makedict

almost_all: get totext fix fix2 maketab makedict


# if we don't use -U option to spoof the site then it does not return the file but returns 403 forbidden error.
# not in this case. but will not harm. (:
get:
	wget  -U $(AGENT)  -c $(LOC)/$(SRC)

totext:
	#list encodings with pdftotext -listenc
	#pdftotext -layout $(SRC) $(DST0)
	pdftotext -enc UCS-2 $(SRC) $(DST0)
	pdftotext -enc UTF-8 $(SRC) $(DST1)

converter:
	#$(VOC) -s ArmsciiUTF.Mod convert.Mod -m
	$(VOC) -s s.Mod ArmsciiUTF.Mod conv.Mod -m

fixer:
	$(VOC) fixer.Mod -m

fix2:
	./fixer
	#everything is fixed by the fixer. no need in further lines.
	#no ':' at the end of the 'abrade' (line 205, 21) word description
	#also found absorbedly like that.
	#does not work on non utf-8 file for unknown to me reason.
	#sed -i '205s/^\(.\{21\}\)/\1:/' $(DST0f)
	#sed -i '205s/^\(.\{21\}\)/\1:/' $(DST1f)
	#remove empty lines
	#sed -i '/^$$/d' $(DST0f)
	#sed -i '/^$$/d' $(DST1f)
	#change 0A [ sequence to ' ['
	#sed -i 's/o12[/ [/g' $(DST0f)
fix:
	#remove first 376 lines
	sed -i -e 1,376d $(DST0)
	sed -i -e 1,376d $(DST1)
	#remove lines that start with page break (looks like ^L)
	#sed -i '/\o14/ d' $(DST0)
	#sed -i '/\o14/ d' $(DST1)
	#remove last 430 lines
	sed -i -n -e :a -e '1,430!{P;N;D;};N;ba' $(DST0)
	sed -i -n -e :a -e '1,430!{P;N;D;};N;ba' $(DST1)
	#remove all null characters
	sed -i 's/\x0//g' $(DST0)
	sed -i 's/\x0//g' $(DST1)
	#fix absent ':' at the end (21th position) of the 216th line
	#sed -i '216s/^\(.\{21\}\)/\1:/' $(DST0)
	#sed -i '216s/^\(.\{21\}\)/\1:/' $(DST1)
	#remove lines after double 0A
	#those are lines with page number and header.
	#dollar sign has to be doubled otherwise make interprets it as variable
	#sed -i '/^$/{N;P;d}' $(DST0)
	#sed -i '/^$$/{N;P;d}' $(DST0)
	###sed -i '/^$/d' $(DST1) #remove empty lines
	#dollar sign has to be doubled otherwise make interprets it as variable
	#sed -i '/^$$/d' $(DST1) #remove empty lines
	#sed -i '/^ /d' $(DST1) #lines starting from ' '
	#remove first line
	#sed -i '1d' $(DST1)
	#printf "$$(printf '\\x%02X' 44)" | dd of="$(DST1)" bs=1 seek=583155 count=1 conv=notrunc &> /dev/null #replace 0A with "," in USA line

maketab:
	./conv

makedict:
	stardict_tabfile $(DST)
	mkdir -p $(NAME)
	mv $(NAME).dict $(NAME).idx $(NAME).ifo $(NAME) 

clean:
	rm *.o
	rm *.c
	rm *.h
	#rm $(DST0)
	#rm $(DST1)
	rm .tmp*
	rm fixer
	rm conv
