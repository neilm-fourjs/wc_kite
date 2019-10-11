# Copyright 2010-2010 Four J's Development Tools. All Rights Reserved.
# $Id:$

-- Web Component Demo by Neil J Martin ( neilm@4js.com )
-- Kite designs by JestOfEve.

IMPORT xml
IMPORT os
IMPORT FGL g2_lib
IMPORT FGL g2_appInfo
IMPORT FGL g2_about
CONSTANT C_PRGVER = "3.1"
CONSTANT C_PRGDESC = "WC Kite Demo"
CONSTANT C_PRGAUTH = "Neil J.Martin"
CONSTANT C_PRGICON = "logo_dark"

DEFINE m_kitePath STRING = "../pics/webcomponents/kite"

DEFINE m_kites DYNAMIC ARRAY OF STRING
DEFINE m_rec RECORD
  kitename STRING,
  kiteFileName STRING,
  colourSchemaName STRING,
  panels DYNAMIC ARRAY OF RECORD
    p STRING,
    c STRING
  END RECORD
END RECORD
DEFINE info STRING
DEFINE m_appInfo g2_appInfo.appInfo
MAIN
  DEFINE wc_data, panel, colour STRING
  CALL m_appInfo.progInfo(C_PRGDESC, C_PRGAUTH, C_PRGVER, C_PRGICON)
  CALL g2_lib.g2_init(ARG_VAL(1), "wc_kite")

-- Try and find the kite folder
	IF os.path.isDirectory("../webcomponents/kite") THEN
		LET m_kitePath = "../webcomponents/kite"
	END IF
	IF os.path.isDirectory("../wc_kite/webcomponents/kite") THEN
		LET m_kitePath = "../wc_kite/webcomponents/kite"
	END IF
	DISPLAY "Kite Path:",m_kitePath

  OPEN FORM f FROM "wc_kite"
  DISPLAY FORM f

-- Default kite to show on load.
  LET m_rec.kitename = "Talon_std"
  LET m_rec.colourSchemaName = "New"
  LET m_rec.kiteFileName = os.path.join(m_kitePath, "kite_" || m_rec.kitename || ".svg")
  CALL setSVG(m_rec.kitename)
  LET wc_data = serializePanels()

  DISPLAY BY NAME info
  OPTIONS INPUT WRAP
  DIALOG ATTRIBUTES(UNBUFFERED)
    INPUT BY NAME m_rec.kitename, m_rec.colourSchemaName, wc_data, panel, colour
        ATTRIBUTE(WITHOUT DEFAULTS)
      ON CHANGE kitename
        CALL m_rec.panels.clear()
        LET m_rec.colourSchemaName = "New"
        LET m_rec.kiteFileName = os.path.join(m_kitePath, "kite_" || m_rec.kitename || ".svg")
        CALL setSVG(m_rec.kitename)
        LET wc_data = serializePanels()
      ON ACTION kiteupdated
        DISPLAY "DATA=", wc_data
        CALL updatePanels(wc_data)
        LET wc_data = serializePanels()
    END INPUT
    DISPLAY ARRAY m_rec.panels TO arr.*
    END DISPLAY
    ON ACTION newKite
      CALL m_rec.panels.clear()
      LET m_rec.colourSchemaName = "New"
      LET m_rec.kiteFileName = os.path.join(m_kitePath, "kite_" || m_rec.kitename || ".svg")
      CALL setSVG(m_rec.kitename)
      LET wc_data = serializePanels()
      NEXT FIELD kitename
    ON ACTION saveKite
      CALL saveKite()
    ON ACTION openKite
      CALL openKite()
      CALL setSVG(m_rec.kitename)
      LET wc_data = serializePanels()
    ON ACTION about
			CALL g2_about.g2_about(m_appInfo)
    ON ACTION EXIT
      EXIT DIALOG
    ON ACTION CLOSE
      EXIT DIALOG
  END DIALOG
  CALL g2_lib.g2_exitProgram(0, % "Program Finished")
END MAIN
--------------------------------------------------------------------------------
#+ serialize panels to a web component value
FUNCTION serializePanels()
  DEFINE wcValue base.StringBuffer
  DEFINE i INTEGER
  LET wcValue = base.StringBuffer.create()
  FOR i = 1 TO m_rec.panels.getLength()
    IF i != 1 THEN
      CALL wcValue.append("\n")
    END IF
    CALL wcValue.append(m_rec.panels[i].p)
    CALL wcValue.append("=")
    CALL wcValue.append(m_rec.panels[i].c)
  END FOR
  RETURN wcValue.toString()
END FUNCTION
--------------------------------------------------------------------------------
#+ update panels according to the given web component value
FUNCTION updatePanels(wcValue)
  DEFINE wcValue STRING
  DEFINE stRow base.StringTokenizer
  DEFINE stCol base.StringTokenizer
  DEFINE theCurrentRow STRING
  DEFINE i INTEGER

  LET i = 1
  CALL m_rec.panels.clear()
  LET stRow = base.StringTokenizer.create(wcValue, "\n")
  WHILE stRow.hasMoreTokens()
    LET theCurrentRow = stRow.nextToken()
    LET stCol = base.StringTokenizer.create(theCurrentRow, "=")
    IF stCol.countTokens() = 2 THEN
      LET m_rec.panels[i].p = stCol.nextToken()
      LET m_rec.panels[i].c = stCol.nextToken()
      LET i = i + 1
    END IF
  END WHILE
