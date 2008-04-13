{
     File:       HIToolbox/Keyboards.h
 
     Contains:   Keyboard API.
 
     Version:    HIToolbox-219.4.81~2
 
     Copyright:  © 1997-2005 by Apple Computer, Inc., all rights reserved
 
     Bugs?:      For bug reports, consult the following page on
                 the World Wide Web:
 
                     http://www.freepascal.org/bugs.html
 
}
{       Pascal Translation Updated:  Peter N Lewis, <peter@stairways.com.au>, August 2005 }
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

unit Keyboards;
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
uses MacTypes, CFBase;
{$ALIGN POWER}


{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}
{  OBSOLETE                                                                        }
{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}
{ These are obsolete.  Carbon does not support these. }
{ Keyboard API Trap Number. Should be moved to Traps.i }
const
	_KeyboardDispatch = $AA7A;

{ Gestalt selector and values for the Keyboard API }
const
	gestaltKeyboardsAttr = $6B626473 (* 'kbds' *);
	gestaltKBPS2Keyboards = 1;
	gestaltKBPS2SetIDToAny = 2;
	gestaltKBPS2SetTranslationTable = 4;

{ Keyboard API Error Codes }
{
   I stole the range blow from the empty space in the Allocation project but should
   be updated to the officially registered range.
}
const
	errKBPS2KeyboardNotAvailable = -30850;
	errKBIlligalParameters = -30851;
	errKBFailSettingID = -30852;
	errKBFailSettingTranslationTable = -30853;
	errKBFailWritePreference = -30854;

