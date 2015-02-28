/* 
 * tclAppInit.c --
 *
 *	Provides main procedure and initialization of 7Script.
 * 
 *
 * 1997-1998 by David S. Herron 
 *
 */

#include "tcl.h"

/*
 * The following variable is a special hack that is needed in order for
 * Sun shared libraries to be used for Tcl.
 */

extern int matherr();
int *tclDummyMathPtr = (int *) matherr;


/*
 *----------------------------------------------------------------------
 *
 * main --
 *
 *	This is the main program for the application.
 *
 * Results:
 *	None: Tcl_Main never returns here, so this procedure never
 *	returns either.
 *
 * Side effects:
 *	Whatever the application does.
 *
 *----------------------------------------------------------------------
 */

int our_argc;
char **our_argv;

int
main(argc, argv)
    int argc;			/* Number of command-line arguments. */
    char **argv;		/* Values of command-line arguments. */
{
  extern void SevenScript_Main _ANSI_ARGS_((int argc, char **argv,
				     Tcl_AppInitProc *appInitProc));
  our_argc = argc;
  our_argv = argv;
  SevenScript_Main(argc, argv, Tcl_AppInit);
  return 0;			/* Needed only to prevent compiler warning. */
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit --
 *
 *	This procedure performs application-specific initialization.
 *	Most applications, especially those that incorporate additional
 *	packages, will have their own version of this procedure.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error
 *	message in interp->result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */


extern int Memchan_Init   _ANSI_ARGS_((Tcl_Interp *interp));
extern int Tclgdbm_Init   _ANSI_ARGS_((Tcl_Interp *interp));
extern int Tclmd5_Init    _ANSI_ARGS_((Tcl_Interp *interp));
extern int Tclpasswd_Init _ANSI_ARGS_((Tcl_Interp *interp));
extern int Cgic_Init      _ANSI_ARGS_((Tcl_Interp *interp, int argc, char **argv));
extern int SevenScript_Init      _ANSI_ARGS_((Tcl_Interp *interp));
extern int Gdtclft_Init   _ANSI_ARGS_((Tcl_Interp *interp));
#ifdef USING_MYSQL
extern int Mysqltcl_Init  _ANSI_ARGS_((Tcl_Interp *interp));
#endif

int Tcl_AppInit(interp)
Tcl_Interp *interp;		/* Interpreter for application. */
{
    if (Tcl_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }

    /*
     * Call the init procedures for included packages.  Each call should
     * look like this:
     *
     * if (Mod_Init(interp) == TCL_ERROR) {
     *     return TCL_ERROR;
     * }
     *
     * where "Mod" is the name of the module.
     */

    if (Memchan_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }

    if (Tclgdbm_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }

    if (Tclmd5_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }

    if (Tclpasswd_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }

    if (Cgic_Init(interp, our_argc, our_argv) == TCL_ERROR) {
      return TCL_ERROR;
    }

#ifdef USING_MYSQL
    if (Mysqltcl_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }
#endif
    
    if (SevenScript_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }

    if (Gdtclft_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
    }

    /*
     * Call Tcl_CreateCommand for application-specific commands, if
     * they weren't already created by the init procedures called above.
     */

    /*
     * Specify a user-specific startup file to invoke if the application
     * is run interactively.  Typically the startup file is "~/.apprc"
     * where "app" is the name of the application.  If this line is deleted
     * then no user-specific startup file will be run under any conditions.
     */

    {
      char sevenscriptrc[10240];
      sevenscriptrc[0] = '\0';
      strcpy(sevenscriptrc, SEVENSCRIPT_BASE_DIR);
      strcat(sevenscriptrc, "/lib/7scriptrc");
      Tcl_SetVar(interp, "tcl_rcFileName", sevenscriptrc, TCL_GLOBAL_ONLY);
    }

#ifdef SEVENSCRIPT_LIB_DIR
    /*
     * Specify the "7script_library" variable.
     * This variable is used by the autoloading mechanism.
     */
    Tcl_SetVar(interp, "7script_library", SEVENSCRIPT_LIB_DIR, TCL_GLOBAL_ONLY);
#endif

    return TCL_OK;
}

void SevenScript_Main(argc, argv, appInitProc)
int argc;
char **argv;
Tcl_AppInitProc *appInitProc;
{
    Tcl_Obj *prompt1NamePtr = NULL;
    Tcl_Obj *prompt2NamePtr = NULL;
    Tcl_Obj *resultPtr;
    Tcl_Obj *commandPtr = NULL;
    char *fileName;
    char  buffer[1000];
    char *args;
    char *bytes;
    int tty;
    int code, gotPartial, length;
    Tcl_Interp *interp;
    Tcl_Channel inChannel, outChannel, errChannel;
    int exitCode = 0;
    int substFile = 0;
    Tcl_DString arglist;

    Tcl_FindExecutable(argv[0]);
    interp = Tcl_CreateInterp();

    Tcl_DStringInit(&arglist);
 
    /*
     * Make command-line arguments available in the Tcl variables "argc"
     * and "argv".
     *
     * Process the command line arguments as so;
     *
     *	-7script_subst	Treat the input as if it were
     *			run through 7script_subst command.
     *			This works for the #!7script script as well.
     *
     *  First arg w/o '-'	If given, taken as file name to process.
     *
     * For "#!" scripts the argument list is {-7script_subst file_name}
     * so this loop below sees both and we still have the stdin
     * available for processing.
     *
     * For "#!" scripts where the script does not specify -7script_subst
     * the arg list is {file_name args from command line}.  In order
     * to be compatible with regular tclsh, we check for that with
     * this if before the argument scanning loop.
     * 
     */
 
    fileName = NULL;
    if ((argc > 1) && (argv[1][0] != '-')) {
        fileName = argv[1];
        argc--;
        argv++;
    }

    {
      int argno;

      for (argno = 1; argno < argc; argno++) {
	Tcl_DStringAppendElement(&arglist, &(argv[argno][0]));
	if (argv[argno][0] == '-') {
	  if (strcmp(&(argv[argno][1]), "7script_subst") == 0
	   || strcmp(&(argv[argno][1]), "snap_subst") == 0) { /* backwards compatibility */
	    substFile = 1;
	  }
	}
	else {
	  if (fileName == NULL) {
	    fileName = argv[argno];
	  }
	}
      }
    }

    Tcl_SetVar(interp, "argv", Tcl_DStringValue(&arglist), TCL_GLOBAL_ONLY);
    Tcl_DStringFree(&arglist);
    sprintf(buffer, "%d", argc-1);
    Tcl_SetVar(interp, "argc", buffer, TCL_GLOBAL_ONLY);
    Tcl_SetVar(interp, "argv0", (fileName != NULL) ? fileName : argv[0],
            TCL_GLOBAL_ONLY);
 
    /*
     * Set the "tcl_interactive" variable.
     */
 
    tty = isatty(0);
    Tcl_SetVar(interp, "tcl_interactive",
            ((fileName == NULL) && tty) ? "1" : "0", TCL_GLOBAL_ONLY);
    
    /*
     * Invoke application-specific initialization.
     */
 
    if ((*appInitProc)(interp) != TCL_OK) {
        errChannel = Tcl_GetStdChannel(TCL_STDERR);
        if (errChannel) {
            Tcl_Write(errChannel,
                    "application-specific initialization failed: ", -1);
            Tcl_Write(errChannel, interp->result, -1);
            Tcl_Write(errChannel, "\n", 1);
        }
    }
 
 
    /*
     * If a script file was specified then just source that file
     * and quit.
     */
 
    if (fileName != NULL) {
      if (substFile) {
	sprintf(buffer, "7script include %s", fileName);
	code = Tcl_Eval(interp, buffer);
      }
      else
        code = Tcl_EvalFile(interp, fileName);
      if (code != TCL_OK) {
	errChannel = Tcl_GetStdChannel(TCL_STDERR);
	if (errChannel) {
	  /*
	   * The following statement guarantees that the errorInfo
	   * variable is set properly.
	   */
	  
	  Tcl_AddErrorInfo(interp, "");
	  Tcl_Write(errChannel,
		    Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY), -1);
	  Tcl_Write(errChannel, "\n", 1);
	}
	exitCode = 1;
	goto done;
      }
      else
	goto output_result;
    }

    /*
     * We're running interactively.  Source a user-specific startup
     * file if the application specified one and if the file exists.
     */
 
    Tcl_SourceRCFile(interp);

    /*
     * Well, actually we weren't running interactively.
     * This is where we differ from the standard Tcl_Main()
     * and instead of processing the non-interactive stdin
     * as TCL commands we process it as HTML to process.
     */
    if (!tty) {
      code = Tcl_Eval(interp, "7script subst [read stdin]");
      if (code != TCL_OK) {
	errChannel = Tcl_GetStdChannel(TCL_STDERR);
	if (errChannel) {
	  /*
	   * The following statement guarantees that the errorInfo
	   * variable is set properly.
	   */
	  
	  Tcl_AddErrorInfo(interp, "");
	  Tcl_Write(errChannel,
		    Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY), -1);
	  Tcl_Write(errChannel, "\n", 1);
	}
	exitCode = 1;
      }
      else {
	extern char *SevenScript_HeaderTxt();
      output_result:

	outChannel = Tcl_GetStdChannel(TCL_STDOUT);

	if (substFile || !tty) {
	  Tcl_SetChannelOption(interp, outChannel, "-translation", "crlf");
	
	  SevenScript_HeaderMinimum();
	  Tcl_Write(outChannel, SevenScript_HeaderTxt(), -1);
	  Tcl_Write(outChannel, "\r\n", -1);
	}
	Tcl_Write(outChannel, interp->result, -1);
      }
      goto done;
    }

 
    /*
     * Process commands from stdin until there's an end-of-file.  Note
     * that we need to fetch the standard channels again after every
     * eval, since they may have been changed.
     */
 
    commandPtr = Tcl_NewObj();
    Tcl_IncrRefCount(commandPtr);
    prompt1NamePtr = Tcl_NewStringObj("tcl_prompt1", -1);
    Tcl_IncrRefCount(prompt1NamePtr);
    prompt2NamePtr = Tcl_NewStringObj("tcl_prompt2", -1);
    Tcl_IncrRefCount(prompt2NamePtr);
    
    inChannel = Tcl_GetStdChannel(TCL_STDIN);
    outChannel = Tcl_GetStdChannel(TCL_STDOUT);
    gotPartial = 0;
    while (1) {
        if (tty) {
            Tcl_Obj *promptCmdPtr;
 
            promptCmdPtr = Tcl_ObjGetVar2(interp,
                    (gotPartial? prompt2NamePtr : prompt1NamePtr),
                    (Tcl_Obj *) NULL, TCL_GLOBAL_ONLY);
            if (promptCmdPtr == NULL) {
                defaultPrompt:
                if (!gotPartial && outChannel) {
                    Tcl_Write(outChannel, "% ", 2);
                }
            } else {
                code = Tcl_EvalObj(interp, promptCmdPtr);
                inChannel = Tcl_GetStdChannel(TCL_STDIN);
                outChannel = Tcl_GetStdChannel(TCL_STDOUT);
                errChannel = Tcl_GetStdChannel(TCL_STDERR);
                if (code != TCL_OK) {
                    if (errChannel) {
                        resultPtr = Tcl_GetObjResult(interp);
                        bytes = Tcl_GetStringFromObj(resultPtr, &length);
                        Tcl_Write(errChannel, bytes, length);
                        Tcl_Write(errChannel, "\n", 1);
                    }
                    Tcl_AddErrorInfo(interp,
                            "\n    (script that generates prompt)");
                    goto defaultPrompt;
                }
            }
            if (outChannel) {
                Tcl_Flush(outChannel);
            }
        }
        if (!inChannel) {
            goto done;
        }
        length = Tcl_GetsObj(inChannel, commandPtr);
        if (length < 0) {
            goto done;
        }
        if ((length == 0) && Tcl_Eof(inChannel) && (!gotPartial)) {
            goto done;
        }
 
        /*
         * Add the newline removed by Tcl_GetsObj back to the string.
         */
 
        Tcl_AppendToObj(commandPtr, "\n", 1);
        if (!TclObjCommandComplete(commandPtr)) {
            gotPartial = 1;
            continue;
        }
 
        gotPartial = 0;
        code = Tcl_RecordAndEvalObj(interp, commandPtr, 0);
        inChannel = Tcl_GetStdChannel(TCL_STDIN);
        outChannel = Tcl_GetStdChannel(TCL_STDOUT);
        errChannel = Tcl_GetStdChannel(TCL_STDERR);
        Tcl_SetObjLength(commandPtr, 0);
        if (code != TCL_OK) {
            if (errChannel) {
                resultPtr = Tcl_GetObjResult(interp);
                bytes = Tcl_GetStringFromObj(resultPtr, &length);
                Tcl_Write(errChannel, bytes, length);
                Tcl_Write(errChannel, "\n", 1);
            }
        } else if (tty) {
            resultPtr = Tcl_GetObjResult(interp);
            bytes = Tcl_GetStringFromObj(resultPtr, &length);
            if ((length > 0) && outChannel) {
                Tcl_Write(outChannel, bytes, length);
                Tcl_Write(outChannel, "\n", 1);
            }
        }
#ifdef TCL_MEM_DEBUG
        if (quitFlag) {
            Tcl_DecrRefCount(commandPtr);
            Tcl_DecrRefCount(prompt1NamePtr);
            Tcl_DecrRefCount(prompt2NamePtr);
            Tcl_DeleteInterp(interp);
            Tcl_Exit(0);
        }
#endif
    }
 
    /*
     * Rather than calling exit, invoke the "exit" command so that
     * users can replace "exit" with some other command to do additional
     * cleanup on exit.  The Tcl_Eval call should never return.
     */
 
    done:
    if (commandPtr != NULL) {
        Tcl_DecrRefCount(commandPtr);
    }
    if (prompt1NamePtr != NULL) {
        Tcl_DecrRefCount(prompt1NamePtr);
    }
    if (prompt2NamePtr != NULL) {
        Tcl_DecrRefCount(prompt2NamePtr);
    }
    sprintf(buffer, "exit %d", exitCode);
    Tcl_Eval(interp, buffer);
}


