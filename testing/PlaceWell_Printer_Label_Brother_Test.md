# PlaceWell Printer & Label Media Qualification Record

**Project:** PlaceWell\
**Purpose:** Preserve the complete printer-selection research, Brother
HL-L8430CDW testing history, SheetLabels media findings, print-path
experiments, failure modes, and next-step decisions from this working
session.\
**Status:** Working qualification record --- September 2026\
**Primary production requirement:** Reliable full-color printing of
PlaceWell QR label sheets with sharp/scannable QR codes, accurate
registration, minimal/no curl, no scuffing or toner transfer, no
jams/sticking, and a repeatable multi-sheet workflow.

------------------------------------------------------------------------

## 1. Executive Summary

PlaceWell uses physical QR labels that must be printed accurately and
reliably on weatherproof synthetic label stock. The primary launch
material selected for PlaceWell is SheetLabels **XW White Polyester
Weatherproof**, a laser-compatible PET/polyester material.

The Brother **HL-L8430CDW** was purchased directly from Brother and
extensively tested with the PlaceWell label PDFs and SheetLabels media.
The printer can produce sharp, scannable QR codes and toner can bond
successfully to the media, but no tested **full-color production
configuration** has yet simultaneously demonstrated all of the required
characteristics:

-   no meaningful scuff marks,
-   no significant curl,
-   no sheet sticking/jamming,
-   stable synthetic material,
-   accurate die-cut registration,
-   reliable repeated feeding,
-   and full-color output.

Several configurations came close, especially **MP Tray + Label + top
output** on the original XW/RGB-black PDF, where scuffs became
negligible. However, a fully clean and repeatable production workflow
has not yet been established.

A separate test with **SheetLabels SL125-XL Weatherproof Vinyl**
eliminated scuffing on two consecutive sheets, but both sheets curled
and the vinyl face material significantly warped/lifted away from the
backing at the top edge. Therefore XL cannot currently be considered a
solution either.

Research into alternative printers identified the Xerox C320 as a
plausible lower-cost candidate because its standard tray supports labels
and media up to 216 GSM, but Xerox documentation does not explicitly
state PET/polyester label support. Lexmark enterprise models such as the
CS820 have stronger documentation explicitly mentioning **polyester
labels**, including a label-specific weight allowance that covers 182
GSM, but they are substantially more expensive and oversized for
PlaceWell's launch needs.

**Current conclusion:** The Brother has not passed production
qualification, but testing uncovered enough promising behavior that it
was reasonable not to return it immediately. The remaining decision
should be based on controlled repeatability tests rather than isolated
good sheets.

------------------------------------------------------------------------

# 2. PlaceWell Physical Label Requirements

## 2.1 Current PlaceWell label SKUs

The current physical PlaceWell label formats are:

  PlaceWell format       SheetLabels SKU               Size   Labels per sheet
  ---------------------- ----------------- ---------------- ------------------
  Round                  SL125-XW                1.5" round                 30
  Rectangle / portrait   SL1184-XW           1.25" × 2.125"                 20
  Square                 SL1189-XW            1.75" × 1.75"                 20

All are based on **8.5" × 11" sheets**.

## 2.2 Locked launch material

The launch material is:

**SheetLabels XW --- White Polyester Weatherproof**

Important terminology:

-   **PET** means *polyethylene terephthalate*.
-   PET is a type of **polyester**.
-   **XW** is SheetLabels' material/SKU abbreviation for its White
    Polyester Weatherproof material. It is not a generic
    printer-industry term.
-   The material is not vinyl.
-   PlaceWell customer-facing wording should be **weatherproof
    polyester, dishwasher-safe**.

Relevant XW construction information used during printer research:

-   matte white laser PET face,
-   approximately 2.5 mil face,
-   approximately 3.5 mil liner,
-   approximately **182 GSM total construction**,
-   permanent adhesive,
-   laser-printer compatible,
-   synthetic/weatherproof material.

This 182 GSM total construction became a major printer-selection
criterion.

------------------------------------------------------------------------

# 3. What PlaceWell Needs From a Production Printer

A printer should not be approved merely because one label sheet prints.

A production-pass configuration must provide:

1.  **Full-color output**
2.  **Sharp QR codes**
3.  **Reliable QR scanning**
4.  **Accurate die-cut registration**
5.  **No toner smearing after cooling**
6.  **No meaningful scuff/offset marks**
7.  **No significant curl**
8.  **No material warping or delamination**
9.  **No jams or end-of-path sticking**
10. **Reliable consecutive-sheet feeding**
11. **Usable unattended output**
12. A paper path/media specification reasonably compatible with the
    selected stock.

The intended validation sequence, once a promising configuration is
found, is:

-   1 sheet
-   3 consecutive sheets
-   10 consecutive sheets
-   all three PlaceWell XW SKUs
-   QR scan verification
-   registration verification
-   later, a larger XW sheet for future tote/box labels.

------------------------------------------------------------------------

# 4. Brother HL-L8430CDW

## 4.1 Purchase