{
 *  KBInitialize()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBSetupPS2Keyboard()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBGetPS2KeyboardID()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBIsPS2KeyboardConnected()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBIsPS2KeyboardEnabled()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBGetPS2KeyboardAttributes()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBSetKCAPForPS2Keyboard()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBSetupPS2KeyboardFromLayoutType()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{
 *  KBGetPS2KeyboardLayoutType()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }


{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}
{ Keyboard API constants                                                           }
{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}

{
 *  PhysicalKeyboardLayoutType
 *  
 *  Summary:
 *    Physical keyboard layout types indicate the physical keyboard
 *    layout. They are returned by the KBGetLayoutType API.
 }
type
	PhysicalKeyboardLayoutType = UInt32;
const
{
   * A JIS keyboard layout type.
   }
	kKeyboardJIS = $4A495320 (* 'JIS ' *);

  {
   * An ANSI keyboard layout type.
   }
	kKeyboardANSI = $414E5349 (* 'ANSI' *);

  {
   * An ISO keyboard layout type.
   }
	kKeyboardISO = $49534F20 (* 'ISO ' *);

  {
   * An unknown physical keyboard layout type.
   }
	kKeyboardUnknown = kUnknownType; { '????'}

{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}
{ Keyboard API types                                                               }
{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}

{
 *  KeyboardLayoutRef
 *  
 *  Summary:
 *    The opaque keyboard layout contains information about a keyboard
 *    layout. It is used with the keyboard layout APIs.
 *  
 *  Discussion:
 *    KeyboardLayoutRef APIs follow CoreFoundation function naming
 *    convention. You mustn't release any references you get from APIs
 *    named "Get."
 }
type
	KeyboardLayoutRef = ^SInt32; { an opaque 32-bit type }

{
 *  KeyboardLayoutPropertyTag
 *  
 *  Summary:
 *    Keyboard layout property tags specify the value you want to
 *    retrieve. They are used with the KLGetKeyboardLayoutProperty API.
 }
type
	KeyboardLayoutPropertyTag = UInt32;
const
{
   * The keyboard layout data (const void *).  It is used with the
   * KeyTranslate API.
   }
	kKLKCHRData = 0;

  {
   * The keyboard layout data (const void *).  It is used with the
   * UCKeyTranslate API.
   }
	kKLuchrData = 1;

  {
   * The keyboard layout identifier (KeyboardLayoutIdentifier).
   }
	kKLIdentifier = 2;

  {
   * The keyboard layout icon (IconRef).
   }
	kKLIcon = 3;

  {
   * The localized keyboard layout name (CFStringRef).
   }
	kKLLocalizedName = 4;

  {
   * The keyboard layout name (CFStringRef).
   }
	kKLName = 5;

  {
   * The keyboard layout group identifier (SInt32).
   }
	kKLGroupIdentifier = 6;

  {
   * The keyboard layout kind (KeyboardLayoutKind).
   }
	kKLKind = 7;

  {
   * The language/locale string associated with the keyboard, if any
   * (CFStringRef). This string uses ISO 639 and ISO 3166 codes
   * (examples: "fr", "en_US". Note: The CFStringRef may be NULL for
   * some keyboards.
   }
	kKLLanguageCode = 9;


{
 *  KeyboardLayoutKind
 *  
 *  Summary:
 *    Keyboard layout kinds indicate available keyboard layout formats.
 }
type
	KeyboardLayoutKind = SInt32;
const
{
   * Both KCHR and uchr formats are available.
   }
	kKLKCHRuchrKind = 0;

  {
   * Only KCHR format is avaiable.
   }
	kKLKCHRKind = 1;

  {
   * Only uchr format is available.
   }
	kKLuchrKind = 2;


{
 *  KeyboardLayoutIdentifier
 *  
 *  Summary:
 *    Keyboard layout identifiers specify particular keyboard layouts.
 }
type
	KeyboardLayoutIdentifier = SInt32;
const
	kKLUSKeyboard = 0;

{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}
{ Keyboard API routines                                                            }
{ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ}
{
 *  KBGetLayoutType()
 *  
 *  Summary:
 *    Returns the physical keyboard layout type.
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    iKeyboardType:
 *      The keyboard type ID.  LMGetKbdType().
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.0 and later
 *    Non-Carbon CFM:   in KeyboardsLib 1.0 and later
 }
function KBGetLayoutType( iKeyboardType: SInt16 ): PhysicalKeyboardLayoutType; external name '_KBGetLayoutType';
(* AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER *)


{ iterate keyboard layouts}

{
 *  KLGetKeyboardLayoutCount()
 *  
 *  Summary:
 *    Returns the number of keyboard layouts.
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    oCount:
 *      On exit, the number of keyboard layouts
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLGetKeyboardLayoutCount( var oCount: CFIndex ): OSStatus; external name '_KLGetKeyboardLayoutCount';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


{
 *  KLGetKeyboardLayoutAtIndex()
 *  
 *  Summary:
 *    Retrieves the keyboard layout at the given index.
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    iIndex:
 *      The index of the keyboard layout to retrieve. If the index is
 *      outside the index space of the keyboard layouts (0 to N-1
 *      inclusive, where N is the count of the keyboard layouts), the
 *      behavior is undefined.
 *    
 *    oKeyboardLayout:
 *      On exit, the keyboard layout with the given index.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLGetKeyboardLayoutAtIndex( iIndex: CFIndex; var oKeyboardLayout: KeyboardLayoutRef ): OSStatus; external name '_KLGetKeyboardLayoutAtIndex';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


{
   *** deprecated. ***
   NOTE: "Indexed" is a wrong name, please use "AtIndex"...
   OSStatus KLGetIndexedKeyboardLayout(
                CFIndex                     iIndex,
                KeyboardLayoutRef           *oKeyboardLayout    );
}

{ get keyboard layout info}

{
 *  KLGetKeyboardLayoutProperty()
 *  
 *  Summary:
 *    Retrives property value for the given keyboard layout and tag.
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    iKeyboardLayout:
 *      The keyboard layout to be queried. If this parameter is not a
 *      valid KeyboardLayoutRef, the behavior is undefined.
 *    
 *    iPropertyTag:
 *      The property tag.
 *    
 *    oValue:
 *      On exit, the property value for the given keyboard layout and
 *      tag.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLGetKeyboardLayoutProperty( iKeyboardLayout: KeyboardLayoutRef; iPropertyTag: KeyboardLayoutPropertyTag; var oValue: UnivPtr ): OSStatus; external name '_KLGetKeyboardLayoutProperty';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


{ get keyboard layout with identifier or name}

{
 *  KLGetKeyboardLayoutWithIdentifier()
 *  
 *  Summary:
 *    Retrieves the keyboard layout with the given identifier.
 *  
 *  Discussion:
 *    For now, the identifier is in the range of SInt16 which is
 *    compatible with the Resource Manager resource ID. However, it
 *    will become an arbitrary SInt32 value at some point, so do not
 *    assume it is in SInt16 range or falls into the "script range" of
 *    the resource IDs.
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    iIdentifier:
 *      The keyboard layout identifier.
 *    
 *    oKeyboardLayout:
 *      On exit, the keyboard layout with the given identifier.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLGetKeyboardLayoutWithIdentifier( iIdentifier: KeyboardLayoutIdentifier; var oKeyboardLayout: KeyboardLayoutRef ): OSStatus; external name '_KLGetKeyboardLayoutWithIdentifier';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


{
 *  KLGetKeyboardLayoutWithName()
 *  
 *  Summary:
 *    Retrieves the keyboard layout with the given name.
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    iName:
 *      The keyboard layout name.
 *    
 *    oKeyboardLayout:
 *      On exit, the keyboard layout with the given name.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLGetKeyboardLayoutWithName( iName: CFStringRef; var oKeyboardLayout: KeyboardLayoutRef ): OSStatus; external name '_KLGetKeyboardLayoutWithName';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


{ get/set current keyboard layout of the current group identifier}

{
 *  KLGetCurrentKeyboardLayout()
 *  
 *  Summary:
 *    Retrieves the current keyboard layout.
 *  
 *  Discussion:
 *    Retrieves the current keyboard layout for the current keyboard
 *    script.  To retrive the current keyboard script for Roman
 *    keyboard script, you need to call KeyScript( smRoman |
 *    smKeyForceKeyScriptMask ) then call KLGetCurrentKeyboardLayout().
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    oKeyboardLayout:
 *      On exit, the current keyboard layout.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLGetCurrentKeyboardLayout( var oKeyboardLayout: KeyboardLayoutRef ): OSStatus; external name '_KLGetCurrentKeyboardLayout';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


{
 *  KLSetCurrentKeyboardLayout()
 *  
 *  Summary:
 *    Sets the current keyboard layout.
 *  
 *  Discussion:
 *    Sets the current keyboard layout for the current keyboard script.
 *     Returns "paramErr" when the current keyboard layout is not
 *    Unicode and the specified keyboard layout belongs to Unicode
 *    group.  To set Roman keyboard script's current keyboard layout to
 *    "U.S." for example, you need to call KeyScript( smRoman |
 *    smKeyForceKeyScriptMask ) then call KLSetCurrentKeyboardLayout(
 *    theUSKeyboardLayoutRef ).
 *  
 *  Mac OS X threading:
 *    Not thread safe
 *  
 *  Parameters:
 *    
 *    iKeyboardLayout:
 *      The keyboard layout.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.2 and later in Carbon.framework
 *    CarbonLib:        not available in CarbonLib 1.x, is available on Mac OS X version 10.2 and later
 *    Non-Carbon CFM:   not available
 }
function KLSetCurrentKeyboardLayout( iKeyboardLayout: KeyboardLayoutRef ): OSStatus; external name '_KLSetCurrentKeyboardLayout';
(* AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER *)


end.
