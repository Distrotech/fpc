{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2000, 2001 by madded2 (madded@vao.udmnet.ru).
    Copyright (c) 2002, 2004 Yuri Prokushev (prokushev@freemail.ru).

    Interface to OS/2 32-bit sockets library

 **********************************************************************

  Inet & Sockets Unit v1.04.
  /c/ 2000, 2001 by madded2 (madded@vao.udmnet.ru).
  based on units from SIBYL & infos from Toolkit 4.0.

  for help use tcppr.inf and C samples from toolkit.

  without res_* and dh_* funcs, and have very
  bad support for select() and ioctl() funcs

  new in ver 1.04 : little ioctl() & iptrace support + errors SOCE* constants
  new in ver 1.03 : used inet_lib.lib file for fixing VP linker bug
  new in ver 1.02 : $saves sections, need for correct registers operations
  new in ver 1.01 : ip header struct
}
{
@abstract(a unit to handle sockets)
@author(Yuri Prokushev (prokushev@freemail.ru))
@author(madded2 (madded@vao.udmnet.ru))
@created(3 Sep 2002)
@lastmod(23 Sep 2002)
@todo(sys/ioctl.h, sys/ioctlos2.h, sys/itypes.h)
This is functions from SO32DLL.DLL. These functions allows to use
protocol-independed sockets. Equal to SYS\SOCKET.H, NERRNO.H, SYS\SYSCTL.H.
}
unit SO32Dll;

interface

{$MODE ObjFPC}
{$ASMMODE Intel}

(***************************************************************************)
(*                                                                         *)
(*                                     Types                               *)
(*                                                                         *)
(***************************************************************************)
const
  // stream socket
  SOCK_STREAM    = 1;
  // datagram socket
  SOCK_DGRAM     = 2;
  // raw-protocol interface
  SOCK_RAW       = 3;
  // reliably-delivered message
  SOCK_RDM       = 4;
  // sequenced packet stream
  SOCK_SEQPACKET = 5;

(***************************************************************************)
(*                                                                         *)
(*                            Option flags per-socket                      *)
(*                                                                         *)
(***************************************************************************)
const
  // turn on debugging info recording
  SO_DEBUG        = $0001;
  // socket has had listen()
  SO_ACCEPTCONN   = $0002;
  // allow local address reuse
  SO_REUSEADDR    = $0004;
  // keep connections alive
  SO_KEEPALIVE    = $0008;
  // just use interface addresses
  SO_DONTROUTE    = $0010;
  // permit sending of broadcast msgs
  SO_BROADCAST    = $0020;
  // bypass hardware when possible
  SO_USELOOPBACK  = $0040;
  // linger on close if data present
  SO_LINGER       = $0080;
  // leave received OOB data in line
  SO_OOBINLINE    = $0100;
  // limited broadcast sent on all IFs
  SO_L_BROADCAST  = $0200;
  // set if shut down called for rcv
  SO_RCV_SHUTDOWN = $0400;
  // set if shutdown called for send
  SO_SND_SHUTDOWN = $0800;
  // allow local address & port reuse
  SO_REUSEPORT    = $1000;
  // allow t/tcp on socket
  SO_TTCP         = $2000;

(***************************************************************************)
(*                                                                         *)
(*                  Additional options, not kept in so_options             *)
(*                                                                         *)
(***************************************************************************)
const
  // send buffer size
  SO_SNDBUF   = $1001;
  // receive buffer size
  SO_RCVBUF   = $1002;
  // send low-water mark
  SO_SNDLOWAT = $1003;
  // receive low-water mark
  SO_RCVLOWAT = $1004;
  // send timeout
  SO_SNDTIMEO = $1005;
  // receive timeout
  SO_RCVTIMEO = $1006;
  // get error status and clear
  SO_ERROR    = $1007;
  // get socket type
  SO_TYPE     = $1008;
  // get socket options
  SO_OPTIONS  = $1010;

(***************************************************************************)
(*                                                                         *)
(*               Structure used for manipulating linger option             *)
(*                                                                         *)
(***************************************************************************)
type
  //Structure used for manipulating linger option
  linger = record
     l_onoff      :  Longint; // option on/off
     l_linger     : Longint; // linger time
  end;

(***************************************************************************)
(*                                                                         *)
(*      Level number for (get/set)sockopt() to apply to socket itself      *)
(*                                                                         *)
(***************************************************************************)
const
  // options for socket level
  SOL_SOCKET = $ffff;

(***************************************************************************)
(*                                                                         *)
(*                              Address families                           *)
(*                                                                         *)
(***************************************************************************)
const
  // unspecified
  AF_UNSPEC   = 0;
  // local to host (pipes, portals)
  AF_LOCAL    = 1;
  // backward compatibility
  AF_UNIX     = AF_LOCAL;
  AF_OS2      = AF_UNIX;
  // internetwork: UDP, TCP, etc.
  AF_INET     = 2;
  // arpanet imp addresses
  AF_IMPLINK  = 3;
  // pup protocols: e.g. BSP
  AF_PUP      = 4;
  // mit CHAOS protocols
  AF_CHAOS    = 5;
  // XEROX NS protocols
  AF_NS       = 6;
  // ISO protocols
  AF_ISO      = 7;
  // ISO protocols
  AF_OSI      = AF_ISO;
  // european computer manufacturers
  AF_ECMA     = 8;
  // datakit protocols
  AF_DATAKIT  = 9;
  // CCITT protocols, X.25 etc
  AF_CCITT    = 10;
  // IBM SNA
  AF_SNA      = 11;
  // DECnet
  AF_DECnet   = 12;
  // DEC Direct data link interface
  AF_DLI      = 13;
  // LAT
  AF_LAT      = 14;
  // NSC Hyperchannel
  AF_HYLINK   = 15;
  // Apple Talk
  AF_APPLETALK = 16;
  // Netbios
  AF_NB        = 17;
  // Netbios
  AF_NETBIOS   = AF_NB;
  // Link layer interface
  AF_LINK      = 18;
  // eXpress Transfer Protocol (no AF)
  pseudo_AF_XTP = 19;
  // connection-oriented IP, aka ST II
  AF_COIP      = 20;
  // Computer Network Technology
  AF_CNT       = 21;
  // Help Identify RTIP packets
  pseudo_AF_RTIP = 22;
  // Novell Internet Protocol
  AF_IPX       = 23;
  // Simple Internet Protocol
  AF_SIP       = 24;
  AF_INET6     = 24;
  // Help Identify PIP packets
  pseudo_AF_PIP = 25;
  // Internal Routing Protocol
  AF_ROUTE     = 39;
  // firewall support
  AF_FWIP      = 40;
  // IPSEC and encryption techniques
  AF_IPSEC     = 41;
  // DES
  AF_DES       = 42;
  AF_MD5       = 43;
  AF_CDMF      = 44;

  AF_MAX       = 45;

