#include "my_alloc.h"

#define MYSQL_ERRMSG_SIZE       200
#define MAX_MYSQL_MANAGER_ERR 256

typedef unsigned long my_ulonglong;
typedef char **MYSQL_ROW;		/* return data as array of strings */
typedef unsigned int MYSQL_FIELD_OFFSET; /* offset to current field */
typedef char my_bool;
typedef char * gptr;
typedef int my_socket;
struct st_vio;					/* Only C */
typedef struct st_vio Vio;

typedef struct st_net {
  Vio* vio;
  unsigned char *buff,*buff_end,*write_pos,*read_pos;
  my_socket fd;					/* For Perl DBI/dbd */
  unsigned long max_packet,max_packet_size;
  unsigned int last_errno,pkt_nr,compress_pkt_nr;
  unsigned int write_timeout, read_timeout, retry_count;
  int fcntl;
  char last_error[MYSQL_ERRMSG_SIZE];
  unsigned char error;
  my_bool return_errno,compress;
  /*
    The following variable is set if we are doing several queries in one
    command ( as in LOAD TABLE ... FROM MASTER ),
    and do not want to confuse the client with OK at the wrong time
  */
  unsigned long remain_in_buf,length, buf_length, where_b;
  unsigned int *return_status;
  unsigned char reading_or_writing;
  char save_char;
  my_bool no_send_ok;
  gptr query_cache_query;
} NET;

typedef struct st_mysql_field {
  char *name;			/* Name of column */
  char *table;			/* Table of column if column was a field */
  char *org_table;		/* Org table name if table was an alias */
  char *db;			/* Database for table */
  char *def;			/* Default value (set by mysql_list_fields) */
  unsigned long length;		/* Width of column */
  unsigned long max_length;	/* Max width of selected set */
  unsigned int flags;		/* Div flags */
  unsigned int decimals;	/* Number of decimals in field */
  enum enum_field_types type;	/* Type of field. Se mysql_com.h for types */
} MYSQL_FIELD;

struct st_mysql_options {
  unsigned int connect_timeout,client_flag;
  unsigned int port;
  char *host,*init_command,*user,*password,*unix_socket,*db;
  char *my_cnf_file,*my_cnf_group, *charset_dir, *charset_name;
  char *ssl_key;				/* PEM key file */
  char *ssl_cert;				/* PEM cert file */
  char *ssl_ca;					/* PEM CA file */
  char *ssl_capath;				/* PEM directory of CA-s? */
  char *ssl_cipher;				/* cipher to use */
  unsigned long max_allowed_packet;
  my_bool use_ssl;				/* if to use SSL or not */
  my_bool compress,named_pipe;
 /*
   On connect, find out the replication role of the server, and
   establish connections to all the peers
 */
  my_bool rpl_probe;
 /*
   Each call to mysql_real_query() will parse it to tell if it is a read
   or a write, and direct it to the slave or the master
 */
  my_bool rpl_parse;
 /*
   If set, never read from a master,only from slave, when doing
   a read that is replication-aware
 */
  my_bool no_master_reads;
};

typedef struct st_mysql {
  NET		net;			/* Communication parameters */
  gptr		connector_fd;		/* ConnectorFd for SSL */
  char		*host,*user,*passwd,*unix_socket,*server_version,*host_info,
		*info,*db;
  struct charset_info_st *charset;
  MYSQL_FIELD	*fields;
  MEM_ROOT	field_alloc;
  my_ulonglong affected_rows;
  my_ulonglong insert_id;		/* id if insert on table with NEXTNR */
  my_ulonglong extra_info;		/* Used by mysqlshow */
  unsigned long thread_id;		/* Id for connection in server */
  unsigned long packet_length;
  unsigned int	port,client_flag,server_capabilities;
  unsigned int	protocol_version;
  unsigned int	field_count;
  unsigned int 	server_status;
  unsigned int  server_language;
  struct st_mysql_options options;
  enum mysql_status status;
  my_bool	free_me;		/* If free in mysql_close */
  my_bool	reconnect;		/* set to 1 if automatic reconnect */
  char	        scramble_buff[9];

 /*
   Set if this is the original connection, not a master or a slave we have
   added though mysql_rpl_probe() or mysql_set_master()/ mysql_add_slave()
 */
  my_bool rpl_pivot;
  /*
    Pointers to the master, and the next slave connections, points to
    itself if lone connection.
  */
  struct st_mysql* master, *next_slave;

  struct st_mysql* last_used_slave; /* needed for round-robin slave pick */
 /* needed for send/read/store/use result to work correctly with replication */
  struct st_mysql* last_used_con;
} MYSQL;

typedef struct st_mysql_rows {
  struct st_mysql_rows *next;		/* list of rows */
  MYSQL_ROW data;
} MYSQL_ROWS;

