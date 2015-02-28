/* scan.c - HTML scanner for 7Script.
 *
 * 1997-1998 by David S. Herron 
 *
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifdef FREEBSD
#include <stdlib.h>
#else
#include <alloca.h>
#include <malloc.h>
#endif

#include <tcl.h>

static int SevenScript_SubstCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  int c;
  char *input = NULL;
  short done = 0;
  enum {
    text=0,
    inTag,
    inTagBody,
    inTagParamSeparation,
    inTagParamBody,
    inTagParamValueSep,
    inQuotedTagValue,
    inQuotedTagValueMaybeTcl,
    inQuotedTagValueMaybeTclEnd,
    inQuotedTagValueTCLCode,
    inQuotedTagValueTCLVariable,
    inQuotedTagAfterValue,
    inTCLCode,
    inTCLVarReference,
    inMaybeTclEnd
  } state;
  enum {
    afterNewline=0,
    afterRandom
  } tclState;
  char tclAppend[2];
  Tcl_DString cmdBuf;
  Tcl_DString result;
  int dousage = 0;
  int argno;
  int retval = TCL_OK;
  int nested_TCL_delimiters = 0;

  for (argno = 1; argno < argc; argno++) {
    if (argv[argno][0] != '-')
      input = &(argv[argno][0]);
    else {
#if 0
      if (strcmp(argv[argno], "-set") == 0) {
	char *varname = argv[++argno];
	char *value   = argv[++argno];

	if (!varname || !value || argno >= argc) {
	  dousage = 1;
	}
	else {
	  Tcl_SetVar(interp, varname, value, 0);
	}
      }
#endif
    }
  }

  if (dousage || !input) {
    Tcl_SetResult(interp, "USAGE: 7script subst string", TCL_STATIC);
    return TCL_ERROR;
  }

  tclAppend[0] = '\0';
  tclAppend[1] = '\0';
  Tcl_DStringInit(&cmdBuf);
  Tcl_DStringInit(&result);

  state = text;
  tclState = afterNewline;

  if (input[0] == '#' && input[1] == '!') {
    while (input[0] != '\n')
      input++;
    if (input[0] == '\n')
      input++;
  }

  for (c = (input++)[0]; !done ; c = (input++)[0]) {
    if (c == '\0') {
      done = 1;
      continue;
    }

    /*
     * Special case: Backslash handling that's going into 'result'
     * This section is transporting the HTML into 'result'.  Whether
     * we do any translation is dependant on specifics of HTML.  From
     * what I remember there isn't need for translation.
     */
    if (1 == 0) {
      char bf[5];
      unsigned long val;
    handle_backslash_result:

#if 0
      /*
       * This version does translation.  That is the following is recognized:
       *
       *  \xXX		Two HEX digits
       *  \###		Three OCTAL digits
       *  \c		One character
       *	\a    Audible alert (bell) (0x7).
       *        \b    Backspace (0x8).
       *        \f    Form feed (0xc).
       *        \n    Newline (0xa).
       *        \r    Carriage-return (0xd).
       *        \t    Tab (0x9).
       *        \v    Vertical tab (0xb).
       *        \<newline>whiteSpace
       */

      c = (input++)[0];
      switch (c) {
      case 'x':  /* hex */
	memset(bf, 0, sizeof bf);
	c = (input++)[0];   /* dig1 */
	if (c == '\0') { done = 1; continue; }
	bf[0] = c;
	c = (input++)[0];   /* dig2 */
	if (c == '\0') { done = 1; continue; }
	bf[1] = c;
	val = strtoul(bf, (char **)NULL, 16);
	c = val & 0xff;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
	
      case '0':  /* octal */
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
	bf[0] = c;  /* dig1 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	bf[1] = c;  /* dig2 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	bf[2] = c;  /* dig3 */
	val = strtoul(bf, (char **)NULL, 8);
	c = val & 0xff;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;

      default:
	switch (c) {
	case 'a': c = 0x07; break;
	case 'b': c = 0x08; break;
	case 'f': c = 0x0c; break;
	case 'n': c = ' ';  break;
	case 'r': c = 0x0d; break;
	case 't': c = 0x09; break;
	case 'v': c = 0x0b; break;
	}
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* char */
      }
      continue;
#else
      /*
       * This version does no translation and is useful for skipping
       * over backslashed text.
       */
      tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);  /* Append '\' */
      c = (input++)[0];
      switch (c) {
      case 'x':  /* hex */
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* x */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* dig1 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* dig2 */
	break;
	
      case '0':  /* octal */
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* dig1 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* dig2 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* dig3 */
	break;

      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1); /* char */
      }
      continue;
