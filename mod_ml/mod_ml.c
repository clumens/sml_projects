/* ====================================================================
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) 2000-2003 The Apache Software Foundation.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The end-user documentation included with the redistribution,
 *    if any, must include the following acknowledgment:
 *       "This product includes software developed by the
 *        Apache Software Foundation (http://www.apache.org/)."
 *    Alternately, this acknowledgment may appear in the software itself,
 *    if and wherever such third-party acknowledgments normally appear.
 *
 * 4. The names "Apache" and "Apache Software Foundation" must
 *    not be used to endorse or promote products derived from this
 *    software without prior written permission. For written
 *    permission, please contact apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache",
 *    nor may "Apache" appear in their name, without prior written
 *    permission of the Apache Software Foundation.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 *
 * Portions of this software are based upon public domain software
 * originally written at the National Center for Supercomputing Applications,
 * University of Illinois, Urbana-Champaign.
 */

#define  MOD_ML_VERSION    "mod_ml/0.0.1"
#define  SERVER_IP_LEN     20
#define  HEADER_STR_LEN    500

#include "httpd.h"
#include "http_config.h"
#include "http_core.h"
#include "http_log.h"
#include "http_main.h"
#include "http_protocol.h"
#include "util_script.h"

#include <stdio.h>

/*--------------------------------------------------------------------------*/
/*                                                                          */
/* Data declarations.                                                       */
/*                                                                          */
/* Here are the static cells and structure declarations private to our      */
/* module.                                                                  */
/*                                                                          */
/*--------------------------------------------------------------------------*/

static char *ml_server_ip;    /* IP where SML/NJ is running */
static long ml_port;          /* port where SML/NJ is listening */
static long ml_sock;          /* the socket, for after we connect */

/*
 * Declare ourselves so the configuration routines can find and know us.
 * We'll fill it in at the end of the module.
 */
module MODULE_VAR_EXPORT ml_module;

/*--------------------------------------------------------------------------*/
/* We prototyped the various syntax for command handlers (routines that     */
/* are called when the configuration parser detects a directive declared    */
/* by our module) earlier.  Now we actually declare a "real" routine that   */
/* will be invoked by the parser when our "real" directive is               */
/* encountered.                                                             */
/*                                                                          */
/* If a command handler encounters a problem processing the directive, it   */
/* signals this fact by returning a non-NULL pointer to a string            */
/* describing the problem.                                                  */
/*                                                                          */
/* The magic return value DECLINE_CMD is used to deal with directives       */
/* that might be declared by multiple modules.  If the command handler      */
/* returns NULL, the directive was processed; if it returns DECLINE_CMD,    */
/* the next module (if any) that declares the directive is given a chance   */
/* at it.  If it returns any other value, it's treated as the text of an    */
/* error message.                                                           */
/*--------------------------------------------------------------------------*/
static const char *cmd_ml(cmd_parms *cmd, void *dummy)
{
   return NULL;
}

/* Set up network parameters for where SML/NJ server is running. */
static const char *set_ml_server(cmd_parms *cmd, void *dummy,
                                 char *server_ip, char *port)
{
   ml_server_ip = server_ip;
   ml_port = atol(port);
   ml_sock = 0;

   return NULL;
}

static int open_socket(request_rec *r)
{
   struct sockaddr_in addr;
   int sock, ret;

   /* If the socket is already open, close it first. */
   if (ml_sock != 0)
   {
      ap_pclosesocket(r->pool, ml_sock);
      ml_sock = 0;
   }

   ml_sock = 0;
   addr.sin_addr.s_addr = inet_addr(ml_server_ip);
   addr.sin_port = htons ((unsigned short) ml_port);
   addr.sin_family = AF_INET;

   /* Open socket. */
   if ((sock = ap_psocket (r->pool, AF_INET, SOCK_STREAM, 0)) == -1)
      return -1;

   /* Connect to ML server. */
   do {
      ret = connect(sock, (struct sockaddr *) &addr,
                    sizeof(struct sockaddr_in));
   } while (ret == -1 && errno == EINTR);

   if (ret == -1) return -1;

   ml_sock = sock;
   return sock;
}

void close_socket (request_rec *r, int sock)
{
   if (ml_sock == 0)
      return;

   ap_pclosesocket(r->pool, ml_sock);
   ml_sock = 0;
}