typedef MYSQL_ROWS *MYSQL_ROW_OFFSET;	/* offset to current row */

typedef struct st_mysql_data {
  my_ulonglong rows;
  unsigned int fields;
  MYSQL_ROWS *data;
  MEM_ROOT alloc;
} MYSQL_DATA;

enum mysql_option { MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS,
		    MYSQL_OPT_NAMED_PIPE, MYSQL_INIT_COMMAND,
		    MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP,
		    MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME,
		    MYSQL_OPT_LOCAL_INFILE};

enum mysql_status { MYSQL_STATUS_READY,MYSQL_STATUS_GET_RESULT,
		    MYSQL_STATUS_USE_RESULT};

/*
  There are three types of queries - the ones that have to go to
  the master, the ones that go to a slave, and the adminstrative
  type which must happen on the pivot connectioin
*/
enum mysql_rpl_type { MYSQL_RPL_MASTER, MYSQL_RPL_SLAVE,
		      MYSQL_RPL_ADMIN };

typedef struct st_mysql_res {
  my_ulonglong row_count;
  MYSQL_FIELD	*fields;
  MYSQL_DATA	*data;
  MYSQL_ROWS	*data_cursor;
  unsigned long *lengths;		/* column lengths of current row */
  MYSQL		*handle;		/* for unbuffered reads */
  MEM_ROOT	field_alloc;
  unsigned int	field_count, current_field;
  MYSQL_ROW	row;			/* If unbuffered read */
  MYSQL_ROW	current_row;		/* buffer to current row */
  my_bool	eof;			/* Used by mysql_fetch_row */
} MYSQL_RES;

typedef struct st_mysql_manager
{
  NET net;
  char *host,*user,*passwd;
  unsigned int port;
  my_bool free_me;
  my_bool eof;
  int cmd_status;
  int last_errno;
  char* net_buf,*net_buf_pos,*net_data_end;
  int net_buf_size;
  char last_error[MAX_MYSQL_MANAGER_ERR];
} MYSQL_MANAGER;

/*
  Set up and bring down the server; to ensure that applications will
  work when linked against either the standard client library or the
  embedded server library, these functions should be called.
*/
int  mysql_server_init(int argc, char **argv, char **groups);
void  mysql_server_end(void);

/*
  Set up and bring down a thread; these function should be called
  for each thread in an application which opens at least one MySQL
  connection.  All uses of the connection(s) should be between these
  function calls.
*/
my_bool  mysql_thread_init(void);
void  mysql_thread_end(void);

/*
  Functions to get information from the MYSQL and MYSQL_RES structures
  Should definitely be used if one uses shared libraries.
*/

my_ulonglong  mysql_num_rows(MYSQL_RES *res);
unsigned int  mysql_num_fields(MYSQL_RES *res);
my_bool  mysql_eof(MYSQL_RES *res);
MYSQL_FIELD * mysql_fetch_field_direct(MYSQL_RES *res,
				      unsigned int fieldnr);
MYSQL_FIELD *  mysql_fetch_fields(MYSQL_RES *res);
MYSQL_ROW_OFFSET  mysql_row_tell(MYSQL_RES *res);
MYSQL_FIELD_OFFSET  mysql_field_tell(MYSQL_RES *res);

unsigned int  mysql_field_count(MYSQL *mysql);
my_ulonglong  mysql_affected_rows(MYSQL *mysql);
my_ulonglong  mysql_insert_id(MYSQL *mysql);
unsigned int  mysql_errno(MYSQL *mysql);
const char *  mysql_error(MYSQL *mysql);
const char *  mysql_info(MYSQL *mysql);
unsigned long mysql_thread_id(MYSQL *mysql);
const char *  mysql_character_set_name(MYSQL *mysql);

MYSQL *		 mysql_init(MYSQL *mysql);
int		 mysql_ssl_set(MYSQL *mysql, const char *key,
			      const char *cert, const char *ca,
			      const char *capath, const char *cipher);
my_bool		 mysql_change_user(MYSQL *mysql, const char *user, 
				  const char *passwd, const char *db);
MYSQL *		 mysql_real_connect(MYSQL *mysql, const char *host,
				   const char *user,
				   const char *passwd,
				   const char *db,
				   unsigned int port,
				   const char *unix_socket,
				   unsigned int clientflag);
void		 mysql_close(MYSQL *sock);
int		 mysql_select_db(MYSQL *mysql, const char *db);
int		 mysql_query(MYSQL *mysql, const char *q);
int		 mysql_send_query(MYSQL *mysql, const char *q,
				 unsigned long length);
int		 mysql_read_query_result(MYSQL *mysql);
int		 mysql_real_query(MYSQL *mysql, const char *q,
				unsigned long length);