#endif
    }

    /*
     * Special case: Backslash handling that's going into 'cmdBuf'
     * This is for TCL code.
     */
    if (1 == 0) {
      char bf[5];
      unsigned long val;
    handle_backslash_cmdbuf:

#if 0
      /*
       * This version does translation.  That is the following is recognized:
       *
       *  \xXX		Two HEX digits
       *  \###		Three OCTAL digits
       *  \c		One character
       *	\a    Audible alert (bell) (0x7).
       *        \b    Backspace (0x8).
       *        \f    Form feed (0xc).
       *        \n    Newline (0xa).
       *        \r    Carriage-return (0xd).
       *        \t    Tab (0x9).
       *        \v    Vertical tab (0xb).
       *        \<newline>whiteSpace
       */

      c = (input++)[0];
      switch (c) {
      case 'x':  /* hex */
	memset(bf, 0, sizeof bf);
	c = (input++)[0];   /* dig1 */
	if (c == '\0') { done = 1; continue; }
	bf[0] = c;
	c = (input++)[0];   /* dig2 */
	if (c == '\0') { done = 1; continue; }
	bf[1] = c;
	val = strtoul(bf, (char **)NULL, 16);
	c = val & 0xff;
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
	break;
	
      case '0':  /* octal */
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
	bf[0] = c;  /* dig1 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	bf[1] = c;  /* dig2 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	bf[2] = c;  /* dig3 */
	val = strtoul(bf, (char **)NULL, 8);
	c = val & 0xff;
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
	break;

      default:
	switch (c) {
	case 'a': c = 0x07; break;
	case 'b': c = 0x08; break;
	case 'f': c = 0x0c; break;
	case 'n': c = ' ';  break;
	case 'r': c = 0x0d; break;
	case 't': c = 0x09; break;
	case 'v': c = 0x0b; break;
	}
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* char */
      }
      continue;
#else
      /*
       * This version does no translation and is useful for skipping
       * over backslashed text.
       */
      tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);  /* Append '\' */
      c = (input++)[0];
      switch (c) {
      case 'x':  /* hex */
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* x */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* dig1 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* dig2 */
	break;
	
      case '0':  /* octal */
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* dig1 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* dig2 */
	c = (input++)[0];
	if (c == '\0') { done = 1; continue; }
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* dig3 */
	break;

      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1); /* char */
      }
      continue;
