/* Parse out a TCL script from a string 
 * THIS IS AN EXPERIMENTAL PART OF 7Script.
 *
 * 1997-1998 by David S. Herron 
 *
 */

/* The following is the syntax description - as of TCL v8.0.  The syntax is
 * listed in the Tcl(n) man page.
 *
 * DESCRIPTION
 *      The following rules define the syntax and semantics  of  the
 *      Tcl language:
 *  
 *      [1]  A Tcl script is a string containing one  or  more  com-
 *           mands.  Semi-colons and newlines are command separators
 *           unless quoted as described below.  Close  brackets  are
 *           command  terminators  during  command substitution (see
 *           below) unless quoted.
 *  
 *      [2]  A command is evaluated in two steps.   First,  the  Tcl
 *           interpreter  breaks the command into words and performs
 *           substitutions as described below.  These  substitutions
 *           are  performed  in  the same way for all commands.  The
 *           first word is used to locate  a  command  procedure  to
 *           carry  out  the  command,  then all of the words of the
 *           command are passed to the command procedure.  The  com-
 *           mand  procedure  is free to interpret each of its words
 *           in any way it likes, such as an integer, variable name,
 *           list,  or  Tcl  script.   Different  commands interpret
 *           their words differently.
 *  
 *      [3]  Words of a command are separated by white space (except
 *           for newlines, which are command separators).
 *  
 *      [4]  If the  first  character  of  a  word  is  double-quote
 *           (``"'')  then  the  word  is  terminated  by  the  next
 *           double-quote character.  If semi-colons,  close  brack-
 *           ets,  or  white  space  characters (including newlines)
 *           appear between the quotes  then  they  are  treated  as
 *           ordinary  characters and included in the word.  Command
 *           substitution, variable substitution, and backslash sub-
 *           stitution  are  performed on the characters between the
 *           quotes as described below.  The double-quotes  are  not
 *           retained as part of the word.
 *  
 *      [5]  If the first character of  a  word  is  an  open  brace
 *           (``{'')  then  the  word  is terminated by the matching
 *           close brace (``}'').  Braces nest within the word:  for
 *           each  additional open brace there must be an additional
 *           close brace (however, if an open brace or  close  brace
 *           within  the  word is quoted with a backslash then it is
 *           not counted in locating the matching close brace).   No
 *           substitutions  are  performed on the characters between
 *           the braces except for  backslash-newline  substitutions
 *           described  below,  nor  do semi-colons, newlines, close
 *           brackets, or white space receive any special  interpre-
 *           tation.   The  word will consist of exactly the charac-
 *           ters between the outer braces, not including the braces
 *           themselves.
 *  
 *      [6]  If a word contains an open  bracket  (``['')  then  Tcl
 *           performs  command  substitution.  To do this it invokes
 *           the Tcl interpreter recursively to process the  charac-
 *           ters  following  the open bracket as a Tcl script.  The
 *           script may contain any number of commands and  must  be
 *           terminated  by  a close bracket (``]'').  The result of
 *           the script (i.e. the result of  its  last  command)  is
 *           substituted  into the word in place of the brackets and
 *           all of the characters between them.  There may  be  any
 *           number of command substitutions in a single word.  Com-
 *           mand substitution is not performed on words enclosed in
 *           braces.
 *  
 *      [7]  If a word contains a dollar-sign (``$'') then Tcl  per-
 *           forms  variable  substitution:  the dollar-sign and the
 *           following characters are replaced in the  word  by  the
 *           value  of  a  variable.  Variable substitution may take
 *           any of the following forms:
 *  
 *           $name          Name is the name of a  scalar  variable;
 *                          the  name is terminated by any character
 *                          that isn't a letter,  digit,  or  under-
 *                          score.
 *  
 *           $name(index)   Name gives the name of an array variable
 *                          and  index  gives the name of an element
 *                          within that array.   Name  must  contain
 *                          only  letters,  digits, and underscores.
 *                          Command substitutions, variable  substi-
 *                          tutions, and backslash substitutions are
 *                          performed on the characters of index.
 *  
 *           ${name}        Name is the name of a  scalar  variable.
 *                          It may contain any characters whatsoever
 *                          except for close braces.
 *  
 *           There may be any number of variable substitutions in  a
 *           single word.  Variable substitution is not performed on
 *           words enclosed in braces.
 *   
 *      [8]  If a backslash  (``\'')  appears  within  a  word  then
 *           backslash  substitution occurs.  In all cases but those
 *           described below the backslash is dropped and  the  fol-
 *           lowing  character  is  treated as an ordinary character
 *           and included in the word.  This allows characters  such
 *           as  double  quotes, close brackets, and dollar signs to
 *           be included in words without  triggering  special  pro-
 *           cessing.   The  following  table  lists  the  backslash
 *           sequences that are handled specially,  along  with  the
 *           value that replaces each sequence.
 *  
 *           \a    Audible alert (bell) (0x7).
 *  
 *           \b    Backspace (0x8).
 *  
 *           \f    Form feed (0xc).
 *  
 *           \n    Newline (0xa).
 *  
 *           \r    Carriage-return (0xd).
 *  
 *           \t    Tab (0x9).
 *  
 *           \v    Vertical tab (0xb).
 *  
 *           \<newline>whiteSpace
 *                 A single space character replaces the  backslash,
 *                 newline,  and  all spaces and tabs after the new-
 *                 line.  This backslash sequence is unique in  that
 *                 it  is replaced in a separate pre-pass before the
 *                 command is actually parsed.  This means  that  it
 *                 will  be  replaced  even  when  it occurs between
 *                 braces, and the resulting space will  be  treated
 *                 as  a  word  separator  if  it isn't in braces or
 *                 quotes.
 *  
 *           \\    Backslash (``\'').
 *  
 *           \ooo  The digits ooo (one, two, or three of them)  give
 *                 the octal value of the character.
 *  
 *           \xhh  The hexadecimal digits hh  give  the  hexadecimal
 *                 value of the character.  Any number of digits may
 *                 be present.
 *  
 *           Backslash  substitution  is  not  performed  on   words
 *           enclosed  in  braces,  except  for backslash-newline as
 *           described above.
 * 
 *      [9]  If a hash character (``#'') appears at  a  point  where
 *           Tcl  is expecting the first character of the first word
 *           of a command, then the hash character and  the  charac-
 *           ters  that  follow it, up through the next newline, are
 *           treated as a comment and ignored.  The comment  charac-
 *           ter only has significance when it appears at the begin-
 *           ning of a command.
 *  
 *      [10] Each character is processed exactly  once  by  the  Tcl
 *           interpreter as part of creating the words of a command.
 *           For example, if variable substitution  occurs  then  no
 *           further substitutions are performed on the value of the
 *           variable;  the value is inserted into the  word  verba-
 *           tim.   If  command  substitution occurs then the nested
 *           command is processed entirely by the recursive call  to
 *           the  Tcl  interpreter;  no  substitutions are performed
 *           before making the recursive call and no additional sub-
 *           stitutions  are  performed  on the result of the nested
 *           script.
 *  
 *      [11] Substitutions do not affect the word  boundaries  of  a
 *           command.  For example, during variable substitution the
 *           entire value of the variable becomes part of  a  single
 *           word, even if the variable's value contains spaces.
 */

