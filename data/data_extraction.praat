form Data extracton parameters
 # sound, word, production type (token), speaker - interval tiers
 # pulse - point tier
 comment Number of the sound tier
 integer sndTier 1
 comment Number of the word tier
 integer wrdTier 2
 comment Number of the production type tier
 integer tknTier 3
 comment Number of the speaker tier
 integer spkTier 6
 comment Number of the pulse tier
 integer plsTier 7
 comment Path to formant extraction data
 text formantFile _ Formant_Extraction_Parameters.txt
 comment Path to save spectrograms
 text path C:\Users\...
endform

soundInitial = selected ("Sound")
txtGrid = selected ("TextGrid")

Edit

# ---- delete the initial word "Sound " from the file name
select soundInitial
outFileP$ = selected$ ()
len = length: outFileP$
outFileP$ = right$: outFileP$, len - 6

# ---- make output file names
outFileI$ = outFileP$ + "_Intensity.txt" ; intensities between pulses
outFileIN$ = outFileP$ + "_Intensity_Norm.txt" ; normalized intensities between pulses
outFileP$ = outFileP$ + "_Pulses and Formants.txt" ; pulse timings
						   ; formants correspond to target sounds
						   ; f1hz f1db f2hz f2db f3hz f3db
# ---- resample the sound

select soundInitial
Resample... 16000 50
sound = selected("Sound")

# ---- get editor name

select txtGrid
txtGridName$ = selected$ ()
editorName$ = string$(txtGrid)
editorName$ = editorName$ + ". " + txtGridName$

# ---- scaling parameters

pctRightBase = 10 ; base width of a spectrogram in Praat picture
pctRightScale = 0.5 ; base duration of a word for scaling, seconds
pctRight = 0

# ---- variables

nWord = 1 ; word counter
j = 1 ; counter for pulses
fCounter = 0 ; counter for formants
currPulse = 0 ; current pulse time
prevPulse = 0 ; previous pulse time

currWrd$ = "" ; current word which is combined letter by letter as the
#		script runs through the sound layer

currWrdOut$ = "" ; current word for the output file

# ---- get formant extraction parameters

str = Read Strings from raw text file... 'formantFile$'

selectObject (str)
strNum = Get number of strings

fParams$ [1] = "" ; array of formant extraction parameters

if strNum > 1
 for i to strNum
  fParams$ [i] = Get string: i
 endfor
endif

removeObject: str

# ---- create intensity object 

selectObject: sound
intensity = To Intensity... 100 0

# ---- create pitch object

selectObject: sound
pitch = To Pitch... 0.01 75 600

# ---- extract pulses

selectObject: txtGrid
npulses = Get number of points... plsTier

pulses# = zero# (npulses)

for i to npulses
 pulses# [i] = Get time of point: plsTier, i
endfor

nIntervals = Get number of intervals: sndTier ; number of intervals in the sounds tier

# ---- make headers

writeFileLine: outFileP$, "speaker", tab$, "word", tab$, "prodType", tab$, "V1start", tab$, "Cstart", tab$, "V2start", tab$, "V2end", tab$,
                   ..."f0hz", tab$, "f0db", tab$, "h2hz", tab$, "h2db", tab$, "f1hz", tab$, "f1db", tab$,
                   ..."f2hz", tab$, "f2db", tab$, "f3hz", tab$, "f3db", tab$, "snd", "pulseTime", tab$, "snd", tab$, "pulseTime", tab$
writeFileLine: outFileI$, "speaker", tab$, "word", tab$, "prodType", tab$, "V1start", tab$, "Cstart", tab$, "V2start", tab$, "V2end", tab$,
                  ... "V1int", tab$, "Cint", tab$, "V2int", tab$, "CV2int", tab$,
                  ... "CintNorm", tab$, "V2intNorm", tab$, "CV2intNorm", tab$, "snd", tab$, "intBetweenPulses", tab$, "snd", tab$, "intBetweenPulses", tab$
writeFileLine: outFileIN$, "speaker", tab$, "word", tab$, "prodType", tab$, "V1start", tab$, "Cstart", tab$, "V2start", tab$, "V2end", tab$

# ---- the main algorythm

writeInfoLine: ""