(***************************************************************************)
(*                                                                         *)
(*             Structure used by kernel to store most addresses            *)
(*                                                                         *)
(***************************************************************************)
type
  // Structure used by kernel to store most addresses
  sockaddr = record
    sa_len:    Byte;                     // total length
    sa_family: Byte;                     // address family
    sa_data:   array [0..13] of Byte; // up to 14 bytes of direct address
  end;
  psockaddr = ^sockaddr;

(***************************************************************************)
(*                                                                         *)
(*  Structure used by kernel to pass protocol information in raw sockets   *)
(*                                                                         *)
(***************************************************************************)
type
  // Structure used by kernel to pass protocol information in raw sockets
  sockproto = record
    sp_family:   Word; // address family
    sp_protocol: Word; // protocol
  end;


(***************************************************************************)
(*                                                                         *)
(*             Protocol families, same as address families for now         *)
(*                                                                         *)
(***************************************************************************)
const
  PF_UNSPEC    = AF_UNSPEC;
  PF_LOCAL     = AF_LOCAL;
  PF_UNIX      = AF_UNIX;
  PF_OS2       = AF_OS2;
  PF_INET      = AF_INET;
  PF_IMPLINK   = AF_IMPLINK;
  PF_PUP       = AF_PUP;
  PF_CHAOS     = AF_CHAOS;
  PF_NS        = AF_NS;
  PF_ISO       = AF_ISO;
  PF_OSI       = AF_OSI;
  PF_ECMA      = AF_ECMA;
  PF_DATAKIT   = AF_DATAKIT;
  PF_CCITT     = AF_CCITT;
  PF_SNA       = AF_SNA;
  PF_DECnet    = AF_DECnet;
  PF_DLI       = AF_DLI;
  PF_LAT       = AF_LAT;
  PF_HYLINK    = AF_HYLINK;
  PF_APPLETALK = AF_APPLETALK;
  PF_NETBIOS   = AF_NB;
  PF_NB        = AF_NB;
  PF_ROUTE     = AF_ROUTE;
  PF_LINK      = AF_LINK;
  // really just proto family, no AF
  PF_XTP       = pseudo_AF_XTP;
  PF_COIP      = AF_COIP;
  PF_CNT       = AF_CNT;
  PF_SIP       = AF_SIP;
  PF_INET6     = AF_INET6;
  // same format as AF_NS
  PF_IPX       = AF_IPX;
  // same format as AF_INET
  PF_RTIP      = pseudo_AF_RTIP;
  PF_PIP       = pseudo_AF_PIP;

  PF_MAX       = AF_MAX;


(***************************************************************************)
(*                                                                         *)
(*  Definitions for sysctl call. The sysctl call uses a hierarchical name  *)
(* for objects that can be examined or modified.  The name is expressed as *)
(* a sequence of integers.  Like a file path name, the meaning of each     *)
(* component depends on its place in the hierarchy. The top-level and kern *)
(* identifiers are defined here, and other identifiers are defined in the  *)
(* respective subsystem header files.                                      *)
(*                                                                         *)
(***************************************************************************)

const
// largest number of components supported
  CTL_MAXNAME    = 12;

(***************************************************************************)
(*                                                                         *)
(* Each subsystem defined by sysctl defines a list of variables            *)
(* for that subsystem. Each name is either a node with further             *)
(* levels defined below it, or it is a leaf of some particular             *)
(* type given below. Each sysctl level defines a set of name/type          *)
(* pairs to be used by sysctl(1) in manipulating the subsystem.            *)
(*                                                                         *)
(***************************************************************************)

type
  ctlname=record
    ctl_name: PChar;      // subsystem name
    ctl_type: Longint;    // type of name
  end;

const
  // name is a node
  CTLTYPE_NODE    =1;
  // name describes an integer
  CTLTYPE_INT     =2;
  // name describes a string
  CTLTYPE_STRING  =3;
  // name describes a 64-bit number
  CTLTYPE_QUAD    =4;
  // name describes a structure
  CTLTYPE_STRUCT  =5;
  // inetcfg sysctl code
  CTLTYPE_INETCFG =6;
  // inetver sysctl code
  CTLTYPE_INEVER  =7;

(*
 * Top-level identifiers
 *)
const
  // "high kernel": proc, limits
  CTL_KERN       = 1;
  // network, see socket.h
  CTL_NET        = 4;
  // OS/2 specific codes
  CTL_OS2        = 9;

(*

#define CTL_NAMES { \
        { 0, 0 }, \
        { "kern", CTLTYPE_NODE }, \
        { "net", CTLTYPE_NODE }, \
        { "os2", CTLTYPE_NODE }, \
}

/*
 * CTL_KERN identifiers
 */
#define KERN_MAXFILES            7      /* int: max open files */
#define KERN_HOSTNAME           10      /* string: hostname */
#define KERN_HOSTID             11      /* int: host identifier */