#include <tcl.h>
#include <string.h>
#include <ctype.h>

int SevenScript_ParseTcl             (Tcl_Interp *interp, char *input, Tcl_DString *result);
static int SevenScript_ParseCommand      (Tcl_Interp *interp, char **input, Tcl_DString *result);
static int SevenScript_ParseTclQuotedString (Tcl_Interp *interp, char **input, Tcl_DString *result);
static int SevenScript_ParseTclVariable     (Tcl_Interp *interp, char **input, Tcl_DString *result);
static int SevenScript_ParseTclArrayVariable(Tcl_Interp *interp, char **input, Tcl_DString *result);
static int SevenScript_ParseList         (Tcl_Interp *interp, char **input, Tcl_DString *result);
static int SevenScript_ParseBackslash    (Tcl_Interp *interp, char **input, Tcl_DString *result);

int SevenScript_ParseTclCmd(dummy, interp, argc, argv)
ClientData   dummy;
Tcl_Interp  *interp;
int          argc;
char       **argv;
{
  Tcl_DString r;
  int s;

  switch (s = SevenScript_ParseTcl(interp, argv[1], &r)) {
  case TCL_OK:
    Tcl_DStringResult(interp, &r);
    return TCL_OK;

  default:
    return s;
  }
}

static void append_result(char c, Tcl_DString *result) {
  char bf[2];
  bf[0] = c;
  bf[1] = '\0';
  Tcl_DStringAppend(result, bf, -1);
} 