/* Send a raw string over the connection to SML. */
int send_string (BUFF *buf, char *str)
{
   int retval, len;

   len = strlen(str);
   if ((retval = ap_bwrite (buf, str, len)) != len)
      return -1;
   return retval;
}

/* This is only for special things like headers and CGI parameters.  SML
 * will have to do the hard work of converting this into a lookup table.
 * Luckily, that sort of thing is easy over there.
 */
int send_ml_header (BUFF *buf, char *key, char *value)
{
   if (send_string (buf, key) == -1) return -1;
   if (send_string (buf, "\n") == -1) return -1;
   if (send_string (buf, value) == -1) return -1;
   if (send_string (buf, "\n") == -1) return -1;
}

/*--------------------------------------------------------------------------*/
/*                                                                          */
/* Now we declare our content handlers, which are invoked when the server   */
/* encounters a document which our module is supposed to have a chance to   */
/* see.  (See mod_mime's SetHandler and AddHandler directives, and the      */
/* mod_info and mod_status examples, for more details.)                     */
/*                                                                          */
/* Since content handlers are dumping data directly into the connexion      */
/* (using the r*() routines, such as rputs() and rprintf()) without         */
/* intervention by other parts of the server, they need to make             */
/* sure any accumulated HTTP headers are sent first.  This is done by       */
/* calling send_http_header().  Otherwise, no header will be sent at all,   */
/* and the output sent to the client will actually be HTTP-uncompliant.     */
/*--------------------------------------------------------------------------*/
static int ml_handler(request_rec *r)
{
   BUFF *buf_sock;
   int   ret, sock, content_length = 0;
   int   set_content_type = 0;
   char  key[HEADER_STR_LEN];
   char  val[MAX_STRING_LEN];

   /* Attempt to connect to the SML/NJ process. */
   if ((sock = open_socket(r)) == -1)
      return SERVER_ERROR;

   buf_sock = ap_bcreate(r->pool, B_SOCKET+B_RDWR);
   ap_bpushfd(buf_sock, sock, sock);

   /* Add common and CGI variables to the subprocess_env table. */
   ap_add_common_vars (r);
   ap_add_cgi_vars (r);

   if ((ret = ap_setup_client_block (r, REQUEST_CHUNKED_DECHUNK)) != 0)
   {
      ap_kill_timeout(r);
      close_socket(r, sock);
      return ret;
   }

   ap_reset_timeout(r);

   /* Send the entire subprocess_env table to SML as "key value" strings.
    * This will then get munged into a lookup table so that any pages can check
    * variables.  Note that this includes the name of the file to process.
    */
   if (r->subprocess_env != NULL)
   {
      array_header *env_arr = ap_table_elts (r->subprocess_env);
      table_entry  *elts = (table_entry *) env_arr->elts;
      int i;

      for (i = 0; i < env_arr->nelts; ++i)
      {
         if (!elts[i].key)
            continue;
         else
         {
            if (send_ml_header (buf_sock, elts[i].key, elts[i].val) == -1)
            {
               ap_kill_timeout(r);
               close_socket(r, sock);
               return SERVER_ERROR;
            }
         }

         ap_reset_timeout(r);
      }
   }

   /* Now let's send all the headers. */
   if (r->headers_in)
   {
      array_header *hdr_arr = ap_table_elts(r->headers_in);
      table_entry  *elts = (table_entry *) hdr_arr->elts;
      int i;

      for (i = 0; i < hdr_arr->nelts; ++i)
      {
         if (!elts[i].key)
            continue;
         else
         {
            if (send_ml_header (buf_sock, elts[i].key, elts[i].val) == -1)
            {
               ap_kill_timeout(r);
               close_socket(r, sock);
               return SERVER_ERROR;
            }
         }

         ap_reset_timeout(r);
      }
   }

   /* Is there anything else (like POST data) that the client has for us? */
   if (ap_should_client_block(r))
   {
      char buf[HUGE_STRING_LEN];
      long bufsize = 1;

      /* Now here's a hack.  Flag this content with some random header
       * value so SML will put it into the environment properly.  Users
       * should look up the Post-Content header in the apache_env to get
       * this stuff.
       */
      if (send_string (buf_sock, "Post-Content\n") == -1)
      {
         ap_kill_timeout(r);
         close_socket(r, sock);
         return SERVER_ERROR;
      }

      /* If the client has anything else, send it to the ML process. */
      while ((bufsize = ap_get_client_block (r, buf, HUGE_STRING_LEN)) > 0)
      {
         ap_reset_timeout(r);

         if (ap_bwrite (buf_sock, buf, bufsize) < bufsize)
         {
            /* Discard anything else the client has for us. */
            while (ap_get_client_block (r, buf, HUGE_STRING_LEN) > 0) ;
            close_socket(r, sock);
            return SERVER_ERROR;
         }
      }

      if (send_string (buf_sock, "\n") == -1)
      {
         ap_kill_timeout(r);
         close_socket(r, sock);
         return SERVER_ERROR;
      }
   }

   if (send_string (buf_sock, "end\n") == -1)
   {
      ap_kill_timeout(r);
      close_socket(r, sock);
      return SERVER_ERROR;
   }

   if (ap_bflush(buf_sock) == -1)
   {
      ap_kill_timeout(r);
      close_socket(r, sock);
      return SERVER_ERROR;
   }

   ap_kill_timeout(r);
   ap_hard_timeout("ml-read", r);

   /* The first chunk of text we get back from ML is the headers. */
   while (ap_bgets(key, HEADER_STR_LEN, buf_sock) > 0)
   {
      int len = strlen(key);
      
      if (len > 0) key[len-1] = 0;

      ap_kill_timeout(r);

      /* If this marks the end of the headers, jump out. */
      if (!strcmp(key, "end")) break;

      /* The header's value comes on the next line down. */
      if (ap_bgets(val, MAX_STRING_LEN, buf_sock) <= 0) break;

      len = strlen(val);
      if (len > 0) val[len-1] = 0;

      /* We need to take special action for certain headers. */
      if (!strcmp(key, "Content-Type"))
      {
         char *tmp = ap_pstrdup(r->pool, val);
         ap_content_type_tolower(tmp);
         r->content_type = tmp;

         set_content_type = 1;
      }
      else if (!strcmp(key, "Status"))
      {
         r->status = atoi(val);
         r->status_line = ap_pstrdup(r->pool, val);
      }
      else if (!strcmp(key, "Content-Length"))
      {
         ap_table_set(r->headers_out, key, val);
         content_length = atoi(val);
      }
      else if (!strcmp(key, "Last-Modified"))
      {
         ap_update_mtime(r, ap_parseHTTPdate(val));
         ap_set_last_modified(r);
      }
      else if (!strcmp(key, "Log-Error"))
      {
         ap_log_error("mod_ml", 0, APLOG_ERR, r->server, val);
      }
      else if (!strcmp(key, "Log"))
      {
         ap_log_error("mod_ml", 0, APLOG_ERR, r->server, val);
      }
      else if (!strcmp(key, "Set-Cookie"))
      {
         ap_table_add(r->headers_out, key, val);
      }
      else
      {
         ap_table_set(r->headers_out, key, val);
      }
   }

   /* If the page didn't set a content-type header, just assume. */
   if (set_content_type == 0)
      r->content_type = "text/html";

   /* Now send the headers. */
   ap_send_http_header(r);

   /* If we're only supposed to return headers, we're already done and don't
    * care what we got back from SML.  Otherwise, return the page it built.
    */
   if (r->header_only)
       return OK;
   else
   {
      if (content_length > 0)
      {
         long read = ap_send_fb_length (buf_sock, r, content_length);

         if (read <= 0)
         {
            ap_kill_timeout(r);
            close_socket(r, sock);
            return SERVER_ERROR;
         }

         if (read < content_length || r->connection->aborted)
         {
            char buffer[HUGE_STRING_LEN];
            content_length -= read;

            do {
               read = ap_bgets(buffer, HUGE_STRING_LEN > content_length ?
                               content_length : HUGE_STRING_LEN, buf_sock);
               content_length -= read;
            } while (read > 0 && content_length > 0);
         }
      }
      else
      {
         if (ap_send_fb(buf_sock, r) <= 0)
         {
            ap_kill_timeout(r);
            close_socket(r, sock);
            return SERVER_ERROR;
         }
      }
   }

   ap_kill_timeout(r);
   close_socket(r, sock);
   return OK;
}