#define CTL_KERN_NAMES { \
        { 0, 0 }, \
        { "ostype", CTLTYPE_STRING }, \
        { "osrelease", CTLTYPE_STRING }, \
        { "osrevision", CTLTYPE_INT }, \
        { "version", CTLTYPE_STRING }, \
        { "maxvnodes", CTLTYPE_INT }, \
        { "maxproc", CTLTYPE_INT }, \
        { "maxfiles", CTLTYPE_INT }, \
        { "argmax", CTLTYPE_INT }, \
        { "securelevel", CTLTYPE_INT }, \
        { "hostname", CTLTYPE_STRING }, \
        { "hostid", CTLTYPE_INT }, \
        { "clockrate", CTLTYPE_STRUCT }, \
        { "vnode", CTLTYPE_STRUCT }, \
        { "proc", CTLTYPE_STRUCT }, \
        { "file", CTLTYPE_STRUCT }, \
        { "profiling", CTLTYPE_NODE }, \
        { "posix1version", CTLTYPE_INT }, \
        { "ngroups", CTLTYPE_INT }, \
        { "job_control", CTLTYPE_INT }, \
        { "saved_ids", CTLTYPE_INT }, \
        { "boottime", CTLTYPE_STRUCT }, \
}

/*
 * KERN_SYSCTL objects
 */
#define KERNCTL_INETVER      70          /* Sysctl code for sockets Inetversion */
#define OS2_MEMMAPIO         1           /* memory map io */
#define OS2_QUERY_MEMMAPIO   2           /* Query if mapped memory usable */

/* Generic Structure for Inetcfg calls */
struct inetcfg_ctl{
          unsigned long var_name;
          unsigned long var_cur_val;
          unsigned long var_max_val;
          unsigned long var_def_val;
          unsigned long var_min_val;
};

/* Inetversion */
struct inetvers_ctl {
         float version;
         char  versionstr[10];           /* Less than 10 chars in version string */
};

#include <sys/cdefs.h>
#ifndef KERNEL
__BEGIN_DECLS
int _System sysctl __TCPPROTO((int *, u_int, void *, size_t *, void *, size_t));
__END_DECLS
#endif
*)

(* !!TODO!! Not finished yet!!
/*
 * Definitions for network related sysctl, CTL_NET.
 *
 * Second level is protocol family.
 * Third level is protocol number.
 *
 * Further levels are defined by the individual families below.
 */
const
  NET_MAXID     = AF_MAX;

#define CTL_NET_NAMES { \
        { 0, 0 }, \
        { "local", CTLTYPE_NODE }, \
        { "inet", CTLTYPE_NODE }, \
        { "implink", CTLTYPE_NODE }, \
        { "pup", CTLTYPE_NODE }, \
        { "chaos", CTLTYPE_NODE }, \
        { "xerox_ns", CTLTYPE_NODE }, \
        { "iso", CTLTYPE_NODE }, \
        { "emca", CTLTYPE_NODE }, \
        { "datakit", CTLTYPE_NODE }, \
        { "ccitt", CTLTYPE_NODE }, \
        { "ibm_sna", CTLTYPE_NODE }, \
        { "decnet", CTLTYPE_NODE }, \
        { "dec_dli", CTLTYPE_NODE }, \
        { "lat", CTLTYPE_NODE }, \
        { "hylink", CTLTYPE_NODE }, \
        { "appletalk", CTLTYPE_NODE }, \
        { "netbios", CTLTYPE_NODE }, \
        { "route", CTLTYPE_NODE }, \
        { "link_layer", CTLTYPE_NODE }, \
        { "xtp", CTLTYPE_NODE }, \
        { "coip", CTLTYPE_NODE }, \
        { "cnt", CTLTYPE_NODE }, \
        { "rtip", CTLTYPE_NODE }, \
        { "ipx", CTLTYPE_NODE }, \
        { "sip", CTLTYPE_NODE }, \
        { "pip", CTLTYPE_NODE }, \
}

/*
 * PF_ROUTE - Routing table
 *
 * Three additional levels are defined:
 *      Fourth: address family, 0 is wildcard
 *      Fifth: type of info, defined below
 *      Sixth: flag(s) to mask with for NET_RT_FLAGS
 */
const
  // dump; may limit to a.f.
  NET_RT_DUMP   = 1;
  // by flags, e.g. RESOLVING
  NET_RT_FLAGS  = 2;
  // survey interface list
  NET_RT_IFLIST = 3;
  NET_RT_MAXID  = 4;

#define CTL_NET_RT_NAMES { \
        { 0, 0 }, \
        { "dump", CTLTYPE_STRUCT }, \
        { "flags", CTLTYPE_STRUCT }, \
        { "iflist", CTLTYPE_STRUCT }, \
}

*)

(***************************************************************************)
(*                                                                         *)
(*             Maximum queue length specifiable by listen                  *)
(*                                                                         *)
(***************************************************************************)
const
  // Maximum queue length specifiable by listen
  SOMAXCONN = 1024;

(***************************************************************************)
(*                                                                         *)
(*               Message header for recvmsg and sendmsg calls              *)
(*          Used value-result for recvmsg, value only for sendmsg          *)
(*                                                                         *)
(***************************************************************************)
type
  iovec = record
    iov_base  :  Pointer;
    iov_len   :  Longint;
  end;

  // Message header for recvmsg and sendmsg calls
  msghdr = record
    msg_name:       pChar;     // optional address
    msg_namelen:    Longint;   // size of address
    msg_iov:        ^iovec;    // scatter/gather array
    msg_iovlen:     Longint;   // # elements in msg_iov (max 1024)
    msg_control:    pChar;     // ancillary data, see below
    msg_controllen: Longint;   // ancillary data buffer len
    msg_flags:      Longint;   // flags on received message
  end;