/* perform query on master */
int		 mysql_master_query(MYSQL *mysql, const char *q,
				unsigned long length);
int		 mysql_master_send_query(MYSQL *mysql, const char *q,
				unsigned long length);
/* perform query on slave */  
int		 mysql_slave_query(MYSQL *mysql, const char *q,
				unsigned long length);
int		 mysql_slave_send_query(MYSQL *mysql, const char *q,
				unsigned long length);

/*
  enable/disable parsing of all queries to decide if they go on master or
  slave
*/
void             mysql_enable_rpl_parse(MYSQL* mysql);
void             mysql_disable_rpl_parse(MYSQL* mysql);
/* get the value of the parse flag */  
int              mysql_rpl_parse_enabled(MYSQL* mysql);

/*  enable/disable reads from master */
void             mysql_enable_reads_from_master(MYSQL* mysql);
void             mysql_disable_reads_from_master(MYSQL* mysql);
/* get the value of the master read flag */  
int              mysql_reads_from_master_enabled(MYSQL* mysql);

enum mysql_rpl_type      mysql_rpl_query_type(const char* q, int len);  

/* discover the master and its slaves */  
int              mysql_rpl_probe(MYSQL* mysql);

/* set the master, close/free the old one, if it is not a pivot */
int              mysql_set_master(MYSQL* mysql, const char* host,
				 unsigned int port,
				 const char* user,
				 const char* passwd);
int              mysql_add_slave(MYSQL* mysql, const char* host,
				unsigned int port,
				const char* user,
				const char* passwd);

int		 mysql_shutdown(MYSQL *mysql);
int		 mysql_dump_debug_info(MYSQL *mysql);
int		 mysql_refresh(MYSQL *mysql,
			     unsigned int refresh_options);
int		 mysql_kill(MYSQL *mysql,unsigned long pid);
int		 mysql_ping(MYSQL *mysql);
const char *	 mysql_stat(MYSQL *mysql);
const char *	 mysql_get_server_info(MYSQL *mysql);
const char *	 mysql_get_client_info(void);
const char *	 mysql_get_host_info(MYSQL *mysql);
unsigned int	 mysql_get_proto_info(MYSQL *mysql);
MYSQL_RES *	 mysql_list_dbs(MYSQL *mysql,const char *wild);
MYSQL_RES *	 mysql_list_tables(MYSQL *mysql,const char *wild);
MYSQL_RES *	 mysql_list_fields(MYSQL *mysql, const char *table,
				 const char *wild);
MYSQL_RES *	 mysql_list_processes(MYSQL *mysql);
MYSQL_RES *	 mysql_store_result(MYSQL *mysql);
MYSQL_RES *	 mysql_use_result(MYSQL *mysql);
int		 mysql_options(MYSQL *mysql,enum mysql_option option,
			      const char *arg);
void		 mysql_free_result(MYSQL_RES *result);
void		 mysql_data_seek(MYSQL_RES *result,
				my_ulonglong offset);
MYSQL_ROW_OFFSET  mysql_row_seek(MYSQL_RES *result,
				MYSQL_ROW_OFFSET offset);
MYSQL_FIELD_OFFSET  mysql_field_seek(MYSQL_RES *result,
				   MYSQL_FIELD_OFFSET offset);
MYSQL_ROW	 mysql_fetch_row(MYSQL_RES *result);
unsigned long *  mysql_fetch_lengths(MYSQL_RES *result);
MYSQL_FIELD *	 mysql_fetch_field(MYSQL_RES *result);
unsigned long	 mysql_escape_string(char *to,const char *from,
				    unsigned long from_length);
unsigned long  mysql_real_escape_string(MYSQL *mysql,
				       char *to,const char *from,
				       unsigned long length);
void		 mysql_debug(const char *debug);
char *		 mysql_odbc_escape_string(MYSQL *mysql,
					 char *to,
					 unsigned long to_length,
					 const char *from,
					 unsigned long from_length,
					 void *param,
					 char *
					 (*extend_buffer)
					 (void *, char *to,
					  unsigned long *length));
void 		 myodbc_remove_escape(MYSQL *mysql,char *name);
unsigned int	 mysql_thread_safe(void);
MYSQL_MANAGER*   mysql_manager_init(MYSQL_MANAGER* con);  
MYSQL_MANAGER*   mysql_manager_connect(MYSQL_MANAGER* con,
				      const char* host,
				      const char* user,
				      const char* passwd,
				      unsigned int port);
void             mysql_manager_close(MYSQL_MANAGER* con);
int              mysql_manager_command(MYSQL_MANAGER* con,
					const char* cmd, int cmd_len);
int              mysql_manager_fetch_line(MYSQL_MANAGER* con,
                                        char* res_buf,
					int res_buf_size);
