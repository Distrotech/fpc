{
     File:       CFNetwork/CFHost.h
 
     Contains:   CoreFoundation CFHost header
 
     Version:    CFNetwork-71.2~1
 
     Copyright:  � 2001-2003 by Apple Computer, Inc., all rights reserved
 
     Bugs?:      For bug reports, consult the following page on
                 the World Wide Web:
 
                     http://www.freepascal.org/bugs.html
 
}
{	  Pascal Translation:  Peter N Lewis, <peter@stairways.com.au>, 2004 }


{
    Modified for use with Free Pascal
    Version 200
    Please report any bugs to <gpc@microbizz.nl>
}

{$mode macpas}
{$packenum 1}
{$macro on}
{$inline on}
{$CALLING MWPASCAL}

unit CFHost;
interface
{$setc UNIVERSAL_INTERFACES_VERSION := $0342}
{$setc GAP_INTERFACES_VERSION := $0200}

{$ifc not defined USE_CFSTR_CONSTANT_MACROS}
    {$setc USE_CFSTR_CONSTANT_MACROS := TRUE}
{$endc}

{$ifc defined CPUPOWERPC and defined CPUI386}
	{$error Conflicting initial definitions for CPUPOWERPC and CPUI386}
{$endc}
{$ifc defined FPC_BIG_ENDIAN and defined FPC_LITTLE_ENDIAN}
	{$error Conflicting initial definitions for FPC_BIG_ENDIAN and FPC_LITTLE_ENDIAN}
{$endc}

{$ifc not defined __ppc__ and defined CPUPOWERPC}
	{$setc __ppc__ := 1}
{$elsec}
	{$setc __ppc__ := 0}
{$endc}
{$ifc not defined __i386__ and defined CPUI386}
	{$setc __i386__ := 1}
{$elsec}
	{$setc __i386__ := 0}
{$endc}

{$ifc defined __ppc__ and __ppc__ and defined __i386__ and __i386__}
	{$error Conflicting definitions for __ppc__ and __i386__}
{$endc}

{$ifc defined __ppc__ and __ppc__}
	{$setc TARGET_CPU_PPC := TRUE}
	{$setc TARGET_CPU_X86 := FALSE}
{$elifc defined __i386__ and __i386__}
	{$setc TARGET_CPU_PPC := FALSE}
	{$setc TARGET_CPU_X86 := TRUE}
{$elsec}
	{$error Neither __ppc__ nor __i386__ is defined.}
{$endc}
{$setc TARGET_CPU_PPC_64 := FALSE}

{$ifc defined FPC_BIG_ENDIAN}
	{$setc TARGET_RT_BIG_ENDIAN := TRUE}
	{$setc TARGET_RT_LITTLE_ENDIAN := FALSE}
{$elifc defined FPC_LITTLE_ENDIAN}
	{$setc TARGET_RT_BIG_ENDIAN := FALSE}
	{$setc TARGET_RT_LITTLE_ENDIAN := TRUE}
{$elsec}
	{$error Neither FPC_BIG_ENDIAN nor FPC_LITTLE_ENDIAN are defined.}
{$endc}
{$setc ACCESSOR_CALLS_ARE_FUNCTIONS := TRUE}
{$setc CALL_NOT_IN_CARBON := FALSE}
{$setc OLDROUTINENAMES := FALSE}
{$setc OPAQUE_TOOLBOX_STRUCTS := TRUE}
{$setc OPAQUE_UPP_TYPES := TRUE}
{$setc OTCARBONAPPLICATION := TRUE}
{$setc OTKERNEL := FALSE}
{$setc PM_USE_SESSION_APIS := TRUE}
{$setc TARGET_API_MAC_CARBON := TRUE}
{$setc TARGET_API_MAC_OS8 := FALSE}
{$setc TARGET_API_MAC_OSX := TRUE}
{$setc TARGET_CARBON := TRUE}
{$setc TARGET_CPU_68K := FALSE}
{$setc TARGET_CPU_MIPS := FALSE}
{$setc TARGET_CPU_SPARC := FALSE}
{$setc TARGET_OS_MAC := TRUE}
{$setc TARGET_OS_UNIX := FALSE}
{$setc TARGET_OS_WIN32 := FALSE}
{$setc TARGET_RT_MAC_68881 := FALSE}
{$setc TARGET_RT_MAC_CFM := FALSE}
{$setc TARGET_RT_MAC_MACHO := TRUE}
{$setc TYPED_FUNCTION_POINTERS := TRUE}
{$setc TYPE_BOOL := FALSE}
{$setc TYPE_EXTENDED := FALSE}
{$setc TYPE_LONGLONG := TRUE}
uses MacTypes,CFBase,CFData,CFArray,CFRunLoop,CFStream;
{$ALIGN MAC68K}