const
  // process out-of-band data
  MSG_OOB       = $1;
  // peek at incoming message
  MSG_PEEK      = $2;
  // send without using routing tables
  MSG_DONTROUTE = $4;
  // send without using routing tables
  MSG_FULLREAD   = $8;
  // data completes record
  MSG_EOR        = $10;
  // data discarded before delivery
  MSG_TRUNC      = $20;
  // control data lost before delivery
  MSG_CTRUNC     = $40;
  // wait for full request or error
  MSG_WAITALL    = $80;
  // this message should be nonblocking
  MSG_DONTWAIT   = $100;
  MSG_EOF        = $200;
  // mem mapped io
  MSG_MAPIO      = $400;

(***************************************************************************)
(*                                                                         *)
(*        Header for ancillary data objects in msg_control buffer          *)
(*         Used for additional information with/about a datagram           *)
(*          not expressible by flags.   The format is a sequence         *)
(*           of message elements headed by cmsghdr structures              *)
(*                                                                         *)
(***************************************************************************)
type
  // Header for ancillary data objects in msg_control buffer
  cmsghdr = record
    cmsg_len:   Longint; // data byte count, including hdr
    cmsg_level: Longint; // originating protocol
    cmsg_type:  Longint; // protocol-specific type
  end;

  cmsg = record
    cmsg_hdr:  cmsghdr;
    cmsg_data: array [0..0] of Byte;
  end;

(***************************************************************************)
(*                                                                         *)
(*                     "Socket"-level control message types                *)
(*                                                                         *)
(***************************************************************************)
const
  // access rights (array of int)
  SCM_RIGHTS = $01;

(***************************************************************************)
(*                                                                         *)
(*              4.3 compat sockaddr, move to compat file later             *)
(*                                                                         *)
(***************************************************************************)
type
  // 4.3 compat sockaddr
  osockaddr = record
    sa_family: Word;                // address family
    sa_data: array [0..13] of Byte; // up to 14 bytes of direct address
  end;

(***************************************************************************)
(*                                                                         *)
(*             4.3-compat message header (move to compat file later)       *)
(*                                                                         *)
(***************************************************************************)
type
  // 4.3-compat message header
  omsghdr = record
    msg_name:         pChar;   // optional address
    msg_namelen:      Longint; // size of address
    msg_iov:          ^iovec;  // scatter/gather array
    msg_iovlen:       Longint; // # elements in msg_iov
    msg_accrights:    pChar;   // access rights sent/received
    msg_accrightslen: Longint;
  end;


(* !!TODO
/*
 * send_file parameter structure
 */
struct sf_parms {
        void   *header_data;      /* ptr to header data */
        size_t header_length;     /* size of header data */
        int    file_handle;       /* file handle to send from */
        size_t file_size;         /* size of file */
        int    file_offset;       /* byte offset in file to send from */
        size_t file_bytes;        /* bytes of file to be sent */
        void   *trailer_data;     /* ptr to trailer data */
        size_t trailer_length;    /* size of trailer data */
        size_t bytes_sent;        /* bytes sent in this send_file call */
};
*)

{ !!TODO Check is all this functions defined
__BEGIN_DECLS
int _System accept_and_recv __TCPPROTO((long, long*, struct sockaddr *, long*, struct sockaddr*, long*, caddr_t, size_t));
ssize_t _System recvfrom __TCPPROTO((int, void *, size_t, int, struct sockaddr *, int *));
ssize_t _System recvmsg __TCPPROTO((int, struct msghdr *, int));
ssize_t _System send __TCPPROTO((int, const void *, size_t, int));
ssize_t _System sendto __TCPPROTO((int, const void *, size_t, int, const struct sockaddr *, int));
ssize_t _System sendmsg __TCPPROTO((int, const struct msghdr *, int));
ssize_t _System send_file __TCPPROTO((int *, struct sf_parms *, int ));
int _System setsockopt __TCPPROTO((int, int, int, const void *, int));
int _System shutdown __TCPPROTO((int, int));
int _System socket __TCPPROTO((int, int, int));
int _System socketpair __TCPPROTO((int, int, int, int *));

/* OS/2 additions */
int _System sock_init __TCPPROTO((void));
int _System sock_errno __TCPPROTO((void));
void _System psock_errno __TCPPROTO((const char *));
char * _System sock_strerror __TCPPROTO((int));
int _System soabort __TCPPROTO((int));
int _System so_cancel __TCPPROTO((int));
int _System getinetversion __TCPPROTO((char *));
void _System addsockettolist __TCPPROTO((int));
int _System removesocketfromlist __TCPPROTO((int));
/*int _System removesocketfromlist __TCPPROTO((long *));*/  /*changed on 09-30-98 for corresponding change in sockets.c file*/

/* SOCKS additions */
int _System Raccept __TCPPROTO((int, struct sockaddr *, int *));
int _System Rbind __TCPPROTO((int, struct sockaddr *, int, struct sockaddr *));
int _System Rconnect __TCPPROTO((int, const struct sockaddr *, int));
int _System Rgetsockname __TCPPROTO((int, struct sockaddr *, int *));
int _System Rlisten __TCPPROTO((int, int));
__END_DECLS


/* more OS/2 stuff */

const
  // should be on free list
  MT_FREE      =  0;
  // dynamic (data) allocation
  MT_DATA      =  1;
  // packet header
  MT_HEADER    =  2;
  // socket structure
  MT_SOCKET    =  3;
  // protocol control block
  MT_PCB       =  4;
  // routing tables
  MT_RTABLE    =  5;
  // IMP host tables
  MT_HTABLE    =  6;
  // address resolution tables
  MT_ATABLE    =  7;
  // socket name
  MT_SONAME    =  8;
  // zombie proc status
  MT_ZOMBIE    =  9;
  // socket options
  MT_SOOPTS    =  10;
  // fragment reassembly header
  MT_FTABLE    =  11;
  // access rights
  MT_RIGHTS    =  12;
  // interface address
  MT_IFADDR    =  13;

Type
  sostats=record
    count: integer;
    socketdata: array[0..13*MAXSOCKETS-1] of integer;
  end;

}