The Brother HL-L8430CDW was purchased **directly from Brother's
website**.

This matters for returns: it should not be treated as a Staples, Best
Buy, or Office Depot purchase.

## 4.2 Relevant Brother specifications discovered

Important findings during research:

-   color laser printer,
-   approximately 33 ppm,
-   250-sheet main tray,
-   50-sheet MP tray nominal capacity for ordinary paper,
-   Brother explicitly directs label media through the **MP tray**,
-   Brother's published MP-tray media-weight range is approximately
    **60--163 GSM**,
-   the PlaceWell XW sheet is approximately **182 GSM**.

Therefore the XW construction is about **19 GSM above the published
Brother MP-tray range**.

Brother's documented label workflow also calls for the rear face-up
output to be opened. The rear face-up output is effectively a one-sheet
workflow for labels; Brother instructs users to remove printed label
sheets immediately.

This was a significant concern for PlaceWell because the desired
workflow is repeated/unattended label-sheet production.

------------------------------------------------------------------------

# 5. Baseline Brother Printing Setup

The initial working print setup used:

-   MP Tray
-   Letter
-   Media Type = Label
-   rear face-up output open
-   duplex off
-   Fine / 2400-class quality
-   Toner Save off
-   Brother scaling off
-   PDF/browser print at **Actual Size / 100%**
-   Pages per sheet = 1
-   Color output.

Printing by opening the PDF and using **Ctrl+P** gave the best die-cut
alignment during earlier testing. Printing through Brother-specific
software was not the preferred workflow.

------------------------------------------------------------------------

# 6. Early XW Results on Brother

## 6.1 MP Tray + Label + rear output

The initial XW output showed:

-   severe sheet curl,
-   sheet warm after printing,
-   faint scuff/smudge marks in blank areas,
-   visible toner transfer/scuffing around dense printed regions,
-   QR codes remained printable,
-   toner itself did **not** continue smearing after the sheet cooled.

One observed example had faint marks in the blank area between labels
such as Dill and Fennel.

A manually supported/caught sheet appeared cleaner, suggesting output
handling/contact could be contributing to the marks. However, manually
catching each sheet is not an acceptable production workflow.

### Initial interpretation

The main failure was not simply "toner will not stick to polyester."

Instead, the observed problems included:

-   physical curl,
-   hot-sheet handling,
-   contact/scuff transfer,
-   and unsuitable production output behavior.

------------------------------------------------------------------------

# 7. Brother "Improve Print Output" Experiments

Brother driver options were tested to try to address curl and toner
behavior.

## 7.1 Improve Toner Fixing

Result:

-   prolonged mechanical cycling,
-   eventually produced **Cannot Print 39**.

This mode was not useful for the XW workflow.

## 7.2 Reduce Paper Curl

Result:

-   similar prolonged behavior,
-   also associated with **Cannot Print 39** during testing,
-   on later attempts it could print, but did not meaningfully solve the
    curl.

## 7.3 Plain Paper through MP tray

Result:

-   sheet printed,
-   toner bonded after cooling,
-   severe curl remained.

## 7.4 Plain Paper + Reduce Curl

Result:

-   curl still severe,
-   scuffing became especially bad --- described during testing as the
    **worst scuff marks so far**.

## 7.5 Ordinary-paper sanity check

After restart, normal ordinary paper printed correctly.

Firmware was also checked and was current at the time:

-   Main: 1.15
-   Sub1: 1.07

### Conclusion from these tests

The printer was not generally broken. The failures were associated with
the specialty-media workflow/settings.

The "Improve Print Output" modes were removed from further
consideration.

------------------------------------------------------------------------

# 8. Main Tray Experiment With XW

Because the MP/rear path was producing severe curl, a controlled
experiment was attempted using the main tray.

The Brother console did **not** allow **Label** as the paper type for
Main Tray / Tray 1.

Therefore the diagnostic setup used:

-   Main Tray / Tray 1
-   Letter
-   Plain Paper on printer
-   Plain Paper in Printing Preferences
-   XW printable label side face down
-   rear closed / normal top output
-   duplex off
-   Improve Toner Fixing off
-   Reduce Paper Curl off
-   Actual Size / 100%.

At first the job did not print. The printer started, made noise, but did
not feed the XW sheet.

A print job became stuck in Windows.

------------------------------------------------------------------------

# 9. Windows Print Queue Recovery

The stuck job could not initially be deleted from the Windows queue.

The spool folder contained two locked files:

-   `FP00021.SPL`
-   `FP00021.SHD`

Resource Monitor showed that **spoolsv.exe**, PID **26428**, was holding
the files.

The Print Spooler service reported that it was not started, but the
`spoolsv.exe` process was still alive and holding the spool files.

The recovery sequence was:

1.  Printer turned off.
2.  Print Spooler confirmed stopped.
3.  Task Manager → Details.
4.  Located `spoolsv.exe`, PID 26428.
5.  Ended that specific process.
6.  Deleted the two files from: `C:\Windows\System32\spool\PRINTERS`
7.  Restarted the Print Spooler service.