#endif
    }

    switch (state) {
    case text:
      switch (c) {
      case '<':
	state = inTag;
	continue;
      case '\\':
	goto handle_backslash_result;
      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;
      
    case inTag:
      switch (c) {
      case '{':
	state = inTCLCode;
	tclState = afterRandom;
	Tcl_DStringInit(&cmdBuf);
	break;
      case '$':
	state = inTCLVarReference;
	Tcl_DStringInit(&cmdBuf);
	break;
      case '\\':
	goto handle_backslash_result;
      default:
	state = inTagBody;
	tclAppend[0] = '<';  Tcl_DStringAppend(&result, tclAppend, -1);
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;

    case inTCLVarReference:
      switch (c) {
      case '>': {
        int res;
    	/*char *val;*/
    	char cmd[1024];
    	state = text;
    	/*Tcl_DStringAppend(&result, "VarName=", -1);
    	Tcl_DStringAppend(&result, Tcl_DStringValue(&cmdBuf), -1);*/
    	sprintf(cmd, "return $%s", Tcl_DStringValue(&cmdBuf));
    	res = Tcl_Eval(interp, cmd);
    	/*val = Tcl_GetVar(interp, Tcl_DStringValue(&cmdBuf),
	     *                 TCL_LEAVE_ERR_MSG);*/
        if (res != TCL_RETURN) {
            Tcl_DStringAppend(&result,
                              "<P><B><PRE>An error occurred in processing.  "
                              "Could not access value for variable \"",
                              -1);
            Tcl_DStringAppend(&result, Tcl_DStringValue(&cmdBuf), -1);
            Tcl_DStringAppend(&result, "\";  Because: \n", -1);
            Tcl_DStringAppend(&result, interp->result, -1);
            Tcl_DStringAppend(&result, "  Stack trace: ", -1);
            Tcl_DStringAppend(&result, Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY), -1);
            Tcl_DStringAppend(&result, ".</PRE></B>\n", -1);
        }
        else {
        	/*Tcl_DStringAppend(&result, " Value=", -1);*/
            Tcl_DStringAppend(&result, interp->result, -1);
        }
        break;
      }
	
      case '\\':
        goto handle_backslash_cmdbuf;
      default:
        tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
        break;
      }
      break;
      
    case inTagBody:
      switch (c) {
      case '>':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = text;
	break;
      case '\\':
	goto handle_backslash_result;
      case ' ':
      case '\t':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = inTagParamSeparation;
	break;
      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;


    case inTagParamSeparation:
      switch (c) {
      case ' ':
      case '\t':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      case '>':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = text;
	break;
      case '\\':
	goto handle_backslash_result;
      default:
	state = inTagParamBody;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;

    case inTagParamBody:
      switch (c) {
      case ' ':
      case '\t':
	state = inTagParamSeparation;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      case '>':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = text;
	break;
      case '=':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = inTagParamValueSep;
	break;
      case '\\':
	goto handle_backslash_result;
      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;

    case inTagParamValueSep:
      switch (c) {
      case ' ':
      case '\t':   /* Actually an error */
	state = inTagParamSeparation;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      case '>':   /* Actually an error */
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = text;
	break;
      case '"':
	state = inQuotedTagValue;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      case '\\':
	goto handle_backslash_result;
      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;

    case inQuotedTagValue:
      switch (c) {
      case '<':
	state = inQuotedTagValueMaybeTcl;
	break;
      case '\\':
	goto handle_backslash_result;
      case '"':
	state = inQuotedTagAfterValue;
	/* fall through */
      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
      }
      break;

    case inQuotedTagValueMaybeTcl:
      switch (c) {
      case '{':
	state = inQuotedTagValueTCLCode;
	Tcl_DStringInit(&cmdBuf);
	break;
      case '$':
	state = inQuotedTagValueTCLVariable;
	Tcl_DStringInit(&cmdBuf);
	break;
      case '\\':
	goto handle_backslash_result;
      default:
	state = inQuotedTagValue;
	tclAppend[0] = '{';  Tcl_DStringAppend(&result, tclAppend, -1);
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;

    case inQuotedTagValueTCLVariable:
      switch (c) {
      case '>': {
        int res;
        /*char *val;*/
        char cmd[1024];
        state = inQuotedTagValue;
        /*val = Tcl_GetVar(interp, Tcl_DStringValue(&cmdBuf),
         *                 TCL_LEAVE_ERR_MSG);*/
    	sprintf(cmd, "return $%s", Tcl_DStringValue(&cmdBuf));
    	res = Tcl_Eval(interp, cmd);
        if (res != TCL_RETURN) {
            Tcl_DStringAppend(&result,
                              "ERROR:  "
                              "Could not access value for variable \"",
                              -1);
            Tcl_DStringAppend(&result, Tcl_DStringValue(&cmdBuf), -1);
            Tcl_DStringAppend(&result, "\".", -1);
        }
        else {
            Tcl_DStringAppend(&result, interp->result, -1);
        }
        break;
      }
	
      case '\\':
        goto handle_backslash_cmdbuf;
      default:
        tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
        break;
      }
      break;

    case inQuotedTagValueTCLCode:
      switch (c) {
      case '}':
	state = inQuotedTagValueMaybeTclEnd;
	break;
      case '\\':
	goto handle_backslash_cmdbuf;
      case '<':
	if (input[0] == '{') {
	  nested_TCL_delimiters++;
	}
	/* fall through */
      default:
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
	break;
      }
      break;

    case inQuotedTagValueMaybeTclEnd:
      switch (c) {
      case '>': {

	nested_TCL_delimiters--;
	if (nested_TCL_delimiters >= 0) {
	  state = inTCLCode;
	  Tcl_DStringAppend(&cmdBuf, "}>", -1);
	  continue;
	}

	state = inQuotedTagValue;
	nested_TCL_delimiters = 0;
	/*printf("subst eval %s\n", Tcl_DStringValue(&cmdBuf));*/
	switch (Tcl_Eval(interp, Tcl_DStringValue(&cmdBuf))) {
	case TCL_OK:
	case TCL_RETURN:
	  Tcl_DStringAppend(&result, interp->result, -1);
	  break;
	case TCL_BREAK:    retval = TCL_BREAK;    done = 1; break;
	case TCL_CONTINUE: retval = TCL_CONTINUE; done = 1; break;
	default:
	  /*printf("<P><B><PRE>An error occurred in processing.  TCL Code is %s\n",
	   * Tcl_GetVar(interp, "errorCode", TCL_GLOBAL_ONLY));
	   *printf("%s\n", Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY));*/
	  Tcl_DStringAppend(&result, "ERROR: ", -1);
	  Tcl_DStringAppend(&result, Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY), -1);
	  break;
	}
	Tcl_DStringInit(&cmdBuf);
	break;
      }
      case '\\':
	Tcl_DStringAppend(&cmdBuf, "}", -1);
	state = inQuotedTagValueTCLCode;
	goto handle_backslash_cmdbuf;
      default:
	Tcl_DStringAppend(&cmdBuf, "}", -1);
	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
	state = inQuotedTagValueTCLCode;
	break;
      }
      break;

    case inQuotedTagAfterValue:
      switch (c) {
      case ' ':
      case '\t':
	state = inTagParamSeparation;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      case '>':
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	state = text;
	break;
      case '\\':
	goto handle_backslash_result;
      default:
	state = inTagParamBody;
	tclAppend[0] = c;    Tcl_DStringAppend(&result, tclAppend, -1);
	break;
      }
      break;

    case inTCLCode:
      switch (c) {
      case '}':
    	state = inMaybeTclEnd;
    	break;
      case '\\':
    	goto handle_backslash_cmdbuf;
      case '<':
    	if (input[0] == '{') {
    	  nested_TCL_delimiters++;
    	}
    	/* fall through */
      default:
    	tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
    	break;
      }
      break;

    case inMaybeTclEnd:
      switch (c) {
      case '>': {

    	nested_TCL_delimiters--;
    	if (nested_TCL_delimiters >= 0) {
    	  state = inTCLCode;
    	  Tcl_DStringAppend(&cmdBuf, "}>", -1);
    	  continue;
    	}

    	state = text;
    	nested_TCL_delimiters = 0;
    	/*printf("subst eval %s\n", Tcl_DStringValue(&cmdBuf));*/
    	switch (Tcl_Eval(interp, Tcl_DStringValue(&cmdBuf))) {
    	case TCL_OK:
    	case TCL_RETURN:
    	  Tcl_DStringAppend(&result, interp->result, -1);
    	  break;
        case TCL_BREAK:    retval = TCL_BREAK;    done = 1; break;
        case TCL_CONTINUE: retval = TCL_CONTINUE; done = 1; break;
    	default:
    	  Tcl_DStringAppend(&result,
    			    "<P><B><PRE>An error occurred in processing.  TCL Code is ",
    			    -1);
    	  Tcl_DStringAppend(&result,
    			    Tcl_GetVar(interp, "errorCode", TCL_GLOBAL_ONLY),
    			    -1);
    	  Tcl_DStringAppend(&result, "\n<BR>", -1);
    	  Tcl_DStringAppend(&result,
    			    Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY),
    			    -1);
    	  Tcl_DStringAppend(&result, "\n</PRE></b>\n", -1);
    
    	  /*printf("<P><B><PRE>An error occurred in processing.  TCL Code is %s\n",
    	   * Tcl_GetVar(interp, "errorCode", TCL_GLOBAL_ONLY));
    	   * printf("%s\n", Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY));*/
    	  break;
    	}
    	Tcl_DStringInit(&cmdBuf);
    	break;
      }
      case '\\':
    	Tcl_DStringAppend(&cmdBuf, "}", -1);
    	state = inTCLCode;
	    goto handle_backslash_cmdbuf;
      default:
    	Tcl_DStringAppend(&cmdBuf, "}", -1);
	    tclAppend[0] = c;    Tcl_DStringAppend(&cmdBuf, tclAppend, -1);
    	state = inTCLCode;
	    break;
      }
      break;

    default:
      break;
    }
  }

  Tcl_SetResult(interp, Tcl_DStringValue(&result), TCL_VOLATILE);

  Tcl_DStringFree(&cmdBuf);
  Tcl_DStringFree(&result);

  return retval;
}

static int SevenScript_ForeachCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  char   *varname = argv[1];
  int     nParams;
  char   **lParams;
  int      res;
  char    *val;
  int      valNum;
  char    *script;
  Tcl_DString ret;
  int      tcl_result;

  if (argc != 4) {
	Tcl_AppendResult(interp, "Incorrect number of args in '7script foreach'", 0);
	return TCL_ERROR;
  }

  if (!varname) {
	Tcl_AppendResult(interp, "No loop variable given in '7script foreach'", 0);
	return TCL_ERROR;
  }

  if (!argv[2]) {
    noParams:
	Tcl_AppendResult(interp, "No values given in '7script foreach'", 0);
	return TCL_ERROR;
  }

  script = argv[3];
  if (!script) {
	Tcl_AppendResult(interp, "No script given in '7script foreach'", 0);
	return TCL_ERROR;
  }

  res = Tcl_SplitList(interp, argv[2], &nParams, &lParams);
  if (res != TCL_OK) {
	goto noParams;
  }

  Tcl_DStringInit(&ret);

  for (valNum = 0; valNum < nParams; valNum++) {
	int             passed_argc = 2;
	char           *passed_argv[3];

	val = lParams[valNum];

	if (Tcl_SetVar(interp, varname, val, 0) == NULL) {
	    Tcl_DStringAppend(&ret, "<B>Could not set  ", -1);
	    Tcl_DStringAppend(&ret, varname, -1);
	    Tcl_DStringAppend(&ret, " to ", -1);
	    Tcl_DStringAppend(&ret, val, -1);
	    Tcl_DStringAppend(&ret, " because: ", -1);
	    Tcl_DStringAppend(&ret, interp->result, -1);
	    Tcl_DStringAppend(&ret, "</b>.\n", -1);
	    continue;
	}


	passed_argv[0] = "7script_subst";
	passed_argv[1] = script;

	tcl_result = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);

	if (tcl_result != TCL_OK) {
	    Tcl_DStringAppend(&ret, "<B>Iteration for ", -1);
	    Tcl_DStringAppend(&ret, varname, -1);
	    Tcl_DStringAppend(&ret, "=", -1);
	    Tcl_DStringAppend(&ret, val, -1);
	    Tcl_DStringAppend(&ret, " failed because: ", -1);
	    Tcl_DStringAppend(&ret, interp->result, -1);
	    Tcl_DStringAppend(&ret, "</b>.\n", -1);
	    continue;
	}

	Tcl_DStringAppend(&ret, interp->result, -1);
  }


  Tcl_Free((char *) lParams);
  Tcl_DStringResult(interp, &ret);
  return TCL_OK;
}