/*--------------------------------------------------------------------------*/
/*                                                                          */
/* Now let's declare routines for each of the callback phase in order.      */
/* (That's the order in which they're listed in the callback list, *not     */
/* the order in which the server calls them!  See the command_rec           */
/* declaration near the bottom of this file.)  Note that these may be       */
/* called for situations that don't relate primarily to our function - in   */
/* other words, the fixup handler shouldn't assume that the request has     */
/* to do with "example" stuff.                                              */
/*                                                                          */
/* With the exception of the content handler, all of our routines will be   */
/* called for each request, unless an earlier handler from another module   */
/* aborted the sequence.                                                    */
/*                                                                          */
/* Handlers that are declared as "int" can return the following:            */
/*                                                                          */
/*  OK          Handler accepted the request and did its thing with it.     */
/*  DECLINED    Handler took no action.                                     */
/*  HTTP_mumble Handler looked at request and found it wanting.             */
/*                                                                          */
/* What the server does after calling a module handler depends upon the     */
/* handler's return value.  In all cases, if the handler returns            */
/* DECLINED, the server will continue to the next module with an handler    */
/* for the current phase.  However, if the handler return a non-OK,         */
/* non-DECLINED status, the server aborts the request right there.  If      */
/* the handler returns OK, the server's next action is phase-specific;      */
/* see the individual handler comments below for details.                   */
/*                                                                          */
/*--------------------------------------------------------------------------*/
/* 
 * This function is called during server initialisation.  Any information
 * that needs to be recorded must be in static cells, since there's no
 * configuration record.
 *
 * There is no return value.
 */