This successfully cleaned the stuck job without restarting the computer.

------------------------------------------------------------------------

# 10. Successful Main Tray Feed --- XW

A subsequent XW sheet did successfully print from the main tray using
Plain Paper.

Result:

-   **no significant curl**
-   sheet was essentially flat,
-   QR codes scanned,
-   toner did not smear after cooling,
-   minor scuff marks remained, especially associated with QR/dense
    black areas.

This was a major improvement over the original MP + Label + rear-output
configuration.

------------------------------------------------------------------------

# 11. Monochrome Test

A particularly important diagnostic test was performed:

-   Main Tray
-   Plain Paper
-   normal top output
-   Ctrl+P = Black & White
-   Brother Printing Preferences Color/Mono = Mono.

Result:

-   **no curl**
-   **no scuff marks**
-   QR codes remained scannable
-   QR toner did not smear.

This established that the Brother is physically capable of producing a
clean XW sheet under at least one monochrome configuration.

However, monochrome cannot be the PlaceWell production solution because
the labels require color.

This test strongly suggested that the scuffing behavior is connected in
some way to the color-printing/rendering/toner-deposition path, rather
than simply to the existence of the PET sheet.

------------------------------------------------------------------------

# 12. Original QR Rendering Investigation

The PlaceWell PDF was inspected.

The QR artwork was found to be:

-   embedded as RGB black `(0,0,0)`,
-   PDF color space using **DeviceRGB** for the QR image,
-   not explicitly encoded as CMYK `0/0/0/100`.

A configured QR color such as `#1C1B19` was not necessarily being
preserved as that exact color in the embedded QR image; the QR pixels
were effectively black.

This meant the printer driver was responsible for converting RGB black
into toner behavior.

A hypothesis was formed that an explicit **K-only black** QR might
reduce toner/scuff behavior while preserving color elsewhere.

That hypothesis was later physically tested and was **not supported by
the results**.

------------------------------------------------------------------------

# 13. Brother Driver Inspection

Brother Printing Preferences → Advanced → Other Print Options was
inspected.

No useful setting was found for:

-   K-only black while retaining color,
-   pure-black toner control,
-   black/gray objects using black toner only.

The available controls included options such as:

-   Sleep Time
-   Macro/Stream
-   Improve Print Output
-   Edge Emphasis
-   Skip Blank Page
-   TrueType Mode
-   Eco settings
-   Document Position Adjustment.

None provided the required black-toner-only control for QR objects in an
otherwise color document.

"Improve Print Output" was intentionally not revisited because its
fixing/curl options had already caused poor results/errors.

------------------------------------------------------------------------

# 14. Top Output Path Experiments

A major hypothesis was that the **rear output path itself** might be
contributing to curl/scuffing.

## 14.1 MP Tray + Plain Paper + top output + Color

Configuration:

-   XW
-   MP Tray
-   Plain Paper
-   rear tray closed
-   sheet exited from normal top output
-   Ctrl+P = Color
-   Brother Color/Mono = Color.

Result:

-   sheet printed successfully,
-   scuff marks remained,
-   but there were **very few** compared with earlier rear-path tests.

This was a meaningful improvement.

## 14.2 MP Tray + Label + top output + Color

Next, only the paper type was changed:

-   XW
-   MP Tray
-   **Label**
-   rear tray closed
-   top output
-   Ctrl+P = Color
-   Brother Color/Mono = Color.

Result:

-   scuff marks still present,
-   but **negligible**,
-   difficult to find,
-   only a very small number of occurrences.

This became one of the closest full-color Brother results to acceptable
output.

Important: it was still **not completely scuff-free**, so it should not
be described as a fully qualified "good" production sheet.

------------------------------------------------------------------------

# 15. K-Only QR Tests

The PlaceWell QR was changed so it was intended to be **K-only / 100%
black**.

The expectation was that this might reproduce the clean monochrome QR
behavior while allowing the rest of the label to remain colored.

The physical results did **not** support that hypothesis.

## 15.1 K-only + Adobe Acrobat + Main Tray

Configuration:

-   K-only QR
-   label font/design in color
-   Adobe Acrobat Reader
-   Main Tray
-   Plain Paper
-   Actual Size
-   Print as Image = unchecked.

Result:

-   **lots of scuff marks**.

## 15.2 K-only + Adobe Acrobat + MP Tray

Configuration:

-   K-only QR
-   color label design
-   Adobe Acrobat Reader
-   MP Tray
-   Label
-   rear closed / top output
-   Actual Size
-   Print as Image = unchecked.

Result:

-   **lots of scuff marks**.

### Interpretation

K-only did not solve the scuffing.

These tests were worse than the corresponding earlier color tests with
the original RGB-black QR.

However, Adobe Acrobat Reader was also a changed variable in these two
tests. Therefore it cannot be stated with certainty that K-only alone
caused the worsening.

Possible contributors include:

-   K-only PDF construction,
-   Acrobat's rendering/color-management path,
-   driver conversion behavior,
-   or an interaction between them.

The safe conclusion is:

**Explicit K-only QR was not demonstrated to improve the Brother/XW
output and should not currently be considered the solution.**

------------------------------------------------------------------------

# 16. Glossy Paper Experiments --- XW

A different media-type setting was then tested.

## 16.1 First Glossy test

Configuration:

-   XW
-   MP Tray
-   Paper Type = Glossy Paper
-   rear tray open
-   rear output path
-   K-only QR
-   label font/design in color.

Result:

-   **significant curl**
-   **no scuff marks** on this first attempt.

This suggested that media/fuser behavior could eliminate scuffing, but
the curl was unacceptable.

## 16.2 Repeat Glossy test

Same general Glossy/rear-path configuration was attempted again.

Result:

-   sheet became **stuck at the very end at the rear-end/output roller**
-   scuff marks were present.

This demonstrated that the configuration was inconsistent and
unreliable.

------------------------------------------------------------------------

# 17. Thick Paper and Additional Glossy Tests --- XW

Both of the following were tried:

-   Paper Type = Thick Paper
-   Paper Type = Glossy Paper.

The XW sheets were getting **stuck toward the end of the sheet/output
path**.

During this test sequence, Print Quality was also changed from
**2400-class to 600 dpi**.

Because paper type and resolution were not isolated as independent
variables in that sequence, the sticking cannot be attributed
specifically to 600 dpi.

### Decision

Both **Thick Paper** and **Glossy Paper** should be considered failed
configurations for the XW workflow due to end-of-path reliability
problems.

------------------------------------------------------------------------

# 18. Important Clarification About "Best" Brother Configuration

At one point MP Tray + Label + top output was described as the "best"
configuration.

That wording was later corrected.

The actual evidence is:

  -----------------------------------------------------------------------
  Configuration                       Output result
  ----------------------------------- -----------------------------------
  Main Tray + Plain + top + Color     No curl; minor QR scuffs

  Main Tray + Plain + top + Mono      No scuffs; QR scans; monochrome
                                      only

  MP + Plain + top + Color            Very few scuffs

  MP + Label + top + Color            Negligible/hard-to-find scuffs

  MP + Label + top + K-only/Adobe     Lots of scuffs

  MP + Glossy + rear + K-only/color   First sheet no scuffs but severe
                                      curl; repeat became stuck/scuffed

  MP + Thick + rear/path testing      End-of-sheet sticking
  -----------------------------------------------------------------------

Therefore:

**No Brother full-color configuration has yet passed all PlaceWell
production requirements.**

A sheet that has "negligible" scuffs is promising, but it is not the
same as a clean, repeatable, production-qualified workflow.

------------------------------------------------------------------------

# 19. Separate SL125-XL Weatherproof Vinyl Test

A separate SheetLabels material was tested:

**SL125-XL --- Weatherproof Vinyl Label**

This must remain distinct from the normal PlaceWell **SL125-XW
polyester/PET** stock.

The tested XL sheets were **not die-cut**, so die-cut alignment could
not be evaluated.

## 19.1 Test configuration

Two sheets were printed consecutively.

Settings:

-   Material: SL125-XL Weatherproof Vinyl
-   Paper Type = Label
-   Input = MP Tray
-   Output = rear path / rear tray open
-   Color/Mono = Auto
-   Print Quality = **600 dpi**
-   Improve Print Output = Off.

## 19.2 XL Sheet 1

Result:

-   became a little stuck toward the end,
-   eventually exited,
-   **no scuff marks**,
-   curl present,
-   QR codes scanned successfully.

## 19.3 XL Sheet 2

Result:

-   exited without getting stuck,
-   **no scuff marks**,
-   curl present,
-   QR codes scanned successfully.

## 19.4 Material deformation on BOTH XL sheets

Both sheets showed a more serious issue at the very top of the sheet:

-   significant warping,
-   the vinyl label face material warped,
-   the face material **lifted/separated from the sticker
    backing/liner**.

The damaged top area did not affect a label on these particular
non-die-cut sample sheets, but the behavior is still considered a
material/production failure.

### XL conclusion

The vinyl behaved differently from XW:

**Positive:** - no scuff marks on either of the two sheets, - QR codes
scanned, - second sheet completed the path without sticking.

**Negative:** - curl on both, - first sheet slightly stuck at end, -
significant top-edge warping on both, - vinyl face separated/lifted from
backing, - die-cut registration untested.

Therefore XL is **not currently qualified** as a replacement for XW.

------------------------------------------------------------------------

# 20. Consolidated Physical Test Matrix