static int SevenScript_ForCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
    char *init;
    char *test;
    char *iter;
    char *cmd;
    int   res;
    int   bool;
	int   passed_argc = 2;
	char *passed_argv[3];
    Tcl_DString ret;
    
    /* 7script (for) init test iter cmd */
    if (argc != 5) {
        Tcl_AppendResult(interp, "USAGE: 7script for init test iter cmd", 0);
        return TCL_ERROR;
    }
    
    init = argv[1];
    test = argv[2];
    iter = argv[3];
    cmd  = argv[4];
    
	passed_argv[0] = "7script_subst";
	passed_argv[1] = cmd;
	
    Tcl_DStringInit(&ret);
    
    res = Tcl_Eval(interp, init);
    if (res != TCL_OK) {
        Tcl_AppendResult(interp, "\n\tin '7script for' initialization", 0);
        return res;
    }
    
  testit:
    res = Tcl_ExprBoolean(interp, test, &bool);
	switch (res) {
	case TCL_OK:        break;
	case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script for' evaluation", 0);
	                    goto finish;
	}
    
    if (!bool) goto finish;
    
	res = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);
	switch (res) {
	case TCL_OK:        break;
	case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script for' body evaluation", 0);
	                    goto finish;
	case TCL_RETURN:    goto finish;
	case TCL_BREAK:     goto finish;
	case TCL_CONTINUE:  break;
	}
	
	Tcl_DStringAppend(&ret, interp->result, -1);
	
	res = Tcl_Eval(interp, iter);
	switch (res) {
	case TCL_OK:        break;
	case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script for' incrementor evaluation", 0);
	                    goto finish;
	case TCL_RETURN:    goto finish;
	case TCL_BREAK:     goto finish;
	case TCL_CONTINUE:  break;
	}
	
	goto testit;
	
  finish:
    if (res == TCL_OK) {
        Tcl_DStringResult(interp, &ret);
    }
    else {
        Tcl_DStringFree(&ret);
    }
    return res;
}