for i from 2 to (nIntervals - 1)

 # -- find sounds in the sound tier
 selectObject: txtGrid

 snd1$ = Get label of interval: sndTier, i - 1 ; previous sound
 snd2$ = Get label of interval: sndTier, i
 snd3$ = Get label of interval: sndTier, i + 1 ; next sound

 # limits of the previous sound
 snd1Lft = Get start point: sndTier, i - 1 ; the left point of the interval
 snd1Rght = Get end point: sndTier, i - 1 ; the right point of the interval

 # limits of the current sound
 snd2Lft = Get start point: sndTier, i
 snd2Rght = Get end point: sndTier, i

 # limits of the next sound
 snd3Lft = Get start point: sndTier, i + 1
 snd3Rght = Get end point: sndTier, i + 1
	
 # -- check that the sounds are in the same word
 wLft = Get interval at time: wrdTier, (snd1Lft + snd2Lft) / 2
 wLft$ = Get label of interval: wrdTier, wLft
 wRght = Get interval at time: wrdTier, (snd3Lft + snd3Rght) / 2
 wRght$ = Get label of interval: wrdTier, wRght

 # -- build the word in order to make leftpart_VlateralV_rightpart key	
 if wLft$ <> wRght$
  currWrd$ = ""
 else
   currWrd$ = currWrd$ + snd1$
 endif

 if snd2$ = "l'"
  snd2$ = "lˀ"
 endif
  if snd2$ = "ll'"
   snd2$ = "llˀ"
  endif

 # -- check whether the lateral is between 2 sounds and that they all are within one word
 # -- then extract all the necessary data

  # this is because we need to have one vowel at each side of the lateral
  if (snd2$ = "l" or snd2$ = "lˀ") and snd1$ <> "" and snd3$ <> "" and wLft$ = wRght$ and
  ...((length (snd1$) = 1 and length (snd3$) = 1) or 
  ...(left$(snd3$,1) = "^" and length (snd1$) = 1) or
  ...(left$(snd1$,1) = "^" and length (snd3$) = 1))

  # make output file name
  currWrdOut$ = left$ (currWrd$, length (currWrd$) - length(snd1$)) ; length is reduced, because there is already the left vowel in currWrd$
  currWrdOut$ = currWrdOut$ + "_" + snd1$ + snd2$ + snd3$ + "_"
  z = i + 2
  tmpsnd$ = Get label of interval: sndTier, z
  tmpsndLft = Get start point: sndTier, z ; the left point of the interval
  tmpsndRght = Get end point: sndTier, z ; the right point of the interval
  tmpwrd = Get interval at time: wrdTier, (tmpsndLft + tmpsndRght) / 2
  tmpwrd$ = Get label of interval: wrdTier, tmpwrd
  #appendInfoLine: "i = ", fixed$(i, 0), " z = ", fixed$(z, 0), " tmpsnd ", tmpsnd$, " tmpwrd ", tmpwrd$
  while tmpwrd$ = wLft$ and z <= nIntervals
   currWrdOut$ = currWrdOut$ + tmpsnd$
   z = z + 1
   tmpsnd$ = Get label of interval: sndTier, z
   tmpsndLft = Get start point: sndTier, z ; the left point of the interval
   tmpsndRght = Get end point: sndTier, z ; the right point of the interval
   tmpwrd = Get interval at time: wrdTier, (tmpsndLft + tmpsndRght) / 2
   tmpwrd$ = Get label of interval: wrdTier, tmpwrd
   #appendInfoLine: "i = ", tab$, fixed$ (i, 0), "z = ", tab$, fixed$(z, 0), tab$, "tmpsnd", tab$, tmpsnd$, tab$,
               ... "tmpwrd", tab$, tmpwrd$, tab$, "currWrdOut", tab$, currWrdOut$, tab$, "currWrd", tab$, currWrd$
  endwhile

  # borders of the target word
  wLftBorder = Get start point: wrdTier, wLft
  wRghtBorder = Get end point: wrdTier, wLft

  currPulse = pulses# [1]

  # skip all the pulses outside the desired sound
  j = 1		
  while j <= npulses - 1 and currPulse < snd1Lft
   j = j + 1
   currPulse = pulses# [j]
  endwhile

  # we are in the first pulse of a desired VCV segment		
  prevPulse = currPulse
  j = j + 1
  currPulse = pulses# [j]

  # file structure: word, token, start of sound 1, start of sound 2,
  # start of sound 3, end of sound 3, sound, pulse, sound, pulse...
  # get the production type (token) data

  tkn = Get interval at time: tknTier, prevPulse
  tkn$ = Get label of interval: tknTier, tkn
  spk = Get interval at time: spkTier, prevPulse
  spk$ = Get label of interval: spkTier, spk

  # write general data
  appendFile: outFileP$, spk$, tab$, currWrdOut$, tab$, tkn$, tab$, fixed$ (snd1Lft, 4), tab$, fixed$ (snd2Lft, 4), tab$, fixed$ (snd3Lft, 4), tab$, fixed$ (snd3Rght, 4), tab$
  appendFile: outFileI$, spk$, tab$, currWrdOut$, tab$, tkn$, tab$, fixed$ (snd1Lft, 4), tab$, fixed$ (snd2Lft, 4), tab$, fixed$ (snd3Lft, 4), tab$, fixed$ (snd3Rght, 4), tab$
  appendFile: outFileIN$, spk$, tab$, currWrdOut$, tab$, tkn$, tab$, fixed$ (snd1Lft, 4), tab$, fixed$ (snd2Lft, 4), tab$, fixed$ (snd3Lft, 4), tab$, fixed$ (snd3Rght, 4), tab$

  # extract and write mean intensities of each sound
  selectObject: intensity
  snd1Int = Get mean... snd1Lft snd2Lft dB
  appendFile: outFileI$, fixed$ (snd1Int, 4), tab$
  snd2Int = Get mean... snd2Lft snd3Lft dB
  appendFile: outFileI$, fixed$ (snd2Int, 4), tab$
  snd3Int = Get mean... snd3Lft snd3Rght dB
  appendFile: outFileI$, fixed$ (snd3Int, 4), tab$
  snd2snd3Int = Get mean... snd2Lft snd3Rght dB
  appendFile: outFileI$, fixed$ (snd2snd3Int, 4), tab$
  
  # extract and write normalized intensities
  editor: editorName$
   Select: snd2Lft - 0.02, snd3Rght + 0.02
   Zoom to selection
   Extract selected sound (preserve times)
  endeditor

  tmpSound = selected ("Sound")

  appendInfoLine: "snd2Int = ",fixed$(snd2Int, 2), " snd3Int = ", fixed$(snd3Int, 2), " snd2snd3Int = ", fixed$(snd2snd3Int, 2)

  snd3IntNorm = 70
  snd2IntNorm = snd2Int + (snd3IntNorm - snd3Int)
  snd2snd3IntNorm = snd2snd3Int + (snd3IntNorm - snd3Int)


  loopFlag = 1

  while loopFlag = 1
   appendInfoLine: "snd2IntTarget = ",fixed$(snd2IntNorm, 2), " snd3IntTarget = ", fixed$(snd3IntNorm, 2), " snd2snd3IntTarget = ", fixed$(snd2snd3IntNorm, 2)
   selectObject: tmpSound
   Scale intensity... snd2snd3IntNorm
   tmpIntensity = To Intensity... 100 0

   snd2IntNorm = Get mean... snd2Lft snd3Lft dB
   snd3IntNorm = Get mean... snd3Lft snd3Rght dB
   if snd3IntNorm < 69.5
    snd2snd3IntNorm = snd2snd3IntNorm + 1
   endif
   if snd3IntNorm > 70.5
    snd2snd3IntNorm = snd2snd3IntNorm - 1
   endif
   if snd3IntNorm >= 69.5 and snd3IntNorm <= 70.5
    loopFlag = 0
   endif
   appendInfoLine: "snd2IntResult = ",fixed$(snd2IntNorm, 2), " snd3IntResult = ", fixed$(snd3IntNorm, 2), " snd2snd3IntResult = ", fixed$(snd2snd3IntNorm, 2)
   removeObject: tmpIntensity
  endwhile

  appendFile: outFileI$, fixed$ (snd2IntNorm, 4), tab$
  appendFile: outFileI$, fixed$ (snd3IntNorm, 4), tab$
  appendFile: outFileI$, fixed$ (snd2snd3IntNorm, 4), tab$


  removeObject: tmpSound
  
  # extract formant data

  if fParams$ [nWord] <> "-"

   # structure of parameters: place within the l/l' sound (0.5 = middle), f1 band leftmost point,
   # f1 band rightmost point, f2 left, f2 right, f3 left, f3 right

   @split (" ", fParams$ [nWord])

   sndPlace = number (split.array$[1])
   f1Lfthz = number (split.array$[2])
   f1Rghthz = number (split.array$[3])
   f2Lfthz = number (split.array$[4])
   f2Rghthz = number (split.array$[5])
   f3Lfthz = number (split.array$[6])
   f3Rghthz = number (split.array$[7])
  else
   sndPlace = 0.5
  endif

  # estimate f0 frequency. automatic estimation by Praat doesn't always work on creaky sounds
  tLeft = snd2Lft + (snd2Rght - snd2Lft) * sndPlace - 0.01
  tRight = snd2Lft + (snd2Rght - snd2Lft) * sndPlace + 0.01
  z = j ; j is the first pulse within the lateral
  pulseSum = 0
  pulseNum = 0
  #appendInfoLine: currWrdOut$, " j = ", fixed$(j, 0), " tLeft ", fixed$(tLeft, 3), " tRight ", fixed$ (tRight, 3), " pulse[j] = ", fixed$(pulses#[j], 3)
  while pulses#[z] < tRight
   #appendInfoLine: "z = ", fixed$(z, 0), " pulse[z] = ", fixed$(pulses#[z], 3)
   if pulses#[z] > tLeft
    pulseSum = pulseSum + pulses#[z] - pulses#[z - 1]
    pulseNum = pulseNum + 1
   endif
   z = z + 1
  endwhile
  if pulseSum = 0
   f0hz = undefined
  else
   pulseSum = pulseSum + pulses#[z] - pulses#[z - 1]
   pulseNum = pulseNum + 1
   f0hz = 1 / (pulseSum / pulseNum)
  endif

  editor: editorName$
   Select: snd2Lft + (snd2Rght - snd2Lft) * sndPlace - 0.01, snd2Lft + (snd2Rght - snd2Lft) * sndPlace + 0.01 ; extract several pulses
   View spectral slice
  endeditor				

  slice = selected ("Spectrum")
  To Ltas (1-to-1)
  ltas = selected("Ltas")
   
  if fParams$ [nWord] <> "-"

   if f0hz <> undefined
    f0Lfthz = f0hz * 0.9
    f0Rghthz = f0hz * 1.1
    f0db = Get maximum... f0Lfthz f0Rghthz None
    f0hz = Get frequency of maximum... f0Lfthz f0Rghthz None

    h2hz = f0hz * 2
    h2Lefthz = h2hz * 0.9
    h2Rghthz = h2hz * 1.1
    h2db = Get maximum... h2Lefthz h2Rghthz None
   else
    f0db = undefined
    f0hz = undefined
    h2hz = undefined
    h2db = undefined
   endif
   f1db = Get maximum... f1Lfthz f1Rghthz None
   f1hz = Get frequency of maximum... f1Lfthz f1Rghthz None

   f2db = Get maximum... f2Lfthz f2Rghthz None
   f2hz = Get frequency of maximum... f2Lfthz f2Rghthz None

   f3db = Get maximum... f3Lfthz f3Rghthz None
   f3hz = Get frequency of maximum... f3Lfthz f3Rghthz None

   # write formant data
   appendFile: outFileP$, fixed$ (f0hz,0), tab$, fixed$ (f0db,0), tab$,
    ...fixed$ (h2hz,0), tab$, fixed$ (h2db,0), tab$,
    ...fixed$ (f1hz, 0), tab$, fixed$ (f1db, 0), tab$,
    ...fixed$ (f2hz, 0), tab$, fixed$ (f2db, 0), tab$,
    ...fixed$ (f3hz, 0), tab$, fixed$ (f3db, 0), tab$
  else
   appendFile: outFileP$, "-", tab$, "-", tab$,
    ..."-", tab$, "-", tab$,
    ..."-", tab$, "-", tab$,
    ..."-", tab$, "-", tab$,
    ..."-", tab$, "-", tab$
  endif

  # draw the spectral slice:
  selectObject: slice
  Select outer viewport: 0, 4, 0, 3
  Erase all
  Draw: 0, 5000, 0, 0, "yes"
  # add formants

  if fParams$ [nWord] <> "-"
   One mark bottom: f1hz, "no", "yes", "yes", "F1 " + fixed$ (f1hz, 0)
   One mark bottom: f2hz, "no", "yes", "yes", "F2 " + fixed$ (f2hz, 0)
   One mark bottom: f3hz, "no", "yes", "yes", "F3 " + fixed$ (f3hz, 0)
  endif

  # save the slice
  selectObject: txtGrid
  txtGridName$ = selected$ ()
  txtGridName$ = right$ (txtGridName$, length (txtGridName$) - 9)

  x = (snd2Lft + snd3Lft) / 2

  fname$ = path$ + txtGridName$ + ", " + currWrdOut$ + ", " + tkn$ + "_slice" + ".png"
  if fileReadable (fname$)
   z = 2
   fname$ = path$ + txtGridName$ + ", " + currWrdOut$ + "_" + string$(z) + ", " + tkn$ + "_slice" + ".png"
   while fileReadable (fname$)
    z = z + 1
    fname$ = path$ + txtGridName$ + ", " + currWrdOut$ + "_" + string$(z) + ", " + tkn$ + "_slice" + ".png"
   endwhile
   Save as 300-dpi PNG file: fname$
  else
   Save as 300-dpi PNG file: fname$
  endif

  # clear the drawing pane
  Erase all

  # ---- extract the sound and textgrid

  # extract the sound and textgrid

  editor: editorName$
   Select: wLftBorder, wRghtBorder
   Zoom to selection
   Extract selected sound (time from 0)
  endeditor
  
  tmpSound = selected ("Sound")

  editor: editorName$
   Extract selected TextGrid (time from 0)
  endeditor

  tmpTxtGrid = selected ("TextGrid")
  
  select tmpTxtGrid
  tmpTxtGridName$ = selected$ ()
  tmpEditorName$ = string$(tmpTxtGrid)
  tmpEditorName$ = tmpEditorName$ + ". " + tmpTxtGridName$

  # edit the textgrid. delete extra pulses

  nPulses = Get number of points: plsTier

  z = 1
  while z <= nPulses
   t = Get time of point: plsTier, z
   if (t < snd1Lft - wLftBorder) or (t > snd3Rght - wLftBorder)
    Remove point: plsTier, z
    nPulses = Get number of points: plsTier
    else
    z = z + 1
   endif
  endwhile

  # remove the data that is not required
  numberOfTiers = Get number of tiers
  if numberOfTiers = 8
    Remove tier... 8
  endif
  Remove tier... 5
  Remove tier... 4

  # ---- draw the spectrogram ----

  # scaling
  pctRight = pctRightBase * (wRghtBorder - wLftBorder) / pctRightScale
  Select outer viewport: 0, pctRight, 0, 4

  # draw the spectrogram
  select tmpSound
  plus tmpTxtGrid

  Edit

  x = snd2Lft + (snd2Rght - snd2Lft) * sndPlace - wLftBorder

  editor: tmpEditorName$
   Select: 0, wRghtBorder - wLftBorder
   # parameters: erase first, write name, draw selection times
   # draw selection hairs, garnish
   Paint visible spectrogram: "yes", "no", "yes", "yes", "yes"
  endeditor

  if fParams$ [nWord] <> "-"
   if f0hz <> undefined   
    One mark left: f0hz, "yes", "yes", "yes", ""
   endif
   One mark left: f1hz, "yes", "yes", "yes", ""
   One mark left: f2hz, "yes", "yes", "yes", ""
   One mark left: f3hz, "yes", "yes", "yes", ""
   Paint circle: "red", x, f1hz, 0.002
   Paint circle: "red", x, f2hz, 0.002
   Paint circle: "red", x, f3hz, 0.002
  endif

  Select outer viewport: 0, pctRight, 4, 7
  
  editor: tmpEditorName$
   Draw visible sound and TextGrid: "no", "no", "yes", "yes", "yes"
  endeditor

  # -- save everything

  Select outer viewport: 0, pctRight, 0, 7

  # the spectrogram
  fname$ = left$ (fname$, length(fname$) - 10) + ".png"
  Save as 300-dpi PNG file: fname$

  # the sound
  fname$ = left$ (fname$, length (fname$) - 4) + ".wav"
  selectObject: tmpSound
  Save as WAV file: fname$

  # the textGrid
  fname$ = left$ (fname$, length (fname$) - 4) + ".TextGrid"
  selectObject: tmpTxtGrid
  Save as short text file: fname$

  # ---- extract data for intensity analysis
  select sound
  plus txtGrid


  editor: editorName$
   Select: snd1Lft, snd3Rght ; in order not to distort intensity
   Zoom to selection
   Extract selected sound (preserve times)
  endeditor
		
  tmpSndI = selected ("Sound")

  select tmpSndI
  Scale intensity... 70
  tmpInt = To Intensity... 100 0

  # ---- add normalized intensities to the output file
  selectObject: tmpInt
  # add mean intensities of each sound
  mean_int = Get mean... snd1Lft snd2Lft dB
  appendFile: outFileIN$, fixed$ (mean_int, 4), tab$
  mean_int = Get mean... snd2Lft snd3Lft dB
  appendFile: outFileIN$, fixed$ (mean_int, 4), tab$
  mean_int = Get mean... snd3Lft snd3Rght dB
  appendFile: outFileIN$, fixed$ (mean_int, 4), tab$

  # ---- add data corresponding to pulses

  # write pulses into the file
  if j <= npulses - 1
   while j <= npulses - 1 and currPulse < snd3Rght

    # first, write the sound
    if prevPulse < snd2Lft
     appendFile: outFileP$, snd1$, tab$
     appendFile: outFileI$, snd1$, tab$
     appendFile: outFileIN$, snd1$, tab$
    else
     if prevPulse < snd3Lft
      appendFile: outFileP$, snd2$, tab$
      appendFile: outFileI$, snd2$, tab$
      appendFile: outFileIN$, snd2$, tab$
     else
      appendFile: outFileP$, snd3$, tab$
      appendFile: outFileI$, snd3$, tab$
      appendFile: outFileIN$, snd3$, tab$
     endif
    endif

    # write intensity
    selectObject: intensity
    mean_int = Get mean... prevPulse currPulse dB
    appendFile: outFileI$, fixed$ (mean_int, 4), tab$

    # write normalized intensity
    selectObject: tmpInt
    mean_int = Get mean... prevPulse currPulse dB
    appendFile: outFileIN$, fixed$ (mean_int, 4), tab$

    # write the last pulse into the output
    appendFile: outFileP$, fixed$ (prevPulse, 4), tab$
    j = j + 1
    prevPulse = currPulse
    currPulse = pulses# [j]
   endwhile
   appendFileLine: outFileI$
   appendFileLine: outFileIN$
			
   # add timing for the last pulse
   appendFileLine: outFileP$, snd3$, tab$, fixed$ (prevPulse, 4)

  endif

  nWord = nWord + 1

  # clear the trash
  removeObject: slice
  removeObject: ltas
  removeObject: tmpSndI
  removeObject: tmpInt
  removeObject: tmpTxtGrid
  removeObject: tmpSound
 endif
endfor

removeObject: intensity
removeObject: pitch
removeObject: sound

selectObject: soundInitial, txtGrid

appendInfoLine: "Done!"

# .sep$ - separator, .str$ the string to be separated
procedure split (.sep$, .str$)
	.strlen = length (.str$)
	.sep = index (.str$, .sep$)
	.seplen = length (.sep$)
	.length = 1
	while .sep > 0
		.part$ = left$ (.str$, .sep - 1)
		.str$ = right$ (.str$, length (.str$) - .sep - .seplen + 1)
		.sep = index (.str$, .sep$)
		.array$ [.length] = .part$
		.length = .length + 1
	endwhile
	.array$ [.length] = .str$
endproc