(***************************************************************************)
(*                                                                         *)
(*          SOCE* constants - socket errors from NERRNO.H                  *)
(*  All OS/2 SOCKET API error constants are biased by SOCBASEERR from the  *)
(*                                 "normal"                                *)
(*                                                                         *)
(***************************************************************************)

const
  SOCBASEERR         = 10000;

  // Not owner
  SOCEPERM           = (SOCBASEERR+1);
  // No such file or directory
  SOCENOENT          = (SOCBASEERR+2);
  // No such process
  SOCESRCH           = (SOCBASEERR+3);
  // Interrupted system call
  SOCEINTR           = (SOCBASEERR+4);
  // Input/output error
  SOCEIO             = (SOCBASEERR+5);
  SOCENXIO           = (SOCBASEERR+6);      // No such device or address
  SOCE2BIG           = (SOCBASEERR+7);      // Argument list too long
  SOCENOEXEC         = (SOCBASEERR+8);      // Exec format error
  SOCEBADF           = (SOCBASEERR+9);      // Bad file number
  SOCECHILD          = (SOCBASEERR+10);     // No child processes
  SOCEDEADLK         = (SOCBASEERR+11);     // Resource deadlock avoided
  SOCENOMEM          = (SOCBASEERR+12);     // Cannot allocate memory
  SOCEACCES          = (SOCBASEERR+13);     // Permission denied
  SOCEFAULT          = (SOCBASEERR+14);     // Bad address
  SOCENOTBLK         = (SOCBASEERR+15);     // Block device required
  SOCEBUSY           = (SOCBASEERR+16);     // Device busy
  SOCEEXIST          = (SOCBASEERR+17);     // File exists
  SOCEXDEV           = (SOCBASEERR+18);     // Cross-device link
  SOCENODEV          = (SOCBASEERR+19);     // Operation not supported by device
  SOCENOTDIR         = (SOCBASEERR+20);     // Not a directory
  SOCEISDIR          = (SOCBASEERR+21);     // Is a directory
  SOCEINVAL          = (SOCBASEERR+22);     // Invalid argument
  SOCENFILE          = (SOCBASEERR+23);     // Too many open files in system
  SOCEMFILE          = (SOCBASEERR+24);     // Too many open files
  SOCENOTTY          = (SOCBASEERR+25);     // Inappropriate ioctl for device
  SOCETXTBSY         = (SOCBASEERR+26);     // Text file busy
  SOCEFBIG           = (SOCBASEERR+27);     // File too large
  SOCENOSPC          = (SOCBASEERR+28);     // No space left on device
  SOCESPIPE          = (SOCBASEERR+29);     // Illegal seek
  SOCEROFS           = (SOCBASEERR+30);     // Read-only file system
  SOCEMLINK          = (SOCBASEERR+31);     // Too many links
  SOCEPIPE           = (SOCBASEERR+32);     // Broken pipe

// math software
  SOCEDOM            = (SOCBASEERR+33);     // Numerical argument out of domain
  SOCERANGE          = (SOCBASEERR+34);     // Result too large

// non-blocking and interrupt i/o
  SOCEAGAIN          = (SOCBASEERR+35);     // Resource temporarily unavailable
  SOCEWOULDBLOCK     = SOCEAGAIN;           // Operation would block
  SOCEINPROGRESS     = (SOCBASEERR+36);     // Operation now in progress
  SOCEALREADY        = (SOCBASEERR+37);     // Operation already in progress

// ipc/network software -- argument errors
  SOCENOTSOCK        = (SOCBASEERR+38);     // Socket operation on non-socket
  SOCEDESTADDRREQ    = (SOCBASEERR+39);     // Destination address required
  SOCEMSGSIZE        = (SOCBASEERR+40);     // Message too long
  SOCEPROTOTYPE      = (SOCBASEERR+41);     // Protocol wrong type for socket
  SOCENOPROTOOPT     = (SOCBASEERR+42);     // Protocol not available
  SOCEPROTONOSUPPORT = (SOCBASEERR+43);     // Protocol not supported
  SOCESOCKTNOSUPPORT = (SOCBASEERR+44);     // Socket type not supported
  SOCEOPNOTSUPP      = (SOCBASEERR+45);     // Operation not supported
  SOCEPFNOSUPPORT    = (SOCBASEERR+46);     // Protocol family not supported
  SOCEAFNOSUPPORT    = (SOCBASEERR+47);     // Address family not supported by protocol family
  SOCEADDRINUSE      = (SOCBASEERR+48);     // Address already in use
  SOCEADDRNOTAVAIL   = (SOCBASEERR+49);     // Can't assign requested address

// ipc/network software -- operational errors
  SOCENETDOWN        = (SOCBASEERR+50);     // Network is down
  SOCENETUNREACH     = (SOCBASEERR+51);     // Network is unreachable
  SOCENETRESET       = (SOCBASEERR+52);     // Network dropped connection on reset
  SOCECONNABORTED    = (SOCBASEERR+53);     // Software caused connection abort
  SOCECONNRESET      = (SOCBASEERR+54);     // Connection reset by peer
  SOCENOBUFS         = (SOCBASEERR+55);     // No buffer space available
  SOCEISCONN         = (SOCBASEERR+56);     // Socket is already connected
  SOCENOTCONN        = (SOCBASEERR+57);     // Socket is not connected
  SOCESHUTDOWN       = (SOCBASEERR+58);     // Can't send after socket shutdown
  SOCETOOMANYREFS    = (SOCBASEERR+59);     // Too many references: can't splice
  SOCETIMEDOUT       = (SOCBASEERR+60);     // Operation timed out
  SOCECONNREFUSED    = (SOCBASEERR+61);     // Connection refused

  SOCELOOP           = (SOCBASEERR+62);     // Too many levels of symbolic links
  SOCENAMETOOLONG    = (SOCBASEERR+63);     // File name too long