The following matrix captures the important physical experiments
discussed in this qualification effort.

  ----------------------------------------------------------------------------------------------------
  \#       Material   Input    Media     Output      Color/QR   Quality      Result
                               Type                                          
  -------- ---------- -------- --------- ----------- ---------- ------------ -------------------------
  1        XW PET     MP       Label     Rear        Color /    2400-class   Severe curl; scuffing
                                                     original                
                                                     RGB QR                  

  2        XW PET     MP       Label +   Rear        Color      2400-class   Mechanical cycling;
                               Improve                                       Cannot Print 39
                               Toner                                         
                               Fixing                                        

  3        XW PET     MP       Label +   Rear        Color      2400-class   Problematic; Cannot Print
                               Reduce                                        39 / no meaningful curl
                               Curl                                          solution

  4        XW PET     MP       Plain     Rear        Color      2400-class   Toner bonded after
                                                                             cooling; severe curl

  5        XW PET     MP       Plain +   Rear        Color      2400-class   Severe curl; very bad
                               Reduce                                        scuffing
                               Curl                                          

  6        XW PET     Main     Plain     Top         Color /    2400-class   No significant curl;
                                                     original                minor QR scuffs; scans
                                                     RGB QR                  

  7        XW PET     Main     Plain     Top         Mono       2400-class   No curl; no scuffs; QR
                                                                             scans

  8        XW PET     MP       Plain     Top         Color      2400-class   Very few scuffs

  9        XW PET     MP       Label     Top         Color      2400-class   Negligible/hard-to-find
                                                                             scuffs

  10       XW PET     Main     Plain     Top         Color /    ---          Lots of scuffs
                                                     K-only QR               
                                                     via                     
                                                     Acrobat                 

  11       XW PET     MP       Label     Top         Color /    ---          Lots of scuffs
                                                     K-only QR               
                                                     via                     
                                                     Acrobat                 

  12       XW PET     MP       Glossy    Rear        K-only     ---          Significant curl; first
                                                     QR + color              attempt no scuffs
                                                     font                    

  13       XW PET     MP       Glossy    Rear        K-only     ---          Repeat: stuck at rear-end
                                                     QR + color              roller; scuffs
                                                     font                    

  14       XW PET     MP       Thick     Rear/path   Color      600 during   Gets stuck toward end
                                         test                   sequence     

  15       XW PET     MP       Glossy    Rear/path   Color      600 during   Gets stuck toward end
                                         test                   sequence     

  16       XL Vinyl   MP       Label     Rear        Auto /     600          Sheet 1 slight end
                                                     color                   sticking; no scuffs;
                                                                             curl; top material
                                                                             warped/lifted

  17       XL Vinyl   MP       Label     Rear        Auto /     600          Sheet 2 no sticking; no
                                                     color                   scuffs; curl; top
                                                                             material warped/lifted
  ----------------------------------------------------------------------------------------------------

**Note:** Some tests changed more than one variable, particularly during
the Thick/Glossy/600-dpi sequence. Those results should not be used to
attribute causality to resolution alone.

------------------------------------------------------------------------

# 21. What the Testing Has Actually Established

## 21.1 Toner adhesion is not the fundamental blocker

Several XW prints were rubbed after cooling and did not smear.

QR codes remained scannable.

Therefore the statement "laser toner cannot bond to this polyester" is
**not supported by the testing**.

## 21.2 Paper path matters substantially

The same XW stock behaved very differently depending on:

-   MP vs Main input,
-   top vs rear output,
-   media type,
-   color vs monochrome.

The rear label path frequently produced much worse curl.

Closing the rear output and allowing the sheet to exit from the top
substantially improved some color tests.

## 21.3 Color mode matters

The Main Tray + Plain + Mono test was particularly revealing:

-   no scuffing,
-   no curl,
-   QR scans.

The corresponding full-color workflow retained at least some scuffing.

This indicates a relationship between the color print pipeline/toner
deposition and the scuff phenomenon.

## 21.4 K-only did not automatically reproduce Mono behavior

Although a K-only QR sounded promising in theory, the physical
K-only/Acrobat tests had **lots of scuffing**.

Therefore:

**K-only object encoding ≠ guaranteed monochrome-engine behavior.**

## 21.5 600 dpi has not yet been proven to help

600 dpi was introduced during later Thick/Glossy tests, but those tests
also changed media settings.

There is not yet a clean 2400-vs-600 controlled comparison with every
other variable identical.

## 21.6 XL vinyl solved one symptom but created another

The two XL sheets had no scuffing, but:

-   curled,
-   one slightly stuck,
-   both significantly warped/delaminated at the top.

This is not acceptable for production.

------------------------------------------------------------------------

# 22. Brother Qualification Status

As of this record:

### Passed individually

-   QR print sharpness: **Yes**
-   QR scan reliability on tested sheets: **Yes**
-   Toner can bond without smearing after cooling: **Yes**
-   Main-tray XW can produce a flat sheet: **Yes**
-   Monochrome XW can print cleanly: **Yes**
-   Some full-color configurations can reduce scuffs to negligible
    levels: **Yes**

### Not yet passed as a complete production workflow

-   Full-color + zero/acceptable scuffs: **Not consistently proven**
-   Full-color + no curl: **Not consistently proven across required
    workflow**
-   No jams/sticking: **Not consistently proven**
-   Consecutive multi-sheet reliability: **Not proven for final XW
    configuration**