static int SevenScript_WhileCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
    char *test;
    char *cmd;
    int   res;
    int   bool;
    int   passed_argc = 2;
    char *passed_argv[3];
    Tcl_DString ret;
    
    /* 7script (while) test cmd */
    if (argc != 3) {
        Tcl_AppendResult(interp, "USAGE: 7script while test cmd", 0);
        return TCL_ERROR;
    }
    
    test = argv[1];
    cmd  = argv[2];
    
    passed_argv[0] = "7script_subst";
    passed_argv[1] = cmd;
	
    Tcl_DStringInit(&ret);
    
  testit:
    res = Tcl_ExprBoolean(interp, test, &bool);
    switch (res) {
    case TCL_OK:        break;
    case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script while' evaluation", 0);
	                goto finish;
    }
    
    if (!bool) goto finish;
    
    res = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);
    switch (res) {
    case TCL_OK:        break;
    case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script while' body evaluation", 0);
	                goto finish;
    case TCL_RETURN:    goto finish;
    case TCL_BREAK:     goto finish;
    case TCL_CONTINUE:  break;
    }
	
    Tcl_DStringAppend(&ret, interp->result, -1);
    goto testit;
	
  finish:
    if (res == TCL_OK) {
        Tcl_DStringResult(interp, &ret);
    }
    else {
        Tcl_DStringFree(&ret);
    }
    return res;    
}

static int SevenScript_IfCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
    char *test;
    char *cmd;
    int   indexTest;
    int   indexCommand;
    int   res;
    int   bool;
    int   passed_argc = 2;
    char *passed_argv[3];
    Tcl_DString ret;
    
    /* 7script if test true-part elseif test true-part else false-part */
    if (argc < 3) {
    
      usage:
      
        Tcl_AppendResult(interp,
            "USAGE: 7script if test true-part elseif test true-part else false-part",
            0);
        return TCL_ERROR;
    }
    
    passed_argv[0] = "7script_subst";
    passed_argv[1] = (char *)0;
	
    Tcl_DStringInit(&ret);
    
    indexTest    = 1;
    indexCommand = 2;

  testit:
    test = argv[indexTest];
    res = Tcl_ExprBoolean(interp, test, &bool);
    /*printf("TEST: [%d]%s res=%d bool=%d\n", indexTest, test, res, bool);*/
   	switch (res) {
	case TCL_OK:        break;
	case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script if' evaluation", 0);
	                    goto finish;
	}
	
    if (!bool) {
        indexTest += 2;
        /*printf("FAIL\n");*/
        if (indexTest >= argc) {
            /*printf("Ran out of arguments - indexTest=%d, argc=%d\n",
             *   indexTest, argc);
             */
            goto finish;
        }
            
        if ((argv[indexTest][0] == 'e' || argv[indexTest][0] == 'E')
         && (argv[indexTest][1] == 'l' || argv[indexTest][1] == 'L')
         && (argv[indexTest][2] == 's' || argv[indexTest][2] == 'S')
         && (argv[indexTest][3] == 'e' || argv[indexTest][3] == 'E')) {
            if (argv[indexTest][4] == '\0') {
                indexCommand = indexTest + 1;
                /*printf("handle else, indexCommand=%d\n", indexCommand);*/
                goto runCommand;
            }
            else if ((argv[indexTest][4] == 'i' || argv[indexTest][4] == 'I')
                  && (argv[indexTest][5] == 'f' || argv[indexTest][5] == 'F')) {
                indexTest += 1;
                /*printf("handle elseif, indexTest=%d\n", indexTest);*/
                goto testit;
            }
            else {
                /*printf("Unknown thing in else part: %s\n", argv[indexTest]);*/
                goto usage;
            }
        }
    }
    else {
        indexCommand = indexTest + 1;
        goto runCommand;
    }
    
  runCommand:
    if (indexCommand >= argc)
        goto usage;
        
    passed_argv[1] = argv[indexCommand];
    res = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);
    /*printf("run command [%d] %s, res=%d, return=%s\n",
     *   indexCommand, argv[indexCommand], res, interp->result);*/
    switch (res) {
    case TCL_OK:        break;
    case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script if' body evaluation", 0);
                        goto finish;
    case TCL_RETURN:    goto finish;
    case TCL_BREAK:     goto finish;
    case TCL_CONTINUE:  break;
    }
	
  finish:
    /*printf("FINISH res=%d\n", res);*/
    if (res == TCL_OK) {
        /*Tcl_DStringResult(interp, &ret);*/
    }
    else {
        Tcl_DStringFree(&ret);
    }
    return res;    
}

static int SevenScript_SwitchCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
#define EXACT	0
#define GLOB	1
#define REGEXP	2
    int i, code, mode, matched;
    int body;
    char *string;
    int switchArgc, splitArgs;
    char **switchArgv;
    int   passed_argc = 2;
    char *passed_argv[3];
    Tcl_DString ret;
    int   use_exact  = 0;
    int   use_glob   = 0;
    int   use_regexp = 0;

    /* 7script switch ?options? string {pattern body ...} */

#if 0
    if (argc < 3) {
    usage:

      Tcl_AppendResult(interp,
		       "USAGE: 7script switch ?options? string {pattern body ...}", 0);
      return TCL_ERROR;
    }