// should be rearranged
  SOCEHOSTDOWN       = (SOCBASEERR+64);      // Host is down
  SOCEHOSTUNREACH    = (SOCBASEERR+65);      // No route to host
  SOCENOTEMPTY       = (SOCBASEERR+66);      // Directory not empty

// quotas & mush
  SOCEPROCLIM        = (SOCBASEERR+67);      // Too many processes
  SOCEUSERS          = (SOCBASEERR+68);      // Too many users
  SOCEDQUOT          = (SOCBASEERR+69);      // Disc quota exceeded

// Network File System
  SOCESTALE          = (SOCBASEERR+70);      // Stale NFS file handle
  SOCEREMOTE         = (SOCBASEERR+71);      // Too many levels of remote in path
  SOCEBADRPC         = (SOCBASEERR+72);      // RPC struct is bad
  SOCERPCMISMATCH    = (SOCBASEERR+73);      // RPC version wrong
  SOCEPROGUNAVAIL    = (SOCBASEERR+74);      // RPC prog. not avail
  SOCEPROGMISMATCH   = (SOCBASEERR+75);      // Program version wrong
  SOCEPROCUNAVAIL    = (SOCBASEERR+76);      // Bad procedure for program

  SOCENOLCK          = (SOCBASEERR+77);      // No locks available
  SOCENOSYS          = (SOCBASEERR+78);      // Function not implemented

  SOCEFTYPE          = (SOCBASEERR+79);      // Inappropriate file type or format
  SOCEAUTH           = (SOCBASEERR+80);      // Authentication error
  SOCENEEDAUTH       = (SOCBASEERR+81);      // Need authenticator

  SOCEOS2ERR         = (SOCBASEERR+100);     // OS/2 Error
  SOCELAST           = (SOCBASEERR+100);     // Must be equal largest errno

(* !!TODO Add this consts
/*
 * OS/2 SOCKET API errors redefined as regular BSD error constants
 */

#ifndef ENOENT
#define ENOENT                  SOCENOENT
#endif

#ifndef EFAULT
#define EFAULT                  SOCEFAULT
#endif

#ifndef EBUSY
#define EBUSY                   SOCEBUSY
#endif

#ifndef ENXIO
#define ENXIO                   SOCENXIO
#endif

#ifndef EACCES
#define EACCES                  SOCEACCES
#endif

#ifndef ENOMEM
#define ENOMEM                  SOCENOMEM
#endif

#ifndef ENOTDIR
#define ENOTDIR                 SOCENOTDIR
#endif

#ifndef EPERM
#define EPERM                   SOCEPERM
#endif

#ifndef ESRCH
#define ESRCH                   SOCESRCH
#endif

#ifndef EDQUOT
#define EDQUOT                  SOCEDQUOT
#endif

#ifndef EEXIST
#define EEXIST                  SOCEEXIST
#endif

#ifndef EBUSY
#define EBUSY                   SOCEBUSY
#endif

#ifndef EWOULDBLOCK
#define EWOULDBLOCK             SOCEWOULDBLOCK
#endif

#ifndef EINPROGRESS
#define EINPROGRESS             SOCEINPROGRESS
#endif

#ifndef EALREADY
#define EALREADY                SOCEALREADY
#endif

#ifndef ENOTSOCK
#define ENOTSOCK                SOCENOTSOCK
#endif

#ifndef EDESTADDRREQ
#define EDESTADDRREQ            SOCEDESTADDRREQ
#endif

#ifndef EMSGSIZE
#define EMSGSIZE                SOCEMSGSIZE
#endif

#ifndef EPROTOTYPE
#define EPROTOTYPE              SOCEPROTOTYPE
#endif

#ifndef ENOPROTOOPT
#define ENOPROTOOPT             SOCENOPROTOOPT
#endif

#ifndef EPROTONOSUPPORT
#define EPROTONOSUPPORT         SOCEPROTONOSUPPORT
#endif

#ifndef ESOCKTNOSUPPORT
#define ESOCKTNOSUPPORT         SOCESOCKTNOSUPPORT
#endif

#ifndef EOPNOTSUPP
#define EOPNOTSUPP              SOCEOPNOTSUPP
#endif

#ifndef EPFNOSUPPORT
#define EPFNOSUPPORT            SOCEPFNOSUPPORT
#endif

#ifndef EAFNOSUPPORT
#define EAFNOSUPPORT            SOCEAFNOSUPPORT
#endif

#ifndef EADDRINUSE
#define EADDRINUSE              SOCEADDRINUSE
#endif

#ifndef EADDRNOTAVAIL
#define EADDRNOTAVAIL           SOCEADDRNOTAVAIL
#endif

#ifndef ENETDOWN
#define ENETDOWN                SOCENETDOWN
#endif

#ifndef ENETUNREACH
#define ENETUNREACH             SOCENETUNREACH
#endif

#ifndef ENETRESET
#define ENETRESET               SOCENETRESET
#endif

#ifndef ECONNABORTED
#define ECONNABORTED            SOCECONNABORTED
#endif

#ifndef ECONNRESET
#define ECONNRESET              SOCECONNRESET
#endif

#ifndef ENOBUFS
#define ENOBUFS                 SOCENOBUFS
#endif

#ifndef EISCONN
#define EISCONN                 SOCEISCONN
#endif

#ifndef ENOTCONN
#define ENOTCONN                SOCENOTCONN
#endif

#ifndef ESHUTDOWN
#define ESHUTDOWN               SOCESHUTDOWN
#endif

#ifndef ETOOMANYREFS
#define ETOOMANYREFS            SOCETOOMANYREFS
#endif

#ifndef ETIMEDOUT
#define ETIMEDOUT               SOCETIMEDOUT
#endif

#ifndef ECONNREFUSED
#define ECONNREFUSED            SOCECONNREFUSED
#endif

#ifndef ELOOP
#define ELOOP                   SOCELOOP
#endif

#ifndef ENAMETOOLONG            /* Borland and Watcom define this */
#define ENAMETOOLONG            SOCENAMETOOLONG
#endif

#ifndef EHOSTDOWN
#define EHOSTDOWN               SOCEHOSTDOWN
#endif

#ifndef EHOSTUNREACH
#define EHOSTUNREACH            SOCEHOSTUNREACH
#endif

#ifndef ENOTEMPTY               /* Watcom defines this */
#define ENOTEMPTY               SOCENOTEMPTY
#endif

#ifndef EINVAL
#define EINVAL                  SOCEINVAL
#endif

#ifndef EINTR
#define EINTR                   SOCEINTR
#endif

#ifndef EMFILE
#define EMFILE                  SOCEMFILE
#endif

#ifndef EPIPE
#define EPIPE                   SOCEPIPE
#endif
*)