static void ml_init(server_rec *s, pool *p)
{
   ap_add_version_component(MOD_ML_VERSION);
}

/*--------------------------------------------------------------------------*/
/*                                                                          */
/* All of the routines have been declared now.  Here's the list of          */
/* directives specific to our module, and information about where they      */
/* may appear and how the command parser should pass them to us for         */
/* processing.  Note that care must be taken to ensure that there are NO    */
/* collisions of directive names between modules.                           */
/*                                                                          */
/*--------------------------------------------------------------------------*/
static const command_rec ml_cmds[] =
{
   {
      "MLServer",
      set_ml_server,
      NULL,
      OR_ALL,
      TAKE2,
      "IP and port where SML/NJ is running"
   },
   {
      "ML",                            /* directive name */
      cmd_ml,                          /* config action routine */
      NULL,                            /* argument to include in call */
      OR_ALL,                          /* where available */
      NO_ARGS,                         /* arguments */
      "ML directove - no arguments"    /* directive description */
   },
   {NULL}
};

/*--------------------------------------------------------------------------*/
/*                                                                          */
/* Now the list of content handlers available from this module.             */
/*                                                                          */
/*--------------------------------------------------------------------------*/
/* 
 * List of content handlers our module supplies.  Each handler is defined by
 * two parts: a name by which it can be referenced (such as by
 * {Add,Set}Handler), and the actual routine name.  The list is terminated by
 * a NULL block, since it can be of variable length.
 *
 * Note that content-handlers are invoked on a most-specific to least-specific
 * basis; that is, a handler that is declared for "text/plain" will be
 * invoked before one that was declared for "text / *".  Note also that
 * if a content-handler returns anything except DECLINED, no other
 * content-handlers will be called.
 */
static const handler_rec ml_handlers[] =
{
    {"ml-handler", ml_handler},
    {NULL}
};

/*--------------------------------------------------------------------------*/
/*                                                                          */
/* Finally, the list of callback routines and data structures that          */
/* provide the hooks into our module from the other parts of the server.    */
/*                                                                          */
/*--------------------------------------------------------------------------*/
/* 
 * Module definition for configuration.  If a particular callback is not
 * needed, replace its routine name below with the word NULL.
 *
 * The number in brackets indicates the order in which the routine is called
 * during request processing.  Note that not all routines are necessarily
 * called (such as if a resource doesn't have access restrictions).
 */
module MODULE_VAR_EXPORT ml_module =
{
   STANDARD_MODULE_STUFF,
   ml_init,                   /* module initializer */
   NULL,                      /* per-directory config creator */
   NULL,                      /* dir config merger */
   NULL,                      /* server config creator */
   NULL,                      /* server config merger */
   ml_cmds,                   /* command table */
   ml_handlers,               /* list of handlers */
   NULL,                      /* filename-to-URI translation */
   NULL,                      /* check user ID */
   NULL,                      /* check auth */
   NULL,                      /* check access */
   NULL,                      /* type checker */
   NULL,                      /* fixups */
   NULL,                      /* logger */
   NULL,                      /* header parser */
   NULL,                      /* process initializer */
   NULL,                      /* process exit/cleanup */
   NULL                       /* post read request */
};