-   10-sheet unattended run: **Not passed**
-   All three die-cut XW SKUs: **Not passed**
-   Production die-cut registration across repeated sheets: **Not fully
    qualified**
-   Synthetic-media stability across repeated printing: **Not fully
    qualified**

**Overall Brother status: NOT YET PRODUCTION-QUALIFIED.**

------------------------------------------------------------------------

# 23. Alternative Printer Research

The Brother problems triggered research into printers with better
synthetic-label/media specifications.

## 23.1 Xerox C320

The Xerox C320 became the leading lower-cost alternative.

Relevant manufacturer specifications found:

-   color laser,
-   approximately 35 ppm,
-   1200 × 1200 dpi,
-   250-sheet standard main tray,
-   approximately 170-sheet output,
-   recommended monthly volume up to approximately 6,000,
-   standard main tray media weight approximately **60--216 GSM**,
-   manual feed slot approximately **60--216 GSM**,
-   media list includes labels and vinyl labels.

This is important because:

-   XW = approximately **182 GSM**
-   Xerox standard tray maximum = approximately **216 GSM**

Therefore XW is within the Xerox standard tray's published general
weight range.

### Important Xerox limitation

Xerox documentation located during the research explicitly mentions:

-   Labels
-   Paper Labels
-   Vinyl Labels

It does **not clearly state PET/polyester labels** for the C320.

Therefore the C320 is a **plausible qualification candidate**, not a
confirmed XW/PET-certified solution.

The optional multipurpose/bypass feeder was also found in detailed
documentation with a lower weight allowance around **176 GSM** in some
configurations. Therefore the proposed XW test path would be the
**standard main tray**, not an optional bypass feeder.

### Xerox qualification plan

If purchased:

1.  ordinary-paper setup test,
2.  one SL125-XW sheet from standard main tray,
3.  correct label/media configuration,
4.  3 consecutive XW sheets,
5.  10 consecutive XW sheets,
6.  SL1184-XW,
7.  SL1189-XW,
8.  larger future XW sheet.

Pass only if:

-   no meaningful scuffing,
-   no toner transfer,
-   no jams,
-   acceptable curl,
-   accurate registration,
-   reliable QR scanning,
-   unattended multi-sheet output.

------------------------------------------------------------------------

# 24. Xerox C320 Cost / Retail Findings

At the time of research:

-   Staples listing: approximately **\$469.99**
-   Office Depot listing: approximately **\$469.99** sale
-   Best Buy did not surface as a reliable current C320 source.
-   Amazon did not surface a clean C320 listing sold directly by Amazon
    that was preferable to Staples/Office Depot.

Starter toner was understood to be included/preinstalled, approximately:

-   black starter: 1,500 pages,
-   cyan/magenta/yellow starters: 1,000 pages each.

This was sufficient for qualification without buying replacement toner
upfront.

Approximate genuine high-capacity toner figures gathered:

-   Black 006R04831: \~8,000 pages
-   C/M/Y: \~5,500 pages each
-   full high-capacity set around \~\$950 at the researched prices.

Actual PlaceWell toner consumption should be much lower than ISO
full-page-equivalent assumptions because the artwork is sparse.

------------------------------------------------------------------------

# 25. Xerox Return-Policy Considerations

Staples and Office Depot were preferred over marketplace sellers because
the printer needs to be **opened and physically tested**.

At the time of research:

### Staples

Technology/business machines including printers generally had a **14-day
return window** from receipt, with:

-   original packaging,
-   UPC,
-   manuals,
-   parts/accessories,
-   sellable condition,
-   receipt/packing slip.

The policy reviewed did not state that printers had to remain unopened.

### Office Depot

Technology/electronics similarly had a **14-day** return window, with:

-   original packaging,
-   UPC,
-   like-new condition.

For either retailer, the operational recommendation was:

-   preserve every packaging component,
-   test immediately,
-   complete qualification in the first few days,
-   do not wait until the end of the return window.

------------------------------------------------------------------------

# 26. Brother Direct Return Research

Because the Brother was purchased **directly from Brother**, its return
must go through Brother rather than a retail store.

The discussion identified Brother's direct-purchase return/support route
and emphasized:

-   initiate the return through Brother,
-   obtain Brother's return instructions/RMA if required,
-   do not ship to an assumed address,
-   preserve original box, foam, accessories, documentation, included
    toner, etc.,
-   confirm whether Brother provides prepaid return shipping,
-   confirm whether any restocking/return fee applies before shipping.

The printer should not be misrepresented as defective solely because XW
is outside the Brother's published MP-tray weight range.

Actual observed issues such as `Cannot Print 39` occurred during Brother
driver Improve Print Output experiments, but any return description
should remain truthful and factual.

------------------------------------------------------------------------

# 27. Lexmark Research

Research was expanded because the Xerox documentation did not explicitly
state polyester/PET.

## 27.1 Current smaller Lexmark models

The Lexmark CS531dw was investigated.

Useful specifications included:

-   color laser,
-   35 ppm,
-   1200 × 1200,
-   standard tray approximately **60--220 GSM**,
-   250-sheet input,
-   170-sheet output,
-   recommended monthly volume approximately 1,500--10,000.

However, the current documentation found explicitly listed:

-   paper labels,
-   vinyl labels,

rather than clearly stating polyester labels.

Therefore it remained in a similar evidence category to Xerox: plausible
by weight/media handling, but not an explicit PET/polyester
qualification.

## 27.2 Lexmark CS820 enterprise series

Older/larger Lexmark enterprise documentation explicitly uses the term:

**Polyester Labels**

Detailed label-specific documentation was found indicating
polyester-label support up to approximately **220 GSM** for the CS820
family.

This is significant because:

-   PlaceWell XW = PET/polyester,
-   XW construction ≈ 182 GSM,
-   182 GSM is below the documented \~220 GSM polyester-label allowance.

This was the strongest explicit synthetic-material match found during
the research.

### CS820 disadvantages

The CS820 is an enterprise-class printer:

-   very large,
-   roughly 137 lb depending configuration,
-   around 60 ppm,
-   large input/output capacity,
-   recommended for much higher monthly volumes,
-   approximately \$2,000+ in listings found during research.

Therefore it was considered technically compelling but economically
excessive for PlaceWell at launch.

------------------------------------------------------------------------

# 28. HP / Other Models Excluded or Deprioritized

## HP Color LaserJet Pro 4201dw

The general supported media weight was found around:

-   60--163 GSM for general media,
-   certain higher figures only for specific media such as postcards or
    HP-specific glossy stock.

Since XW is approximately 182 GSM, the HP did not provide the clean
general media-weight match needed.

It was therefore excluded as a primary XW recommendation.

## Brother HL-L8245CDW

Although labels are supported, the MP-tray weight range was again around
the same \~163 GSM level.

This would repeat the fundamental specification mismatch found with the
HL-L8430CDW.

Therefore it was excluded.

## Canon imageCLASS LBP674Cdw II

This was considered as another color-laser candidate, but the research
did not find as clean a model-specific manufacturer statement for 182
GSM PET/polyester labels as desired.

It remained lower priority.

------------------------------------------------------------------------

# 29. Polyester vs Vinyl --- Why the Distinction Matters

During research it became important not to treat these terms as
interchangeable.

### XW

-   PET/polyester
-   synthetic
-   weatherproof
-   laser-compatible
-   approximately 182 GSM.

### XL

-   weatherproof vinyl material
-   different polymer/construction,
-   physically more flexible,
-   behaves differently under heat.

A printer specification saying **"vinyl labels"** does not automatically
mean that the manufacturer explicitly supports **PET/polyester labels**.

Likewise, simply being under a printer's GSM limit does not guarantee
acceptable behavior because synthetic materials can react differently
to:

-   fuser heat,
-   roller pressure,
-   paper-path curvature,
-   adhesive/liner construction,
-   toner coverage.

This is why physical qualification remains necessary even when
specifications appear compatible.

------------------------------------------------------------------------

# 30. Future PlaceWell Label Expansion

The printer should ideally support larger labels for:

-   totes,
-   storage boxes,
-   other PlaceWell organization use cases.

Larger XW formats identified during research included examples such as:

-   approximately 3 × 5",
-   6 × 4",
-   6.75 × 4.25",
-   approximately 6.94 × 4",
-   8 × 5",
-   full-sheet 8.5 × 11",
-   large round formats.

Operationally, staying with **8.5 × 11" sheet stock** where possible was
preferred because it simplifies:

-   inventory,
-   printer setup,
-   calibration,
-   PDF generation.

A future printer qualification should include at least one larger XW
sheet in addition to the three launch SKUs.

------------------------------------------------------------------------

# 31. Toner Cost Context

Toner cost was researched but is not currently the primary technical
blocker.

## Brother

Approximate genuine high-yield prices gathered during research:

-   TN229XLBK black: \~\$96, \~3,000 pages
-   TN229XLC/M/Y: \~\$123 each, \~2,300 pages each.

A complete genuine set was roughly \~\$467 at those researched prices.

## Xerox

High-capacity set was roughly \~\$950 at researched prices.

## PlaceWell-specific implication

ISO toner yield is based on standardized page coverage and does not
directly represent PlaceWell's sparse labels.

A provisional planning estimate discussed was approximately **\$0.12
toner per PlaceWell sheet** until actual cartridge usage can be
measured.

At that planning value:

-   30-label round sheet ≈ 0.4¢ toner per label,
-   20-label rectangle/square sheet ≈ 0.6¢ toner per label.

The likely larger COGS drivers are:

-   blank XW material,
-   spoilage/waste,
-   labor,
-   printer amortization,

rather than toner alone.

A proper production COGS model should eventually use:

**XW material + toner + expected waste + printer amortization + labor =
cost per printed sheet / cost per finished label.**

------------------------------------------------------------------------

# 32. Key Lessons From the Qualification Work