{
 *  CFHostRef
 *  
 *  Discussion:
 *    This is the type of a reference to a host name or address lookup.
 }
type
	CFHostRef    = ^SInt32; { an opaque 32-bit type }

{
 *  kCFStreamErrorDomainNetDB
 *  
 *  Discussion:
 *    Errors listed in netdb.h
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
var kCFStreamErrorDomainNetDB: SInt32; external name '_kCFStreamErrorDomainNetDB'; (* attribute const *)


{
 *  kCFStreamErrorDomainSystemConfiguration
 *  
 *  Discussion:
 *    Errors listed in SystemConfiguration/SystemConfiguration.h
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
var kCFStreamErrorDomainSystemConfiguration: SInt32; external name '_kCFStreamErrorDomainSystemConfiguration'; (* attribute const *)


{
 *  CFHostInfoType
 *  
 *  Discussion:
 *    Host information types to be resolved.
 }
type
	CFHostInfoType = SInt32;
const
  {
   * Results value is a CFArray of CFData's (each being a struct
   * sockaddr)
   }
  kCFHostAddresses              = 0;

  {
   * Results value is a CFArray of CFString's
   }
  kCFHostNames                  = 1;

  {
   * Results value is a CFData wrapping SCNetworkConnectionFlags
   * (defined in SystemConfiguration/SCNetwork.h)
   }
  kCFHostReachability           = 2;


{
 *  CFHostClientContext
 *  
 *  Discussion:
 *    Structure containing the user-defined data and callbacks for
 *    CFHost objects.
 }
type
	CFHostClientContext = record
		{
		 * The version number of the structure type being passed in as a
		 * parameter to the CFHost client function. Valid version number is
		 * currently 0.
		 }
		version: CFIndex;
	
		{
		 * An arbitrary pointer to client-defined data, which can be
		 * associated with the host and is passed to the callbacks.
		 }
		info: Ptr;
	
		{
		 * The callback used to add a retain for the host on the info pointer
		 * for the life of the host, and may be used for temporary references
		 * the host needs to take. This callback returns the actual info
		 * pointer to store in the host, almost always just the pointer
		 * passed as the parameter.
		 }
		retain: CFAllocatorRetainCallBack;
	
		{
		 * The callback used to remove a retain previously added for the host
		 * on the info pointer.
		 }
		release: CFAllocatorReleaseCallBack;
	
		{
		 * The callback used to create a descriptive string representation of
		 * the info pointer (or the data pointed to by the info pointer) for
		 * debugging purposes. This is used by the CFCopyDescription()
		 * function.
		 }
		copyDescription: CFAllocatorCopyDescriptionCallBack;
	end;
	CFHostClientContextPtr = ^CFHostClientContext;

{
 *  CFHostClientCallBack
 *  
 *  Discussion:
 *    Callback function which is called upon error or completion of an
 *    asynchronous resolve.
 *  
 *  Parameters:
 *    
 *    theHost:
 *      Host whose resolution is complete.
 *    
 *    typeInfo:
 *      Enum representing which info resolution is complete.
 *    
 *    error:
 *      Reference to an error structure if the resolution failed.
 *    
 *    info:
 *      Client's info reference which was passed into the client
 *      context.
 }
type CFHostClientCallBack = procedure( theHost: CFHostRef; typeInfo: CFHostInfoType; const (*var*) error: CFStreamError; info: UnivPtr );


{
 *  CFHostGetTypeID()
 *  
 *  Discussion:
 *    Returns the type identifier of all CFHost instances.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostGetTypeID: CFTypeID; external name '_CFHostGetTypeID';


{
 *  CFHostCreateWithName()
 *  
 *  Discussion:
 *    Creates a new host object with the given name.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    allocator:
 *      The CFAllocator which should be used to allocate memory for the
 *      host. If this reference is not a valid CFAllocator, the
 *      behavior is undefined.
 *    
 *    hostname:
 *      A CFStringRef representing the name of the host. Must be
 *      non-NULL.  If this If this reference is not a valid
 *      CFStringRef, the behavior is undefined.
 *  
 *  Result:
 *    A valid CFHostRef which may now be resolved, or NULL if
 *    unsuccessful.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostCreateWithName( allocator: CFAllocatorRef; hostname: CFStringRef ): CFHostRef; external name '_CFHostCreateWithName';


{
 *  CFHostCreateWithAddress()
 *  
 *  Discussion:
 *    Creates a new host object with the given address.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    allocator:
 *      The CFAllocator which should be used to allocate memory for the
 *      host. If this reference is not a valid CFAllocator, the
 *      behavior is undefined.
 *    
 *    addr:
 *      A CFDataRef containing a struct sockaddr which is the address
 *      of the host. Must be non-NULL.  If this If this reference is
 *      not a valid CFDataRef, the behavior is undefined.
 *  
 *  Result:
 *    A valid CFHostRef which may now be resolved, or NULL if
 *    unsuccessful.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostCreateWithAddress( allocator: CFAllocatorRef; addr: CFDataRef ): CFHostRef; external name '_CFHostCreateWithAddress';


{
 *  CFHostCreateCopy()
 *  
 *  Discussion:
 *    Creates a new host object as a copy of host argument.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    alloc:
 *      The CFAllocator which should be used to allocate memory for the
 *      new host. If this reference is not a valid CFAllocator, the
 *      behavior is undefined.
 *    
 *    host:
 *      A CFHostRef representing the original host. Must be non-NULL. 
 *      If this If this reference is not a valid CFHostRef, the
 *      behavior is undefined.
 *  
 *  Result:
 *    A valid CFHostRef which contains a copy of all previously
 *    resolved data from the original.  NULL is returned in the case of
 *    failure.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostCreateCopy( alloc: CFAllocatorRef; host: CFHostRef ): CFHostRef; external name '_CFHostCreateCopy';


{
 *  CFHostStartInfoResolution()
 *  
 *  Discussion:
 *    Performs a lookup for the given host.  It will search for the
 *    requested information if there is no other active request. 
 *    Previously cached information of the given type will be released.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which should be resolved. Must be non-NULL. If
 *      this reference is not a valid CFHostRef, the behavior is
 *      undefined.
 *    
 *    info:
 *      The enum representing the type of information to be retrieved. 
 *      If the value is not a valid type, the behavior is undefined.
 *    
 *    error:
 *      A reference to a CFStreamError structure which will be filled
 *      with any error information should an error occur.  May be set
 *      to NULL if error information is not wanted.
 *  
 *  Result:
 *    Returns TRUE on success and FALSE on failure.  In asynchronous
 *    mode, this function will return immediately.  In synchronous
 *    mode, it will block until the resolve has completed or until the
 *    resolve is cancelled.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostStartInfoResolution( theHost: CFHostRef; info: CFHostInfoType; error: CFStreamErrorPtr ): Boolean; external name '_CFHostStartInfoResolution';


{
 *  CFHostGetAddressing()
 *  
 *  Discussion:
 *    Tries to retrieve the known addresses from the given host.
 *    Returns a CFArrayRef of addresses if known and there were some.
 *    NULL is returned otherwise.  Each address is a CFDataRef wrapping
 *    a struct sockaddr.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *    The function gets the data in a thread-safe manner, but the
 *    resulting data is not safe.  Since it is returned as a matter of
 *    a get opposed to a copy, the data is not safe if the host is
 *    being altered from another thread.
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which contains the relevant information. Must be
 *      non-NULL. If this reference is not a valid CFHostRef, the
 *      behavior is undefined.
 *    
 *    hasBeenResolved:
 *      A reference to a Boolean which returns FALSE if the information
 *      was not available (e.g. CFHostStartInfoResolution has not been
 *      called), otherwise TRUE will be returned.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostGetAddressing( theHost: CFHostRef; var hasBeenResolved: Boolean ): CFArrayRef; external name '_CFHostGetAddressing';


{
 *  CFHostGetNames()
 *  
 *  Discussion:
 *    Tries to retrieve the names/aliases from the given host. Returns
 *    a CFArrayRef of names for the given host.  NULL is returned
 *    otherwise.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *    The function gets the data in a thread-safe manner, but the
 *    resulting data is not safe.  Since it is returned as a matter of
 *    a get opposed to a copy, the data is not safe if the host is
 *    being altered from another thread.
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which contains the relevant information. Must be
 *      non-NULL. If this reference is not a valid CFHostRef, the
 *      behavior is undefined.
 *    
 *    hasBeenResolved:
 *      A reference to a Boolean which returns FALSE if the information
 *      was not available (e.g. CFHostStartInfoResolution has not been
 *      called), otherwise TRUE will be returned.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostGetNames( theHost: CFHostRef; var hasBeenResolved: Boolean ): CFArrayRef; external name '_CFHostGetNames';


{
 *  CFHostGetReachability()
 *  
 *  Discussion:
 *    Tries to retrieve the reachability of the given host. Returns a
 *    CFDataRef which wraps the reachability flags. NULL will be
 *    returned if the value has not been resolved. The possible values
 *    of these flags is declared in SystemConfiguration/SCNetwork.h.
 *    Returns FALSE if the information was not available, otherwise
 *    TRUE will be returned with the results containing the requested
 *    information.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *    The function gets the data in a thread-safe manner, but the
 *    resulting data is not safe.  Since it is returned as a matter of
 *    a get opposed to a copy, the data is not safe if the host is
 *    being altered from another thread.
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which contains the relevant information. Must be
 *      non-NULL. If this reference is not a valid CFHostRef, the
 *      behavior is undefined.
 *    
 *    hasBeenResolved:
 *      A reference to a Boolean which returns FALSE if the information
 *      was not available (e.g. CFHostStartInfoResolution has not been
 *      called), otherwise TRUE will be returned.  can be NULL
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostGetReachability( theHost: CFHostRef; hasBeenResolved: BooleanPtr ): CFDataRef; external name '_CFHostGetReachability';


{
 *  CFHostCancelInfoResolution()
 *  
 *  Discussion:
 *    Cancels an outstanding asynchronous or synchronous resolve.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which is currently resolving.  Must be non-NULL.
 *      If this reference is not a valid CFHostRef, the behavior is
 *      undefined.
 *    
 *    info:
 *      The enum representing which resolution to be canceled.  If the
 *      value is not a valid type, the behavior is undefined.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
procedure CFHostCancelInfoResolution( theHost: CFHostRef; info: CFHostInfoType ); external name '_CFHostCancelInfoResolution';


{
 *  CFHostSetClient()
 *  
 *  Discussion:
 *    Associates a client context and callback function with a
 *    CFHostRef.  This is required for asynchronous usage.  If not set,
 *    resolve will take place synchronously.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which is getting a client.  Must be non-NULL. If
 *      this reference is not a valid CFHostRef, the behavior is
 *      undefined.
 *    
 *    clientCB:
 *      A CFHostClientCallBack which will be called when the resolve
 *      completes or is cancelled.  Use NULL to remove the client
 *      association with a host object.
 *    
 *    clientContext:
 *      A CFHostClientContext which is used to set the contextual
 *      information associated with the host object.  The info pointer
 *      from the struct will be passed to the callback function. If
 *      setting a client, this value must be non-NULL.
 *  
 *  Result:
 *    Returns TRUE if the procedure was a success, otherwise it returns
 *    FALSE.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
function CFHostSetClient( theHost: CFHostRef; clientCB: CFHostClientCallBack; clientContext: CFHostClientContextPtr ): Boolean; external name '_CFHostSetClient';


{
 *  CFHostScheduleWithRunLoop()
 *  
 *  Discussion:
 *    Schedules the given host on a run loop and mode so the client
 *    will receive its callbacks on that loop and mode.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which is being scheduled.  Must be non-NULL. If
 *      this reference is not a valid CFHostRef, the behavior is
 *      undefined.
 *    
 *    runLoop:
 *      A CFRunLoopRef on which the host should be scheduled. Must be
 *      non-NULL.  If this reference is not a valid CFRunLoopRef, the
 *      behavior is undefined.
 *    
 *    runLoopMode:
 *      A CFStringRef which is the mode in which the run loop will be
 *      running when notification occurs.  Must be non-NULL. If this
 *      reference is not a valid CFStringRef, the behavior is undefined.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
procedure CFHostScheduleWithRunLoop( theHost: CFHostRef; runLoop: CFRunLoopRef; runLoopMode: CFStringRef ); external name '_CFHostScheduleWithRunLoop';


{
 *  CFHostUnscheduleFromRunLoop()
 *  
 *  Discussion:
 *    Unschedules the given host from a run loop and mode so the client
 *    will not receive its callbacks on that loop and mode.
 *  
 *  Mac OS X threading:
 *    Thread safe
 *  
 *  Parameters:
 *    
 *    theHost:
 *      The CFHostRef which is being unscheduled.  Must be non-NULL. If
 *      this reference is not a valid CFHostRef, the behavior is
 *      undefined.
 *    
 *    runLoop:
 *      A CFRunLoopRef on which the host is scheduled and should now be
 *      unscheduled.  Must be non-NULL.  If this reference is not a
 *      valid CFRunLoopRef, the behavior is undefined.
 *    
 *    runLoopMode:
 *      A CFStringRef which is the mode in which the host is scheduled
 *      and should be unscheduled.  Must be non-NULL. If this reference
 *      is not a valid CFStringRef, the behavior is undefined.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.3 and later in CoreServices.framework
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   not available
 }
// AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
procedure CFHostUnscheduleFromRunLoop( theHost: CFHostRef; runLoop: CFRunLoopRef; runLoopMode: CFStringRef ); external name '_CFHostUnscheduleFromRunLoop';


end.
