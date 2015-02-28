/* grep.c - grep command for TCL
 *
 * 1997-1998 by David S. Herron
 */

#include <tcl.h>

static int Grep_GrepCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  int aCounter;
  int caseless                    = 0;
  enum { NL, CRLF, CR } lineEnder = NL;
  int giveBlockNumber             = 0;
  int countOnly                   = 0;
  int patternSimpleString         = 0;
  int suppressErrors              = 0;
  int nonMatchingLines            = 0;
  int patternWord                 = 0;
  int statusOnly                  = 0;
  int matchWholeLine              = 0;
  int compileOnly                 = 0;
  int useCompiled                 = 0;
  int patternGLOB                 = 0;
  int matchCount = 0;
  Tcl_DString retval;
  /* The return value can be a list of lists.
   * The first element of each item is a code, one of the following:
   */
  const char *codeError = "error";
  const char *codeMatch = "match";

  char *patternList = (char *)0;
  char *fileList    = (char *)0;

  char *extraErrorInfo = (char *)0;

  if (1 == 0) {
  usage:
    Tcl_AppendResult(interp, "USAGE: grep ?options? pattern(s) file(s)",
		     extraErrorInfo, 0);
    return TCL_ERROR;
  }

  for (aCounter = 1; aCounter < argc; aCounter++) {
    char *arg = argv[aCounter];

    if      (strcmp(arg, "-i"       ) == 0) { caseless            = 1; }
    else if (strcmp(arg, "-l"       ) == 0) {
      if ((aCounter+1) >= argc) {
	extraErrorInfo = ": Not enough arguments";
	goto usage;
      }
      arg = argv[++aCounter];
      if      (strcmp(arg, "NL"     ) == 0) { lineEnder           = NL; }
      else if (strcmp(arg, "CRLF"   ) == 0) { lineEnder           = CRLF; }
      else if (strcmp(arg, "CR"     ) == 0) { lineEnder           = CR; }
      else {
	extraErrorInfo = ": Unknown line ender string - must be NL|CRLF|CR";
	goto usage;
      }
    }
    else if (strcmp(arg, "-b"       ) == 0) { giveBlockNumber     = 1; }
    else if (strcmp(arg, "-c"       ) == 0) { countOnly           = 1; }
    else if (strcmp(arg, "-E"       ) == 0) { patternSimpleString = 1; }
    else if (strcmp(arg, "-G"       ) == 0) { patternGLOB         = 1; }
    else if (strcmp(arg, "-s"       ) == 0) { suppressErrors      = 1; }
    else if (strcmp(arg, "-v"       ) == 0) { nonMatchingLines    = 1; }
    else if (strcmp(arg, "-w"       ) == 0) { patternWord         = 1; }
    else if (strcmp(arg, "-x"       ) == 0) { matchWholeLine      = 1; }
    else if (strcmp(arg, "-compile" ) == 0) { compileOnly         = 1; }
    else if (strcmp(arg, "-compiled") == 0) { useCompiled         = 1; }
    /*else if (strcmp(arg, "-i") == 0) {  }*/
    else if (arg[0] == '-') {
      extraErrorInfo = ": Unknown option";
      goto usage;
    }
    else {
      if (!patternList)
	patternList = arg;
      else if (!fileList)
	fileList = arg;
      else {
	extraErrorInfo = ": Too many non-option arguments given";
	goto usage;
      }
    }
  }

  if (!patternList) {
    extraErrorInfo = ": No pattern(s) given";
    goto usage;
  }
  if (!fileList) {
    extraErrorInfo = ": No file(s) given";
    goto usage;
  }

  /*
   * Tcl_RegExpCompile.3
   * Tcl_RegExpExec.3
   * Tcl_RegExpMatch.3
   * Tcl_RegExpRange.3
   *
   * int Tcl_RegExpMatch(interp, string, pattern)
   *
   * Tcl_RegExp Tcl_RegExpCompile(interp, pattern)
   *
   * int Tcl_RegExpExec(interp, regexp, string, start)
   *
   * Tcl_RegExpRange(regexp, index, startPtr, endPtr)
   */

  {
    Tcl_RegExp compiled;
    int numFiles;
    char **strFiles;
    int nFile;
    int nLine;
    int done;
    unsigned long lBeginLine;
    char inpBuf[3];
    int  inpRead;
    char cThis = '\0', cLast = '\0';
    Tcl_DString line;
    Tcl_DString element;
    Tcl_Channel inp;


    if (Tcl_SplitList(interp, fileList, &numFiles, &strFiles) != TCL_OK) {
      Tcl_ResetResult(interp);
      Tcl_AppendResult(interp, "Bad file list: ", fileList, NULL);
      return TCL_ERROR;
    }

    compiled = Tcl_RegExpCompile(interp, patternList);
    if (!compiled) {
      Tcl_ResetResult(interp);
      Tcl_AppendResult(interp, "Bad pattern: ", patternList, NULL);
      Tcl_Free((char *)strFiles);
      return TCL_ERROR;
    }

    Tcl_DStringInit(&retval);
    Tcl_DStringInit(&element);
    Tcl_DStringInit(&line);

    for (nFile = 0; nFile < numFiles; nFile++) {

      /* Open the file */
      inp = Tcl_OpenFileChannel(interp, strFiles[nFile], "r", 0644);

      if (!inp) {
	/* Retrieve error message */
	/* Append to result */
	if (!suppressErrors) {
	  int nError;
	  char bError[20];
	  nError = Tcl_GetErrno();
	  sprintf(bError, "(%d)", nError);

	  /* Append: { error {Unable to open file <file>: (n) why} } */
	  Tcl_DStringFree(&element);
	  Tcl_DStringAppendElement(&element, codeError);
	  Tcl_DStringFree(&line);
	  Tcl_DStringAppend(&line, "Unable to open file ", -1);
	  Tcl_DStringAppend(&line, strFiles[nFile], -1);
	  Tcl_DStringAppend(&line, ": ", -1);
	  Tcl_DStringAppend(&line, bError, -1);
	  Tcl_DStringAppend(&line, " ", -1);
	  Tcl_DStringAppend(&line, Tcl_PosixError(interp), -1);
	  Tcl_DStringAppendElement(&element, Tcl_DStringValue(&line));
	  Tcl_DStringAppendElement(&retval, Tcl_DStringValue(&element));
	  Tcl_DStringFree(&line);
	  Tcl_DStringFree(&element);
	}
	continue;
      }

      /* Begin processing the input */
      nLine = 0;
      done = 0;
      lBeginLine = Tcl_Tell(inp);
      while (!done) {
	inpRead = Tcl_Read(inp, inpBuf, 1);
	if (inpRead <= 0 || inpRead > 1) {
	  /* There may be an error worth worrying about...? */
	  /* There may be something to do with the current input
	   * if we did not end on a full line */
	  int nError;
	  nError = Tcl_GetErrno();
	  Tcl_Close(interp, inp);
	  done = 1;
	  if (inpRead == -1 && nError != 0 && !suppressErrors) {
	    char bError[20];
	    sprintf(bError, "(%d)", nError);

	    /* Append: { error {Error reading file <file>: (n) Why} } */
	    Tcl_DStringFree(&element);
	    Tcl_DStringAppendElement(&element, codeError);
	    Tcl_DStringAppend(&line, "Error reading file ", -1);
	    Tcl_DStringAppend(&line, strFiles[nFile], -1);
	    Tcl_DStringAppend(&line, ": ", -1);
	    Tcl_DStringAppend(&line, bError, -1);
	    Tcl_DStringAppend(&line, " ", -1);
	    Tcl_DStringAppend(&line, Tcl_PosixError(interp), -1);
	    Tcl_DStringAppendElement(&element, Tcl_DStringValue(&line));
	    Tcl_DStringAppendElement(&retval, Tcl_DStringValue(&element));
	    Tcl_DStringFree(&line);
	    Tcl_DStringFree(&element);
	  }
	  continue;
	}

	if (Tcl_Eof(inp)) {
	  Tcl_Close(interp, inp);
	  done = 1;
	  continue;
	}

	/* cThis and cLast are used in determining line ending */
	cLast = cThis;
	cThis = inpBuf[0];
	
	if (cThis == '\r' || cThis == '\n') {
	  int lineEnd = 0;
	  /* This might be end of line.
	   * Depending on the line-ending style chosen see if it is.
	   */
	  switch (lineEnder) {
	  case CR:
	    if (cThis == '\r')
	      lineEnd = 1;
	    break;
	  case NL:
	    if (cThis == '\n')
	      lineEnd = 1;
	    break;
	  case CRLF:
	    if (cThis == '\n' && cLast == '\r')
	      lineEnd = 1;
	    break;
	  }
	  
	  if (lineEnd) {
	    /* In coming here we know that 'line' has a line
	     * of text in it.  We now match the compiled expression
	     * against the text to see if it matches.
	     * If so we do appropriate appending to the return buffer.
	     */
	    char *start = Tcl_DStringValue(&line);
	    enum { SHOW_LINE, SHOW_ERROR, NOTHING } action = NOTHING;
	    int matchResult = 0;

	    ++nLine;	/* Bump line counter */

	    /* Compare ... */
	    matchResult = Tcl_RegExpExec(interp, compiled, start, start);

	    /* Depending on compare status and "-v" or not, decide
	     * on the action to perform. */
	    if (nonMatchingLines) {
	      switch (matchResult) {
	      case 1:  action = NOTHING;    break;
	      case 0:  action = SHOW_LINE;  break;
	      case -1: action = SHOW_ERROR; break;
	      }
	    }
	    else {
	      switch (matchResult) {
	      case 1:  action = SHOW_LINE;  break;
	      case 0:  action = NOTHING;    break;
	      case -1: action = SHOW_ERROR; break;
	      }
	    }

	    switch (action) {
	    case SHOW_LINE:

	      if (countOnly) {
		/* We are to only give a count of matches.
		 * Make the count. */
		matchCount++;
	      }
	      else {
		/*
		 * What we are to append is determined by the
		 * command arguments parsed above.
		 *
		 *	match {file name} {line#} {text of line}
		 *
		 * This is appended to retval as an element.
		 */
		char lBuf[30];
		
		Tcl_DStringFree(&element);
		Tcl_DStringAppendElement(&element, codeMatch);
		Tcl_DStringAppendElement(&element, strFiles[nFile]);
		sprintf(lBuf, "%d", nLine);
		Tcl_DStringAppendElement(&element, lBuf);
		Tcl_DStringAppendElement(&element, start);
		/* Append 'block number' if wanted */
		if (giveBlockNumber) {
		  sprintf(lBuf, "%u", (unsigned long) (lBeginLine / 512));
		  Tcl_DStringAppendElement(&element, start);
		}
		Tcl_DStringAppendElement(&retval, Tcl_DStringValue(&element));
		Tcl_DStringFree(&element);
	      }
	      break;
	    case NOTHING:
	      break;
	    case SHOW_ERROR:
	      if (!suppressErrors) {
		char lBuf[30];

		Tcl_DStringFree(&element);
		Tcl_DStringAppendElement(&element, codeError);
		Tcl_DStringAppendElement(&element, strFiles[nFile]);
		sprintf(lBuf, "%d", nLine);
		Tcl_DStringAppendElement(&element, lBuf);
		Tcl_DStringAppendElement(&element, interp->result);
		Tcl_DStringAppendElement(&retval, Tcl_DStringValue(&element));
		Tcl_DStringFree(&element);
	      }
	      break;
	    }

	    /* We are done with this line.  Discard the line.
	     * Record the byte number for the beginning of the line
	     * since this is used if we are giving block numbers.
	     */
	    Tcl_DStringFree(&line);
	    lBeginLine = Tcl_Tell(inp);
	    continue;
	  }
	}
	
	inpBuf[1] = '\0';
	Tcl_DStringAppend(&line, inpBuf, -1);
      }
    }

    /* Done with all processing.  Clean up. */
    Tcl_DStringFree(&element);
    Tcl_DStringFree(&line);
    Tcl_Free((char *)strFiles);
  }

  if (countOnly) {
    char bCount[30];
    sprintf(bCount, "%d", matchCount);
    Tcl_ResetResult(interp);
    Tcl_AppendResult(interp, bCount);
  }
  else {
    Tcl_DStringResult(interp, &retval);
  }
  return TCL_OK;
}

int Grep_Init(interp)
Tcl_Interp *interp;
{
  Tcl_CreateCommand(interp, "grep", Grep_GrepCmd, (ClientData) 0,
		    (Tcl_CmdDeleteProc *)NULL);
  return TCL_OK;
}