#endif

    passed_argv[0] = "7script_subst";
    passed_argv[1] = (char *)0;
	
    Tcl_DStringInit(&ret);

    switchArgc = argc-1;
    switchArgv = argv+1;
    mode = EXACT;
    while ((switchArgc > 0) && (*switchArgv[0] == '-')) {
	if (strcmp(*switchArgv, "-exact") == 0) {
	    mode = EXACT;
	} else if (strcmp(*switchArgv, "-glob") == 0) {
	    mode = GLOB;
	} else if (strcmp(*switchArgv, "-regexp") == 0) {
	    mode = REGEXP;
	} else if (strcmp(*switchArgv, "--") == 0) {
	    switchArgc--;
	    switchArgv++;
	    break;
	} else {
	    Tcl_AppendResult(interp, "bad option \"", switchArgv[0],
		    "\": should be -exact, -glob, -regexp, or --",
		    (char *) NULL);
	    return TCL_ERROR;
	}
	switchArgc--;
	switchArgv++;
    }
    if (switchArgc < 2) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		argv[0], " ?switches? string pattern body ... ?default body?\"",
		(char *) NULL);
	return TCL_ERROR;
    }
    string = *switchArgv;
    switchArgc--;
    switchArgv++;

    /*
     * If all of the pattern/command pairs are lumped into a single
     * argument, split them out again.
     */

    splitArgs = 0;
    if (switchArgc == 1) {
	code = Tcl_SplitList(interp, switchArgv[0], &switchArgc, &switchArgv);
	if (code != TCL_OK) {
	    return code;
	}
	splitArgs = 1;
    }

    for (i = 0; i < switchArgc; i += 2) {
	if (i == (switchArgc-1)) {
	    interp->result = "extra switch pattern with no body";
	    code = TCL_ERROR;
	    goto cleanup;
	}

	/*
	 * See if the pattern matches the string.
	 */

	matched = 0;
	if ((*switchArgv[i] == 'd') && (i == switchArgc-2)
		&& (strcmp(switchArgv[i], "default") == 0)) {
	    matched = 1;
	} else {
	    switch (mode) {
		case EXACT:
		    matched = (strcmp(string, switchArgv[i]) == 0);
		    break;
		case GLOB:
		    matched = Tcl_StringMatch(string, switchArgv[i]);
		    break;
		case REGEXP:
		    matched = Tcl_RegExpMatch(interp, string, switchArgv[i]);
		    if (matched < 0) {
			code = TCL_ERROR;
			goto cleanup;
		    }
		    break;
	    }
	}
	if (!matched) {
	    continue;
	}

	/*
	 * We've got a match.  Find a body to execute, skipping bodies
	 * that are "-".
	 */

	for (body = i+1; ; body += 2) {
	    if (body >= switchArgc) {
		Tcl_AppendResult(interp, "no body specified for pattern \"",
			switchArgv[i], "\"", (char *) NULL);
		code = TCL_ERROR;
		goto cleanup;
	    }
	    if ((switchArgv[body][0] != '-') || (switchArgv[body][1] != 0)) {
		break;
	    }
	}

	passed_argv[1] = switchArgv[body];
	code = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);

	if (code == TCL_ERROR) {
	    char msg[100];
	    sprintf(msg, "\n    (\"%.50s\" arm line %d)", switchArgv[i],
		    interp->errorLine);
	    Tcl_AddErrorInfo(interp, msg);
	}
	goto cleanup;
    }

    /*
     * Nothing matched:  return nothing.
     */

    code = TCL_OK;

    cleanup:
    if (splitArgs) {
	ckfree((char *) switchArgv);
    }
    return code;

}

static int SevenScript_ConcatCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
    int   argno;
    int   res;
    int   passed_argc = 2;
    char *passed_argv[3];
    Tcl_DString ret;

    /* 7script (concat) txt txt ... */
    if (argc < 2) {
        Tcl_AppendResult(interp, "USAGE: 7script concat cmd ...", 0);
	return TCL_ERROR;
    }

    passed_argv[0] = "7script_subst";
    passed_argv[1] = NULL;
    passed_argv[2] = NULL;
	
    Tcl_DStringInit(&ret);

    for (argno = 1; argno < argc; argno++) {
      passed_argv[1] = argv[argno];
      res = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);
      Tcl_DStringAppend(&ret, interp->result, -1);
      switch (res) {
      case TCL_OK:        break;
      case TCL_ERROR:     Tcl_AppendResult(interp, "\n\tin '7script concat' body evaluation", 0);
	                  goto finish;
      case TCL_RETURN:    goto finish;
      case TCL_BREAK:     goto finish;
      case TCL_CONTINUE:  break;
      }
    }

 finish:

    if (res == TCL_OK) {
        Tcl_DStringResult(interp, &ret);
    }
    else {
        Tcl_DStringFree(&ret);
    }
    return res;    
}


typedef struct {
  Tcl_DString name;
  int         hasDefault;
  Tcl_DString defVal;
} _7script_arg;

typedef struct {
  Tcl_Interp  *interp;
  Tcl_DString  name;
  _7script_arg    *arglist;  /* Array of 'numargs' elements */
  int          numargs;
  Tcl_DString  body;
} _7script_template;

static int SevenScript_TemplateDoCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  _7script_template *tmpl = (_7script_template *)dummy;
  char           *body = Tcl_DStringValue(&(tmpl->body));
  int             paramNum;
  int             argNum;
  int             passed_argc = 2;
  char           *passed_argv[3];
  Tcl_CallFrame   frame;
  int             tcl_result = TCL_OK;
  Tcl_CmdInfo     cmdInfo;

  memset(&cmdInfo, 0, sizeof cmdInfo);
  Tcl_GetCommandInfo(interp, argv[0], &cmdInfo);

  memset(&frame, 0, sizeof frame);
  Tcl_PushCallFrame(interp, &frame, cmdInfo.namespacePtr, 1);

  argNum = 1;  /* skip first arg - function name */
  for (paramNum = 0; paramNum < tmpl->numargs; paramNum++) {
    _7script_arg *argdesc = &(tmpl->arglist[paramNum]);
    if (argNum < argc) {
      if (Tcl_SetVar(interp, Tcl_DStringValue(&(argdesc->name)), argv[argNum++], 0) == NULL) {
	Tcl_AppendResult(interp, "Could not set parameter '",
			 Tcl_DStringValue(&(argdesc->name)),
			 "' to value '", argv[argNum++],
			 "' in template '",
			 argv[0], "'",  0);
	tcl_result = TCL_ERROR;
	goto leave;
      }
    }
    else {
      if (argdesc->hasDefault) {
	if (Tcl_SetVar(interp,
		       Tcl_DStringValue(&(argdesc->name)),
		       Tcl_DStringValue(&(argdesc->defVal)),
		       0) == NULL) {
	  Tcl_AppendResult(interp,
			   "Could not set parameter '",
			   Tcl_DStringValue(&(argdesc->name)),
			   "' to default value '",
			   Tcl_DStringValue(&(argdesc->defVal)),
			   "' in template '",
			   argv[0], "'", 
			   0);
	  tcl_result = TCL_ERROR;
	  goto leave;
	}
      }
      else {
	Tcl_AppendResult(interp, "No value provided for parameter '",
			 Tcl_DStringValue(&(argdesc->name)),
			 "' in template '",
			 argv[0], "'", 0);
	tcl_result = TCL_ERROR;
	goto leave;
      }
    }
  }

  if (argNum < argc) {
    Tcl_AppendResult(interp, "Too many arguments provided for template ", argv[0], 0);
    tcl_result = TCL_ERROR;
    goto leave;
  }

  passed_argv[0] = "7script_subst";
  passed_argv[1] = body;

  tcl_result = SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);