int SevenScript_ParseTcl(Tcl_Interp *interp, char *input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;


  memset(result, 0, sizeof (*result));
  Tcl_DStringInit(result);

  for (p = input, c = p[0];
       c != '\0';
       c = p[0]  /* NOTE: The code in the body of the loop is
		  * responsible for advancing p properly.
		  * This *does* widen the possiblity for infinite loops.
		  */
       ) {

    /*
     * NOTE: The body of this loop is the same as in SevenScript_ParseCommand().
     * This is because both do the same job.
     * We cannot use the same function for both because the ending
     * conditions on the loop are different for each.
     */

    if (c == '{') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseList(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '"') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseTclQuotedString(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '\\') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseBackslash(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '[') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseCommand(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '$') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseTclVariable(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (isspace(c)) {
      append_result(c, result);
      p++;
    }
    else {
      append_result(c, result);
      p++;
    }

  }

  return TCL_OK;
}

/*
 *     [6]  If a word contains an open  bracket  (``['')  then  Tcl
 *          performs  command  substitution.  To do this it invokes
 *          the Tcl interpreter recursively to process the  charac-
 *          ters  following  the open bracket as a Tcl script.  The
 *          script may contain any number of commands and  must  be
 *          terminated  by  a close bracket (``]'').  The result of
 *          the script (i.e. the result of  its  last  command)  is
 *          substituted  into the word in place of the brackets and
 *          all of the characters between them.  There may  be  any
 *          number of command substitutions in a single word.  Com-
 *          mand substitution is not performed on words enclosed in
 *          braces.
 */  
static int SevenScript_ParseCommand(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;

  for (p = *input, c = p[0];
       c != '\0' && c != ']';
       c = p[0]  /* NOTE: The code in the body of the loop is
		  * responsible for advancing p properly.
		  * This *does* widen the possiblity for infinite loops.
		  */
       ) {

    /*
     * NOTE: The body of this loop is the same as in SevenScript_ParseTcl().
     * This is because both do the same job.
     * We cannot use the same function for both because the ending
     * conditions on the loop are different for each.
     */

    if (c == '{') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseList(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '"') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseTclQuotedString(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '\\') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseBackslash(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '[') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseCommand(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '$') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseTclVariable(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (isspace(c)) {
      append_result(c, result);
      p++;
    }
    else {
      append_result(c, result);
      p++;
    }

  }

  *input = p;
  return TCL_OK;
}

static int SevenScript_ParseTclQuotedString(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;

  for (p = *input, c = p[0];
       c != '\0';
       c = p[0]  /* NOTE: The code in the body of the loop is
		  * responsible for advancing p properly.
		  * This *does* widen the possiblity for infinite loops.
		  */
       ) {
    if (c == '\\') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseBackslash(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '[') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseCommand(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '$') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseTclVariable(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else {
      append_result(c, result);
      p++;
    }
  }

  *input = p;
  return TCL_OK;
}

static int SevenScript_ParseTclVariable(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;

  p = *input;
  c = p[0];

  if (isupper(c) || islower(c) || isdigit(c) || c == '_' || c == ':') {
      
    /*
     *  $name          Name is the name of a  scalar  variable;
     *                 the  name is terminated by any character
     *                 that isn't a letter,  digit,  or  under-
     *                 score.
     *
     *  $name(index)   Name gives the name of an array variable
     *                 and  index  gives the name of an element
     *                 within that array.   Name  must  contain
     *                 only  letters,  digits, and underscores.
     *                 Command substitutions, variable  substi-
     *                 tutions, and backslash substitutions are
     *                 performed on the characters of index.
     */

    append_result(c, result);
    
    for (p++, c = p[0];
	 c != '\0' && c != '(' && (isupper(c) || islower(c) || isdigit(c) || c == '_' || c == ':');
	 p++, c = p[0]) {
      append_result(c, result);
    }
    
    if (c != '\0') {
      if (c == '(') {
	append_result(c, result);
	p++;
	status = SevenScript_ParseTclArrayVariable(interp, &p, result);
	if (status != TCL_OK)
	  return status;
      }
    }
  }
  else if (c == '{') {
    
    /*
     * ${name}       Name is the name of a  scalar  variable.
     *               It may contain any characters whatsoever
     *               except for close braces.
     */
    
    append_result(c, result);
    
    /* XXX [DSH] Names can be ::name::name, but this loop simplifies it
     * to include any number of :'s.
     */
    for (p++, c = p[0];
	 c != '\0' && c != '}' && (isupper(c) || islower(c) || isdigit(c) || c == '_' || c == ':');
	 p++, c = p[0]) {
      append_result(c, result);
    }
    if (c != '}') {
      if (c == '\0') {
	Tcl_AppendResult(interp, "End of string found while parsing variable.  "
			 "String starts with: $", *input, 0);
	return TCL_ERROR;
      }
      else {
	Tcl_AppendResult(interp, "Improperly formatted variable name found while parsing variable. "
			 "String starts with: $", *input, 0);
	return TCL_ERROR;
      }
    }
    append_result(c, result);
    p++;
  }
  else {
    Tcl_AppendResult(interp, "Improperly formatted variable name found while parsing variable. "
		     "String starts with: $", *input, 0);
    return TCL_ERROR;
  }

  *input = p;
  return TCL_OK;
}

/*
 *          $name(index)   Name gives the name of an array variable
 *                         and  index  gives the name of an element
 *                         within that array.   Name  must  contain
 *                         only  letters,  digits, and underscores.
 *                         Command substitutions, variable  substi-
 *                         tutions, and backslash substitutions are
 *                         performed on the characters of index.
 */
static int SevenScript_ParseTclArrayVariable(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;

  for (p = *input, c = p[0];
       c != '\0' && c != ')';
       c = p[0]  /* NOTE: The code in the body of the loop is
		  * responsible for advancing p properly.
		  * This *does* widen the possiblity for infinite loops.
		  */
       ) {
    if (c == '[') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseCommand(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '\\') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseBackslash(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '$') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseTclVariable(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else {
      append_result(c, result);
      p++;
    }
  }

  *input = p;
  return TCL_OK;
}

/*
 *          \a    Audible alert (bell) (0x7).
 * 
 *          \b    Backspace (0x8).
 * 
 *          \f    Form feed (0xc).
 * 
 *          \n    Newline (0xa).
 * 
 *          \r    Carriage-return (0xd).
 * 
 *          \t    Tab (0x9).
 * 
 *          \v    Vertical tab (0xb).
 * 
 *          \<newline>whiteSpace
 *                A single space character replaces the  backslash,
 *                newline,  and  all spaces and tabs after the new-
 *                line.  This backslash sequence is unique in  that
 *                it  is replaced in a separate pre-pass before the
 *                command is actually parsed.  This means  that  it
 *                will  be  replaced  even  when  it occurs between
 *                braces, and the resulting space will  be  treated
 *                as  a  word  separator  if  it isn't in braces or
 *                quotes.
 * 
 *          \\    Backslash (``\'').
 * 
 *          \ooo  The digits ooo (one, two, or three of them)  give
 *                the octal value of the character.
 * 
 *          \xhh  The hexadecimal digits hh  give  the  hexadecimal
 *                value of the character.  Any number of digits may
 *                be present.
 */
static int SevenScript_ParseBackslash(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;

  p = *input;
  c = p[0];

  switch (c) {
  case 'a':    append_result(c, result); p++; break;
  case 'b':    append_result(c, result); p++; break;
  case 'f':    append_result(c, result); p++; break;
  case 'n':    append_result(c, result); p++; break;
  case 'r':    append_result(c, result); p++; break;
  case 't':    append_result(c, result); p++; break;
  case 'v':    append_result(c, result); p++; break;
  case ' ':    append_result(c, result); p++; break;
  case '\\':   append_result(c, result); p++; break;

  case '0':
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
    append_result(c, result);
    p++;
    if (p[0] < '0' || p[0] > '7')
      break;
    append_result(p[0], result);
    p++;
    if (p[0] < '0' || p[0] > '7')
      break;
    append_result(p[0], result);
    p++;
    break;

  case 'x':
    append_result(c, result);
    for (p++, c = p[0];
	 c != '\0' && ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F')  || (c >= 'a' && c <= 'f'));
	 p++, c = p[0]) {
      append_result(c, result);
    }
    break;

  default:
    append_result(c, result);
    p++;
  }

  *input = p;
  return TCL_OK;
}

/*
 *     [5]  If the first character of  a  word  is  an  open  brace
 *          (``{'')  then  the  word  is terminated by the matching
 *          close brace (``}'').  Braces nest within the word:  for
 *          each  additional open brace there must be an additional
 *          close brace (however, if an open brace or  close  brace
 *          within  the  word is quoted with a backslash then it is
 *          not counted in locating the matching close brace).   No
 *          substitutions  are  performed on the characters between
 *          the braces except for  backslash-newline  substitutions
 *          described  below,  nor  do semi-colons, newlines, close
 *          brackets, or white space receive any special  interpre-
 *          tation.   The  word will consist of exactly the charac-
 *          ters between the outer braces, not including the braces
 *          themselves.
 */

static int SevenScript_ParseList(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;
  int done = 0;

  for (p = *input, c = p[0];
       c != '\0' && !done;
       c = p[0]  /* NOTE: The code in the body of the loop is
		  * responsible for advancing p properly.
		  * This *does* widen the possiblity for infinite loops.
		  */
       ) {
    if (c == '{') {
      append_result(c, result);
      p++;
      status = SevenScript_ParseList(interp, &p, result);
      if (status != TCL_OK)
	return status;
    }
    else if (c == '\\') {
      if (p[1] == '{' || p[1] == '}' || c == '\n') {
	append_result(c, result);
	p++;
	append_result(p[0], result);
	p++;
      }
      else {
	append_result(c, result);
	p++;
      }
    }
    else if (c == '}') {
      if (p[1] != '\0' && !isspace(p[1])) {
	Tcl_AppendResult(interp, "Extra characters after close-brace", 0);
	return TCL_ERROR;
      }
      append_result(c, result);
      p++;
      done = 1;
    }
    else {
      append_result(c, result);
      p++;
    }
  }

  *input = p;
  return TCL_OK;
}
 
#if 0
static int SevenScript_ParseTclSkeleton(Tcl_Interp *interp, char **input, Tcl_DString *result)
{
  char c;
  char *p;
  int status = TCL_OK;

  for (p = *input, c = p[0];
       c != '\0';
       c = p[0]  /* NOTE: The code in the body of the loop is
		  * responsible for advancing p properly.
		  * This *does* widen the possiblity for infinite loops.
		  */
       ) {
  }

  *input = p;
  return TCL_OK;
}
#endif