// * bsd select definitions

const
{
 * Select uses bit masks of file descriptors in longs.  These macros
 * manipulate such bit fields (the filesystem macros use chars).
 * FD_SETSIZE may be defined by the user, but the default here should
 * be enough for most uses.
}
  FD_SETSIZE = 64;

type

  fd_set = record
    fd_count  :  Word;                        // how many are SET?
    fd_array  :  array[0..FD_SETSIZE-1] of Longint;   // an array of SOCKETs
  end;

  timeval = record
    tv_sec   :  Longint; // Number of seconds
    tv_usec  :  Longint; // Number of microseconds
  end;




(* !!TODO Check all macros from sys/itypes.h
function  LSwap(a:Longint):Longint;
function  WSwap(a:Word):Word;

{ host -> network for long (4 bytes) }
function  htonl(a:Longint):Longint;

{ network -> host for long (4 bytes) }
function  ntohl(a:Longint):Longint;

{ host -> network for small (2 bytes) }
function  htons(a:Word):Word;

{ network -> host for small (2 bytes) }
function  ntohs(a:Word):Word;

*)

{ * init / misc funcs }

{ init sockets system }
function  sock_init:Longint; cdecl;

{ get inet version. version - buffer of ?? size for returned string. }
function  getinetversion(var version):Longint; cdecl;


{ * sockets errors reporting funcs }

{ last err code for this thread }
function  sock_errno:Longint; cdecl;

{ print last err string + str if not NIL }
procedure psock_errno(const str:PChar); cdecl;


{ * sockets creation / close funcs }

{ create new socket }
function  socket(domain,stype,protocol:Longint):Longint; cdecl;

{ close socket }
function  soclose(sock:Longint):Longint; cdecl;

{ cancel socket }
function  so_cancel(sock:Longint):Longint; cdecl;

{ shutdown socket. howto: 0/1/2 }
function  shutdown(sock,howto:Longint):Longint; cdecl;

{ abort socket. no docs found about it :( }
function  soabort(sock:Longint):Longint; cdecl;

(***************************************************************************)
(*                                                                         *)
(*                         sockets connection funcs                        *)
(*                                                                         *)
(***************************************************************************)

{ accept a connection from remote host. returns s_addr & s_addr_len if not nil }
function accept(sock:Longint; var s_addr:sockaddr; s_addr_len:Longint):Longint; cdecl;

{ bind a local name to the socket }
function bind(sock:Longint; const s_addr: sockaddr; s_addr_len:Longint):Longint; cdecl;

{ connect socket to remote host }
function connect(sock:Longint; const s_addr:sockaddr; s_addr_len:Longint):Longint; cdecl;

{ listen on socket. max_conn - queue size of listen. }
function listen(sock,max_conn:Longint):Longint; cdecl;

(***************************************************************************)
(*                                                                         *)
(*                       sockets read/write funcs                          *)
(*                                                                         *)
(***************************************************************************)

{ read data from socket. ! return N of readed bytes, or 0 (closed) or -1 }
function recv(sock:Longint; var buf; buf_len,flags:Longint):Longint; cdecl;

{ send data to socket. ! return N of sent bytes. -1 - err }
function  send(sock:Longint; const buf; buf_len,flags:Longint):Longint; cdecl;

{ read data from socket. ! return N of readed bytes, or 0 (closed) or -1 }
function  recvfrom(sock:Longint; var buf; buf_len,flags:Longint; var s_addr:sockaddr; var s_addr_len:Longint):Longint; cdecl;

{ send data to socket. ! return N of sent bytes. -1 - err }
function  sendto(sock:Longint; const buf; buf_len,flags:Longint; var s_addr:sockaddr; s_addr_len:Longint):Longint; cdecl;

{ read data into iov_count number of buffers iov.
  ! return N of readed bytes, or 0 (closed) or -1 }
function  readv(sock:Longint; var iov:iovec; iov_count:Longint):LONGINT; cdecl;

{ write data from iov_count number of buffers iov.
  ! return N of writed bytes, or -1 }
function  writev(sock:Longint; var iov:iovec; iov_count:Longint):LONGINT; cdecl;

{ read data + control info from socket
  ! return N of readed bytes, or 0 (closed) or -1 }
function  recvmsg(sock:Longint; var msgbuf:msghdr; flags:Longint):Longint; cdecl;

{ send data + control info to socket
  ! return N of sended bytes, or -1 }
function  sendmsg(sock:Longint; var msgbuf:msghdr; flags:Longint):Longint; cdecl;

(***************************************************************************)
(*                                                                         *)
(*                              select funcs                               *)
(*                                                                         *)
(***************************************************************************)

{ OS/2 select. 0 - timeout. -1 - err. XX - N of sockets worked. }
function  os2_select(var sockets; N_reads, N_writes, N_exepts, timeout:Longint):Longint; cdecl;

{ bsd select here. heavy voodoo.. }
function  select(nfds:Longint; const readfds,writefds,exceptfds:fd_set; const timeout:timeval):Longint; cdecl;

(***************************************************************************)
(*                                                                         *)
(*                                misc info                                *)
(*                                                                         *)
(***************************************************************************)

{ get host ip addr - addr of primary interface }
function gethostid:Longint; cdecl;

{ get connected to socket hostname }
function getpeername(sock:Longint; var s_addr:sockaddr; var s_addr_len:Longint):Longint; cdecl;

{ get local socket name }
function getsockname(sock:Longint; var s_addr:sockaddr; var s_addr_len:Longint):Longint; cdecl;

(***************************************************************************)
(*                                                                         *)
(*                             options & ioctls                            *)
(*                                                                         *)
(***************************************************************************)

{ get socket options }
function getsockopt(sock,level,optname:Longint; var buf; var buf_len:Longint):Longint; cdecl;

{ set socket options }
function  setsockopt(sock,level,optname:Longint; const buf; buf_len:Longint):Longint; cdecl;

{ f@$king ioctl. use sys/ioctl.h }
function os2_ioctl(sock,cmd:Longint; var data; data_len:Longint):Longint; cdecl;

(***************************************************************************)
(*                                                                         *)
(*     functions only for 4.1+ ip stacks (but also found in 4.02w ;))      *)
(*                                                                         *)
(***************************************************************************)