## Lesson 1 --- Do not select a printer based on "laser compatible" alone

The stock can be laser-compatible while still behaving poorly in a
particular printer.

## Lesson 2 --- GSM is necessary but not sufficient

The Brother/XW mismatch is meaningful, but synthetic construction, fuser
behavior, and paper path also matter.

## Lesson 3 --- Input and output paths materially affect the result

Main/top, MP/top, and MP/rear produced dramatically different physical
behavior.

## Lesson 4 --- A single clean sheet is not a production pass

Glossy/rear produced one scuff-free sheet and then failed on a repeat.

## Lesson 5 --- Monochrome success does not guarantee color success

The Brother produced a clean monochrome XW sheet while full-color tests
continued to show scuffing.

## Lesson 6 --- K-only QR is not automatically equivalent to monochrome printing

The K-only PDF tests did not reproduce the clean Mono result.

## Lesson 7 --- Do not change multiple variables when trying to determine cause

Later Thick/Glossy tests also changed resolution to 600 dpi, making it
impossible to attribute behavior solely to resolution.

Future experiments should change **one variable at a time** whenever
possible.

## Lesson 8 --- Material substitution can introduce new failure modes

XL vinyl removed scuffs in two tests but introduced significant
warping/delamination.

------------------------------------------------------------------------

# 33. Recommended Test-Recording Format Going Forward

Every future physical test should be recorded with the following fields:

**Material** - SKU - XW / XL / other - die-cut or non-die-cut

**PDF** - file/version - RGB QR / K-only QR - color design /
monochrome - viewer used (browser, Windows viewer, Acrobat, etc.) -
Print as Image on/off if Acrobat

**Printer** - model - firmware if changed

**Input** - Main Tray / MP Tray

**Printer paper type** - Plain / Label / Thick / Glossy / other

**Output** - top output / rear output

**Driver** - Color / Mono / Auto - resolution 600 / 2400 - Improve Print
Output setting - duplex - scaling

**Run** - number of consecutive sheets

**Results** - fed successfully? - stuck/jammed? - where did it stick? -
curl after exit? - curl after cooling? - scuffing? - location of
scuffing? - toner rub/smear after cooling? - material
warping/delamination? - QR scans? - registration accurate? - output
stack usable? - notes/photos.

This structure will prevent ambiguity as the number of experiments
grows.

------------------------------------------------------------------------

# 34. Current Decision State

At the end of the recorded tests:

### Brother HL-L8430CDW

**Do not call it production-qualified yet.**

Promising evidence:

-   can feed XW,
-   can produce flat XW from Main Tray,
-   toner can bond,
-   QR scans,
-   monochrome can be clean,
-   MP + Label + top output reduced color scuffs to negligible levels in
    one test configuration.

Remaining concerns:

-   color scuffing,
-   repeatability,
-   curl on rear path,
-   sticking on Thick/Glossy/rear tests,
-   XW is above Brother's published MP-tray weight range,
-   final 3/10-sheet full-color production test has not passed.

### SheetLabels XW Polyester

Still the **preferred/locked PlaceWell launch material** unless a
deliberate material decision changes it.

### SheetLabels XL Vinyl

**Not qualified** based on current test:

-   no scuffs was encouraging,
-   but curl + top-edge warping/delamination is unacceptable.

### Xerox C320

Still a **reasonable lower-cost alternative to physically qualify** if
Brother cannot reach a stable full-color workflow.

Advantages:

-   182 GSM XW is within standard tray's general 216 GSM range,
-   labels supported,
-   reasonable launch price.

Limitation:

-   explicit PET/polyester support was not found in the C320
    documentation reviewed.

### Lexmark CS820

Strongest explicit documentation found for **polyester labels** at a
weight covering XW.

Disadvantages:

-   enterprise size,
-   enterprise cost,
-   likely overkill for PlaceWell launch.

------------------------------------------------------------------------

# 35. Final Working Conclusion

The printer investigation should not be reduced to "Brother works" or
"Brother fails."

The evidence is more nuanced:

1.  The original Brother-recommended MP/Label/rear workflow was poor for
    PlaceWell XW because of severe curl/scuffing.
2.  Main Tray + Plain demonstrated that XW can exit the Brother
    essentially flat.
3.  Mono demonstrated that the printer can create a clean, scuff-free,
    scannable XW sheet.
4.  Full-color printing remains the unresolved part.
5.  MP + Label + top output came very close, with negligible scuffing in
    one controlled test.
6.  K-only QR did not solve the problem in the tested Acrobat workflow.
7.  Glossy/Thick settings introduced unacceptable sticking/curl
    behavior.
8.  XL vinyl removed scuffs on two sheets but introduced unacceptable
    warping/lifting.
9.  No final full-color configuration has yet passed repeated production
    qualification.
10. Any final Brother decision should be based on a controlled,
    repeatable run rather than one isolated clean print.

This record should be treated as the baseline for all future PlaceWell
printer/media qualification work so that these experiments do not need
to be repeated or reconstructed from memory.