leave:
  Tcl_PopCallFrame(interp);

  return tcl_result;
}

static void SevenScript_TemplateDeleteCmd(dummy)
ClientData   dummy;
{
  _7script_template *tmpl = (_7script_template *)dummy;
  int i;

  Tcl_DStringFree(&(tmpl->name));

  for (i = 0; i < tmpl->numargs; i++) {
    Tcl_DStringFree(&(tmpl->arglist[i].name));
    if (tmpl->arglist[i].hasDefault)
      Tcl_DStringFree(&(tmpl->arglist[i].defVal));
  }
  free(tmpl->arglist);

  Tcl_DStringFree(&(tmpl->body));
  free(tmpl);

  return;
}

static int SevenScript_TemplateCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  _7script_template *tmpl = NULL;
  int             i;
  int             nParams;
  char          **lParams;
  int             res;

  if (argc != 4) {
    Tcl_SetResult(interp, "USAGE: 7script_template name arg-list body", TCL_STATIC);
    return TCL_ERROR;
  }

  tmpl = calloc(1, sizeof (_7script_template));
  if (!tmpl) {
    Tcl_AppendResult(interp, "Out of memory", 0);
    return TCL_ERROR;
  }

  tmpl->interp = interp;
  Tcl_DStringInit(&(tmpl->name));
  Tcl_DStringAppend(&(tmpl->name), argv[1], -1);

  /*  Tcl_DStringInit(&(tmpl->arglist));
   *Tcl_DStringAppend(&(tmpl->arglist), argv[2], -1);*/
  res = Tcl_SplitList(interp, argv[2], &nParams, &lParams);
  if (res != TCL_OK) {
    Tcl_AppendResult(interp,
		     "Bad argument specification '",
		     argv[2], "' list in template '", argv[1], "'.", 0);

  procError:
    if (lParams) Tcl_Free((char *)lParams);
    Tcl_DStringFree(&(tmpl->name));
    Tcl_DStringFree(&(tmpl->body));
    free(tmpl);
    return TCL_ERROR;
  }

  tmpl->arglist = calloc(nParams+1, sizeof(_7script_arg));
  if (!tmpl->arglist) {
    Tcl_AppendResult(interp, "Out of memory", 0);
    goto procError;
  }
    
  tmpl->numargs = nParams;

  for (i = 0; i < nParams; i++) {

    int    fieldCount;
    char **fieldValues;
    int    res;

    res = Tcl_SplitList(interp, lParams[i], &fieldCount, &fieldValues);

    Tcl_DStringInit(&(tmpl->arglist[i].name));
    Tcl_DStringAppend(&(tmpl->arglist[i].name), fieldValues[0], -1);
    switch (fieldCount) {
    case 2:
      tmpl->arglist[i].hasDefault = 1;
      Tcl_DStringInit(&(tmpl->arglist[i].defVal));
      Tcl_DStringAppend(&(tmpl->arglist[i].defVal), fieldValues[1], -1);
      break;
    case 1:
      tmpl->arglist[i].hasDefault = 0;
      break;
    default:
      Tcl_AppendResult(interp, "Badly formed argument specification '",
		       lParams[i], "' in template '", argv[1], "'.",
		       "  Argument list '", argv[2], "'.", 0);
      goto procError;
    }

    Tcl_Free((char *)fieldValues);
  }
  Tcl_Free((char *)lParams);

  Tcl_DStringInit(&(tmpl->body));
  Tcl_DStringAppend(&(tmpl->body), argv[3], -1);

  (void)Tcl_CreateCommand(interp, argv[1], SevenScript_TemplateDoCmd, tmpl, SevenScript_TemplateDeleteCmd);

  return TCL_OK;
}

static int SevenScript_IncludeCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  int passed_argc = 2;
  char *passed_argv[3];
  int fd;
  struct stat stbuf;
  int stres;
  char *file;

  if (argc != 2) {
    Tcl_SetResult(interp, "USAGE: 7script include file", TCL_STATIC);
    return TCL_ERROR;
  }

  file = argv[1];

  stres = stat(file, &stbuf);
  if (stres < 0) {
    Tcl_ResetResult(interp);
    Tcl_AppendResult(interp, "File ", file, " does not exist.", 0);
    return TCL_ERROR;
  }
  passed_argv[0] = "7script_subst";
  passed_argv[1] = alloca(stbuf.st_size + 10);
  memset(passed_argv[1], 0, stbuf.st_size + 10);
  fd = open(file, O_RDONLY);
  if (fd < 0) {
    Tcl_AppendResult(interp, "File ", file, " cannot be opened for reading.", 0);
    return TCL_ERROR;
  }
  if (read(fd, passed_argv[1], stbuf.st_size) != stbuf.st_size) {
    Tcl_AppendResult(interp, "File ", file, " cannot be read.", 0);
    return TCL_ERROR;
  }
  close(fd);
  
  return SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);
}