function  addsockettolist(sock:Longint):Longint; cdecl;

function  removesocketfromlist(sock:Longint):Longint; cdecl;

implementation

function  LSwap(a:Longint):Longint; assembler;
asm
      mov   eax,a
      xchg  ah,al
      ror   eax,16
      xchg  ah,al
end;

function  WSwap(a:Word):Word; assembler;
asm
      mov   ax,a
      xchg  ah,al
end;

function accept(sock:Longint; var s_addr: sockaddr; s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 1;
function bind(sock:Longint; const s_addr: sockaddr; s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 2;
function connect(sock:Longint; const s_addr:sockaddr; s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 3;
function gethostid: Longint; cdecl; external 'SO32DLL' index 4;
function getpeername(sock:Longint; var s_addr:sockaddr; var s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 5;
function getsockname(sock:Longint; var s_addr:sockaddr; var s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 6;
function getsockopt(sock,level,optname:Longint; var buf; var buf_len:Longint):Longint; cdecl; external 'SO32DLL' index 7;
function os2_ioctl(sock,cmd:Longint; var data; data_len:Longint):Longint; cdecl; external 'SO32DLL' index 8;
function listen(sock,max_conn:Longint):Longint; cdecl; external 'SO32DLL' index 9;
function recv(sock:Longint; var buf; buf_len,flags:Longint):Longint; cdecl; external 'SO32DLL' index 10;
function  recvfrom(sock:Longint; var buf; buf_len,flags:Longint;var s_addr:sockaddr; var s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 11;
function  os2_select(var sockets; N_reads, N_writes, N_exepts, timeout:Longint):Longint; cdecl; external 'SO32DLL' index 12;
function  send(sock:Longint; const buf; buf_len,flags:Longint):Longint; cdecl; external 'SO32DLL' index 13;
function  sendto(sock:Longint; const buf; buf_len,flags:Longint;var s_addr:sockaddr; s_addr_len:Longint):Longint; cdecl; external 'SO32DLL' index 14;
function  setsockopt(sock,level,optname:Longint; const buf; buf_len:Longint):Longint; cdecl; external 'SO32DLL' index 15;
function  socket(domain,stype,protocol:Longint):Longint; cdecl; external 'SO32DLL' index 16;
function  soclose(sock:Longint):Longint; cdecl; external 'SO32DLL' index 17;
function  so_cancel(sock:Longint):Longint; cdecl; external 'SO32DLL' index 18;
function  soabort(sock:Longint):Longint; cdecl; external 'SO32DLL' index 19;
function  sock_errno:Longint; cdecl; external 'SO32DLL' index 20;
function  recvmsg(sock:Longint; var msgbuf:msghdr; flags:Longint):Longint; cdecl; external 'SO32DLL' index 21;
function  sendmsg(sock:Longint; var msgbuf:msghdr; flags:Longint):Longint; cdecl; external 'SO32DLL' index 22;
function  readv(sock:Longint; var iov:iovec; iov_count:Longint):LONGINT; cdecl; external 'SO32DLL' index 23;
function  writev(sock:Longint; var iov:iovec; iov_count:Longint):LONGINT; cdecl; external 'SO32DLL' index 24;
function  shutdown(sock,howto:Longint):Longint; cdecl; external 'SO32DLL' index 25;
function  sock_init:Longint; cdecl; external 'SO32DLL' index 26;
function  addsockettolist(sock:Longint):Longint; cdecl; external 'SO32DLL' index 27;
function  removesocketfromlist(sock:Longint):Longint; cdecl; external 'SO32DLL' index 28;
{ entry 29 not used }
procedure psock_errno(const str:PChar); cdecl; external 'SO32DLL' index 30;
function  getinetversion(var version):Longint; cdecl; external 'SO32DLL' index 31;
function  select(nfds:Longint;
                 const readfds,writefds,exceptfds:fd_set;
                 const timeout:timeval):Longint; cdecl; external 'SO32DLL' index 32;


function  htonl(a:Longint):Longint;
begin   Result:=LSwap(a);   end;
{ host -> network for long (4 bytes) }

function  ntohl(a:Longint):Longint;
begin   Result:=LSwap(a);   end;
{ network -> host for long (4 bytes) }

function  htons(a:Word):Word;
begin   Result:=WSwap(a);   end;
{ host -> network for small (2 bytes) }

function  ntohs(a:Word):Word;
begin   Result:=WSwap(a);   end;
{ network -> host for small (2 bytes) }

end.