END FUNCTION
--------------------------------------------------------------------------------
#+ Set a Property in the AUI
FUNCTION wc_setProp(l_prop_name STRING, l_value STRING)
  DEFINE w ui.Window
  DEFINE n om.domNode
  LET w = ui.Window.getCurrent()
  LET n = w.findNode("Property", l_prop_name)
  IF n IS NULL THEN
    DISPLAY "can't find property:", l_prop_name
    RETURN
  END IF
  CALL n.setAttribute("value", l_value)
END FUNCTION
--------------------------------------------------------------------------------
#+ Set the svg image into the component.
FUNCTION setSVG(l_nam STRING)
  CALL wc_setProp("model", "xx" || l_nam) -- force a refresh
  CALL wc_setProp("model", l_nam)
  IF l_nam MATCHES "*Trident*" OR l_nam MATCHES "*Talon*" THEN
    LET info = '<b><a href="http://www.jestofevekites.com/">Jest of Eve Kites</a></b>'
  END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Save list of Colours + kite name.
FUNCTION saveKite()
  DEFINE dd xml.DomDocument
  DEFINE dn xml.DomNode
  DEFINE l_tmpFile, l_fileName STRING

  LET dd = xml.DomDocument.Create()
  LET dn = dd.createElement("kite")
  CALL xml.Serializer.VariableToDom(m_rec, dn)
  CALL dd.appendDocumentNode(dn)

  LET l_fileName = winSaveFile("", "Colour List", "*.xml", "Save Colour List")
  IF l_fileName IS NULL THEN
    RETURN
  END IF

  LET l_tmpFile = fgl_getpid() || ".tmp"
  TRY
    CALL dd.save(l_tmpFile)
  CATCH
    CALL g2_lib.g2_errPopup(
        SFMT(% "File Save Failed!\nStatus: %1 %2 Name:%3", STATUS, err_get(STATUS), l_tmpFile))
  END TRY
  TRY
    CALL fgl_putfile(l_tmpFile, l_fileName)
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "File Transfer Failed!\nStatus:%1 %2", STATUS, err_get(STATUS)))
  END TRY
  IF NOT os.Path.delete(l_tmpFile) THEN
    -- Failed to delete temp file !
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Open a save Colour Schema and kite.
FUNCTION openKite()
  DEFINE dd xml.DomDocument
  DEFINE dn xml.DomNode
  DEFINE tmpFile, fileName STRING

  LET tmpfile = fgl_getpid() || ".tmp"

  IF ui.Interface.getFrontEndName() != "GDC" THEN
    OPEN WINDOW upload_kite WITH FORM "fileupload" ATTRIBUTES(STYLE = "dialog")
    INPUT BY NAME fileName ATTRIBUTES(UNBUFFERED)
      ON ACTION ACCEPT
        DISPLAY "uploadGWC:", fileName
        IF fileName.equals("") THEN
          RETURN
        END IF
        ACCEPT INPUT
      ON ACTION CANCEL
        EXIT INPUT
    END INPUT
    CLOSE WINDOW upload_kite
  ELSE
    LET fileName = winOpenFile("", "Colour List", "*.xml", "Open Colour List")
    IF fileName IS NULL THEN
      RETURN
    END IF
  END IF

  TRY
    CALL fgl_getfile(fileName, tmpfile)
  CATCH
    ERROR "Failed to upload '" || fileName || "'"
    RETURN
  END TRY

  LET dd = xml.DomDocument.Create()
  TRY
    SLEEP 1
    CALL dd.load(tmpFile)
    SLEEP 1
    IF NOT os.Path.delete(tmpFile) THEN
      -- Failed to delete temp file !
    END IF
  CATCH
    -- Failed to open
    ERROR "Failed to open '" || tmpFile || "'"
    RETURN
  END TRY

  LET dn = dd.getDocumentElement()
  LET dn = dn.getFirstChildElement()
  CALL m_rec.panels.clear()
  CALL xml.Serializer.DomToVariable(dn, m_rec)
END FUNCTION
--------------------------------------------------------------------------------
#+ Populate the combobox with all the kite svg files found in rs_path
FUNCTION cb_kites(cb)
  DEFINE cb ui.ComboBox
  DEFINE l_file STRING
  DEFINE dir SMALLINT

  CALL m_kites.clear()
  CALL os.Path.dirsort("name", 1)

  LET dir = os.Path.diropen(m_kitePath)
  WHILE dir > 0
    LET l_file = os.Path.dirnext(dir)
    IF l_file IS NULL THEN
      EXIT WHILE
    END IF
    IF os.path.extension(l_file) = "svg" AND l_file.subString(1, 5) = "kite_" THEN
      LET l_file = os.path.rootname(l_file.subString(6, l_file.getLength()))
      LET m_kites[m_kites.getLength() + 1] = l_file
      CALL cb.addItem(l_file, l_file)
    END IF
  END WHILE
END FUNCTION