static Tcl_DString header;
static int         header_init = 0;
static int         saw_content_type = 0;

void SevenScript_HeaderInit()
{
  if (!header_init) {
    Tcl_DStringInit(&header);
    /*    Tcl_DStringAppend(&header, "X-HTML-Generated-By: 7Script v1.0\r\n", -1);*/
    header_init = 1;
  }
}

static int SevenScript_HeaderCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  int argno;

  if (argc < 2) {
    Tcl_AppendResult(interp, "USAGE: 7script header tag val ?val? ...", 0);
    return TCL_ERROR;
  }

  SevenScript_HeaderInit();

  Tcl_DStringAppend(&header, argv[1], -1);
  Tcl_DStringAppend(&header, ": ", -1);
  Tcl_DStringAppend(&header, argv[2], -1);
  Tcl_DStringAppend(&header, "\r\n", -1);
  for (argno = 3; argno < argc; argno++) {
    Tcl_DStringAppend(&header, "        ", -1);
    Tcl_DStringAppend(&header, argv[argno], -1);
    Tcl_DStringAppend(&header, "\r\n", -1);
  }

  return TCL_OK;
}

void SevenScript_HeaderMinimum()
{
  SevenScript_HeaderInit();
  if (!saw_content_type) {
    Tcl_DStringAppend(&header, "Content-Type: text/html\r\n", -1);
    saw_content_type = 1;
  }
}

char *SevenScript_HeaderTxt()
{
  SevenScript_HeaderInit();
  return Tcl_DStringValue(&header);
}

static int SevenScript_HeaderTextCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  int argno;

  if (argc < 2) {
    Tcl_AppendResult(interp, "USAGE: 7script headertext", 0);
    return TCL_ERROR;
  }

  Tcl_SetResult(interp, SevenScript_HeaderTxt(), TCL_VOLATILE);
  return TCL_OK;
}

static int SevenScript_HashCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
    int i;
    int c;
    int len;
    short sum;

    if (argc != 2) {
        Tcl_AppendResult(interp, "USAGE: 7script hash string", 0);
        return TCL_ERROR;
    }

    
    for (len = strlen(argv[1]), i = 0, sum = 0;
         i < len;
         i++) {
         
         sum += argv[1][i];
    }

    sprintf(interp->result, "%d", sum);
    return TCL_OK;
}

static int SevenScript_MainCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  int passed_argc;
  char **passed_argv;
  int argno;
  char *whichCmd = argv[1];

  passed_argv = alloca((argc + 1) * sizeof (char *));
  memset(passed_argv, 0, (argc + 1) * sizeof (char *));

  for (passed_argc = 0, argno = 0; argno < argc; argno++) {
    if (argno != 1) {
      passed_argv[passed_argc] = argv[argno];
      passed_argc++;
    }
  }
  
  if (!argv[1]) {
    Tcl_AppendResult(interp, "USAGE: 7script cmd arg ?arg?", 0);
    return TCL_ERROR;
  }
  else if (strcmp(argv[1], "body") == 0 || strcmp(argv[1], "subst") == 0) {
    return SevenScript_SubstCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "foreach") == 0) {
    return SevenScript_ForeachCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "for") == 0) {
    return SevenScript_ForCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "while") == 0) {
    return SevenScript_WhileCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "if") == 0) {
    return SevenScript_IfCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "switch") == 0) {
    return SevenScript_SwitchCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "concat") == 0) {
    return SevenScript_ConcatCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "include") == 0) {
    return SevenScript_IncludeCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "template") == 0) {
    return SevenScript_TemplateCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "header") == 0) {
    return SevenScript_HeaderCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "headertext") == 0) {
    return SevenScript_HeaderTextCmd(dummy, interp, passed_argc, passed_argv);
  }
  else if (strcmp(argv[1], "hash") == 0) {
    return SevenScript_HashCmd(dummy, interp, passed_argc, passed_argv);
  }
  else {
    Tcl_AppendResult(interp, "Unknown command ", argv[1], 0);
    return TCL_ERROR;
  }
}



extern int SevenScript_ParseTclCmd(ClientData dummy,
                            Tcl_Interp  *interp,
                            int          argc,
                            char       **argv);

int SevenScript_Init(interp)
Tcl_Interp *interp;
{
/*  Tcl_CreateCommand(interp, "7script_subst", SevenScript_SubstCmd, (ClientData) 0,
 *		    (Tcl_CmdDeleteProc *)NULL);
 *  Tcl_CreateCommand(interp, "7script_include", SevenScript_IncludeCmd, (ClientData) 0,
 *		    (Tcl_CmdDeleteProc *)NULL);
 *  Tcl_CreateCommand(interp, "7script_template", SevenScript_TemplateCmd, (ClientData) 0,
 *		    (Tcl_CmdDeleteProc *)NULL);
 */
  /* The 'snap' version is still here for backwards
   * compatibility with the old product name.
   */
  Tcl_CreateCommand(interp, "snap", SevenScript_MainCmd, (ClientData) 0,
		    (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateCommand(interp, "7script", SevenScript_MainCmd, (ClientData) 0,
		    (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateCommand(interp, "tcl-parse", SevenScript_ParseTclCmd, (ClientData) 0,
		    (Tcl_CmdDeleteProc *)NULL);
  return TCL_OK;
}
