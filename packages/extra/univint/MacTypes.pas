{
     File:       CarbonCore/MacTypes.h
 
     Contains:   Basic Macintosh data types.
 
     Version:    CarbonCore-654.0.85~1
 
     Copyright:  � 1985-2005 by Apple Computer, Inc., all rights reserved.
 
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

unit MacTypes;
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
uses ConditionalMacros;


{$ALIGN MAC68K}


{*******************************************************************************

    Base integer types for all target OS's and CPU's
    
        UInt8            8-bit unsigned integer 
        SInt8            8-bit signed integer
        UInt16          16-bit unsigned integer 
        SInt16          16-bit signed integer           
        UInt32          32-bit unsigned integer 
        SInt32          32-bit signed integer   
        UInt64          64-bit unsigned integer 
        SInt64          64-bit signed integer   

********************************************************************************}
type
    SInt8 = ShortInt;
    UInt8 = Byte;
    SInt16 = Integer;
    UInt16 = Word;
    SInt32 = LongInt;
    UInt32 = Longword;
    SInt64 = Int64;
    UInt64 = QWord;



{$ifc TARGET_RT_BIG_ENDIAN}

type
	wide = record
		case boolean of
			false:
				( hi:		SInt32;
					lo:		UInt32);
			true:
				( int:	SInt64)
	end;

	UnsignedWide = record
		case boolean of
			false:
				( hi:		UInt32;
					lo:		UInt32);
			true:
				( int:	UInt64)
	end;

{$elsec}

type
	wide = record
		case boolean of
			false:
				( lo:		UInt32;
					hi:		SInt32);
			true:
				( int:	SInt64)
	end;

	UnsignedWide = record
		case boolean of
			false:
				( lo:		UInt32;
					hi:		UInt32);
			true:
				( int:	UInt64)
	end;

{$endc}  {TARGET_RT_BIG_ENDIAN}



type
    SInt8Ptr = ^SInt8;
    UInt8Ptr = ^UInt8;
    SInt16Ptr = ^SInt16;
    UInt16Ptr = ^UInt16;
    SInt32Ptr = ^SInt32;
    UInt32Ptr = ^UInt32;
    SInt64Ptr = ^SInt64;
    UInt64Ptr = ^UInt64;
    widePtr = ^wide;
    UnsignedWidePtr = ^UnsignedWide;

	{	*******************************************************************************
	
	    Special types for pascal
	    
	        ByteParameter       UInt8 passed as an 8-bit parameter
	        
	    Note:   The conventions for Pascal on 68K require that a UInt8 when
	            passed as a parameter occupy 16-bits on the stack, whereas 
	            an SInt8 would only occupy 8-bits.  To make C and Pascal
	            compatable, in pascal all function parameters of type UInt8
	            or equivalent are changed to ByteParameter.
	
	********************************************************************************	}
	ByteParameter = SInt8;

// For interfaces that use Cs "bool" type, which is a 32 bit number
	CBool = SInt32; 

{*******************************************************************************

    Base fixed point types 
    
        Fixed           16-bit signed integer plus 16-bit fraction
        UnsignedFixed   16-bit unsigned integer plus 16-bit fraction
        Fract           2-bit signed integer plus 30-bit fraction
        ShortFixed      8-bit signed integer plus 8-bit fraction
        
********************************************************************************}
type
	Fixed = SInt32;
	FixedPtr = ^Fixed;
	Fract = SInt32;
	FractPtr = ^Fract;
	UnsignedFixed = UInt32;
	UnsignedFixedPtr = ^UnsignedFixed;
	ShortFixed = SInt16;
	ShortFixedPtr = ^ShortFixed;


{*******************************************************************************

    Base floating point types 
    
        Float32         32 bit IEEE float:  1 sign bit, 8 exponent bits, 23 fraction bits
        Float64         64 bit IEEE float:  1 sign bit, 11 exponent bits, 52 fraction bits  
        Float80         80 bit MacOS float: 1 sign bit, 15 exponent bits, 1 integer bit, 63 fraction bits
        Float96         96 bit 68881 float: 1 sign bit, 15 exponent bits, 16 pad bits, 1 integer bit, 63 fraction bits
        
    Note: These are fixed size floating point types, useful when writing a floating
          point value to disk.  If your compiler does not support a particular size 
          float, a struct is used instead.
          Use of of the NCEG types (e.g. double_t) or an ANSI C type (e.g. double) if
          you want a floating point representation that is natural for any given
          compiler, but might be a different size on different compilers.

********************************************************************************}
type
	Float32 = Single;
	Float32Ptr = ^Float32;
	Float64 = Double;
	Float64Ptr = ^Float64;
	LongDouble = Double;
	Float80 = record
		exp: SInt16;
		man: array [0..3] of UInt16;
	end;

type
	Float96 = record
		exp: SInt16;
		filler: SInt16;
		man: array [0..3] of UInt16;
	end;
type
	Float32Point = record
		x: Float32;
		y: Float32;
	end;

{*******************************************************************************
	Unix compatibility types        
********************************************************************************}
type
	size_t = UInt32;
	size_t_ptr = ^size_t;
	ssize_t = SInt32;
	ssize_t_ptr = ^ssize_t;

{*******************************************************************************

    MacOS Memory Manager types
    
        Ptr             Pointer to a non-relocatable block
        Handle          Pointer to a master pointer to a relocatable block
        Size            The number of bytes in a block (signed for historical reasons)
        
********************************************************************************}
type
	Ptr = ^SInt8;
	PtrPtr = ^Ptr;       
	Handle = ^Ptr;
	Handle_fix = Handle; { used as field type when a record declaration contains a Handle field identifier }
	Size = SInt32;
	Size_fix = Size; { used as field type when a record declaration contains a Size field identifier }
	SizePtr = ^Size;
	UnivPtr = Pointer;
	UnivPtrPtr = ^UnivPtr;

{*******************************************************************************

    Higher level basic types
    
        OSErr                   16-bit result error code
        OSStatus                32-bit result error code
        LogicalAddress          Address in the clients virtual address space
        ConstLogicalAddress     Address in the clients virtual address space that will only be read
        PhysicalAddress         Real address as used on the hardware bus
        BytePtr                 Pointer to an array of bytes
        ByteCount               The size of an array of bytes
        ByteOffset              An offset into an array of bytes
        ItemCount               32-bit iteration count
        OptionBits              Standard 32-bit set of bit flags
        PBVersion               ?
        Duration                32-bit millisecond timer for drivers
        AbsoluteTime            64-bit clock
        ScriptCode              A particular set of written characters (e.g. Roman vs Cyrillic) and their encoding
        LangCode                A particular language (e.g. English), as represented using a particular ScriptCode
        RegionCode              Designates a language as used in a particular region (e.g. British vs American
                                English) together with other region-dependent characteristics (e.g. date format)
        FourCharCode            A 32-bit value made by packing four 1 byte characters together
        OSType                  A FourCharCode used in the OS and file system (e.g. creator)
        ResType                 A FourCharCode used to tag resources (e.g. 'DLOG')
        
********************************************************************************}
type
	OSErr = SInt16;
	OSStatus = SInt32;
	LogicalAddress = UnivPtr;
	ConstLogicalAddress = UnivPtr;
	PhysicalAddress = UnivPtr;
	BytePtr = UInt8Ptr;
	ByteCount = UInt32;
 	ByteCountPtr = ^ByteCount;
	ByteOffset = UInt32;
 	ByteOffsetPtr = ^ByteOffset;
	Duration = SInt32;
	AbsoluteTime = UnsignedWide;
	AbsoluteTimePtr = ^AbsoluteTime;
	OptionBits = UInt32;
	OptionBitsPtr = ^OptionBits;
	ItemCount = UInt32;
 	ItemCountPtr = ^ItemCount;
	PBVersion = UInt32;
	ScriptCode = SInt16;
 	ScriptCodePtr = ^ScriptCode;
	LangCode = SInt16;
 	LangCodePtr = ^LangCode;
	RegionCode = SInt16;
 	RegionCodePtr = ^RegionCode;
	FourCharCode = UInt32;
	OSType = FourCharCode;
	OSType_fix = OSType; { used as field type when a record declaration contains a OSType field identifier }
	ResType = FourCharCode;
	OSTypePtr = ^OSType;
	ResTypePtr = ^ResType;
{*******************************************************************************

    Boolean types and values
    
        Boolean         Mac OS historic type, sizeof(Boolean)==1
        bool            Defined in stdbool.h, ISO C/C++ standard type
        false           Now defined in stdbool.h
        true            Now defined in stdbool.h
        
********************************************************************************}
type
{ "Boolean", "true", and "false" are built into the Pascal language }
	BooleanPtr = ^Boolean;
	boolean_fix = boolean; { used as field type when a record declaration contains a boolean field identifier }
{*******************************************************************************

    Function Pointer Types
    
        ProcPtr                 Generic pointer to a function
        Register68kProcPtr      Pointer to a 68K function that expects parameters in registers
        UniversalProcPtr        Pointer to classic 68K code or a RoutineDescriptor
        
        ProcHandle              Pointer to a ProcPtr
        UniversalProcHandle     Pointer to a UniversalProcPtr
        
********************************************************************************}
type
	ProcPtr = Ptr;
	Register68kProcPtr = ProcPtr;
	UniversalProcPtr = ProcPtr;

type
	ProcHandle = ^ProcPtr;
	UniversalProcHandle = ^UniversalProcPtr;


{*******************************************************************************

    Common Constants
    
        noErr                   OSErr: function performed properly - no error
        kNilOptions             OptionBits: all flags false
        kInvalidID              KernelID: NULL is for pointers as kInvalidID is for ID's
        kVariableLengthArray    array bounds: variable length array

    Note: kVariableLengthArray is used in array bounds to specify a variable length array.
          It is ususally used in variable length structs when the last field is an array
          of any size.  Before ANSI C, we used zero as the bounds of variable length 
          array, but zero length array are illegal in ANSI C.  Example usage:
    
        struct FooList 
        (
            short   listLength;
            Foo     elements[kVariableLengthArray];
        );
        
********************************************************************************}
const
	noErr = 0;

const
	kNilOptions = 0;

const
	kInvalidID = 0;
const
	kVariableLengthArray = 1;

const
	kUnknownType = $3F3F3F3F; { "????" QuickTime 3.0: default unknown ResType or OSType }


{*******************************************************************************

    String Types and Unicode Types
    
        UnicodeScalarValue,     A complete Unicode character in UTF-32 format, with
        UTF32Char               values from 0 through 0x10FFFF (excluding the surrogate
                                range 0xD800-0xDFFF and certain disallowed values).

        UniChar,                A 16-bit Unicode code value in the default UTF-16 format.
        UTF16Char               UnicodeScalarValues 0-0xFFFF are expressed in UTF-16
                                format using a single UTF16Char with the same value.
                                UnicodeScalarValues 0x10000-0x10FFFF are expressed in
                                UTF-16 format using a pair of UTF16Chars - one in the
                                high surrogate range (0xD800-0xDBFF) followed by one in
                                the low surrogate range (0xDC00-0xDFFF). All of the
                                characters defined in Unicode versions through 3.0 are
                                in the range 0-0xFFFF and can be expressed using a single
                                UTF16Char, thus the term "Unicode character" generally
                                refers to a UniChar = UTF16Char.

        UTF8Char                An 8-bit code value in UTF-8 format. UnicodeScalarValues
                                0-0x7F are expressed in UTF-8 format using one UTF8Char
                                with the same value. UnicodeScalarValues above 0x7F are
                                expressed in UTF-8 format using 2-4 UTF8Chars, all with
                                values in the range 0x80-0xF4 (UnicodeScalarValues
                                0x100-0xFFFF use two or three UTF8Chars,
                                UnicodeScalarValues 0x10000-0x10FFFF use four UTF8Chars).

        UniCharCount            A count of UTF-16 code values in an array or buffer.

        StrNNN                  Pascal string holding up to NNN bytes
        StringPtr               Pointer to a pascal string
        StringHandle            Pointer to a StringPtr
        ConstStringPtr          Pointer to a read-only pascal string
        ConstStrNNNParam        For function parameters only - means string is const
        
        CStringPtr              Pointer to a C string           (in C:  char*)
        ConstCStringPtr         Pointer to a read-only C string (in C:  const char*)
        
    Note: The length of a pascal string is stored as the first byte.
          A pascal string does not have a termination byte.
          A pascal string can hold at most 255 bytes of data.
          The first character in a pascal string is offset one byte from the start of the string. 
          
          A C string is terminated with a byte of value zero.  
          A C string has no length limitation.
          The first character in a C string is the zeroth byte of the string. 
          
        
********************************************************************************}
type
	UnicodeScalarValue = UInt32;
	UTF32Char = UInt32;
	UniChar = UInt16;
	UTF16Char = UInt16;
	UTF8Char = UInt8;
	UniCharPtr = ^UniChar;
	ConstUniCharPtr = UniCharPtr;
	UniCharCount = UInt32;
	UniCharCountPtr = ^UniCharCount;
	Str15 = STRING[15];
	Str27 = STRING[27];
	Str31 = STRING[31];
	Str32 = STRING[32];
	Str36 = STRING[36];
	Str63 = STRING[63];
	Str255 = STRING[255];
	{	
	    The type Str32 is used in many AppleTalk based data structures.
	    It holds up to 32 one byte chars.  The problem is that with the
	    length byte it is 33 bytes long.  This can cause weird alignment
	    problems in structures.  To fix this the type "Str32Field" has
	    been created.  It should only be used to hold 32 chars, but
	    it is 34 bytes long so that there are no alignment problems.
		}
    Str32Field = Str32;
	{	
	    QuickTime 3.0:
	    The type StrFileName is used to make MacOS structs work 
	    cross-platform.  For example FSSpec or SFReply previously
	    contained a Str63 field.  They now contain a StrFileName
	    field which is the same when targeting the MacOS but is
	    a 256 char buffer for Win32 and unix, allowing them to
	    contain long file names.
		}
type
	StrFileName = Str63;
	StringPtr = ^Str255;
	StringHandle = ^StringPtr;
	ConstStringPtr = StringPtr;
	CStringPtr = PChar;
	ConstCStringPtr = CStringPtr;
	CStringPtrPtr = ^CStringPtr;
	ConstCStringPtrPtr = ^ConstCStringPtr;
	ConstStr255Param = Str255;
	ConstStr63Param = Str63;
	ConstStr36Param = Str36;
	ConstStr32Param = Str32;
	ConstStr31Param = Str31;
	ConstStr27Param = Str27;
	ConstStr15Param = Str15;
	ConstStrFileNameParam = ConstStr63Param;

{*******************************************************************************

    Process Manager type ProcessSerialNumber (previously in Processes.h)

********************************************************************************}
{ type for unique process identifier }
type
	ProcessSerialNumber = record
		highLongOfPSN: UInt32;
		lowLongOfPSN: UInt32;
	end;
	ProcessSerialNumberPtr = ^ProcessSerialNumber;
{*******************************************************************************

    Quickdraw Types
    
        Point               2D Quickdraw coordinate, range: -32K to +32K
        Rect                Rectangular Quickdraw area
        Style               Quickdraw font rendering styles
        StyleParameter      Style when used as a parameter (historical 68K convention)
        StyleField          Style when used as a field (historical 68K convention)
        CharParameter       Char when used as a parameter (historical 68K convention)
        
    Note:   The original Macintosh toolbox in 68K Pascal defined Style as a SET.  
            Both Style and CHAR occupy 8-bits in packed records or 16-bits when 
            used as fields in non-packed records or as parameters. 
        
********************************************************************************}
type
	Point = record
		case SInt16 of
		0: (
			v: SInt16;
			h: SInt16;
		   );
		1: (
			vh: array [0..1] of SInt16;
			);
	end;
	PointPtr = ^Point;
type
	Rect = record
		case SInt16 of
		0: (
			top: SInt16;
			left: SInt16;
			bottom: SInt16;
			right: SInt16;
		   );
		1: (
			topLeft: Point;
			botRight: Point;
		   );
	end;
	RectPtr = ^Rect;
type
	FixedPoint = record
		x: Fixed;
		y: Fixed;
	end;
	FixedPointPtr = ^FixedPoint;
type
	FixedRect = record
		left: Fixed;
		top: Fixed;
		right: Fixed;
		bottom: Fixed;
	end;
	FixedRectPtr = ^FixedRect;

type
	CharParameter = Char;
const
	normal = 0;
	bold = 1;
	italic = 2;
	underline = 4;
	outline = 8;
	shadow = $10;
	condense = $20;
	extend = $40;

type
	Style = SInt8;
	Style_fix = Style; { used as field type when a record declaration contains a Style field identifier }
	StyleParameter = SInt16;
	StyleField = Style;


{*******************************************************************************

    QuickTime TimeBase types (previously in Movies.h)
    
        TimeValue           Count of units
        TimeScale           Units per second
        CompTimeValue       64-bit count of units (always a struct) 
        TimeValue64         64-bit count of units (long long or struct) 
        TimeBase            An opaque reference to a time base
        TimeRecord          Package of TimeBase, duration, and scale
        
********************************************************************************}
type
	TimeValue = SInt32;
	TimeScale = SInt32;
	TimeScale_fix = TimeScale; { used as field type when a record declaration contains a TimeScale field identifier }
	CompTimeValue = wide;
	CompTimeValuePtr = ^CompTimeValue;
	TimeValue64 = SInt64;
	TimeValue64Ptr = ^TimeValue64;
	TimeBase = ^SInt32; { an opaque 32-bit type }
	TimeBase_fix = TimeBase; { used as field type when a record declaration contains a TimeBase field identifier }
	TimeBasePtr = ^TimeBase;
	TimeRecord = record
		value: CompTimeValue;                  { units (duration or absolute) }
		scale: TimeScale;                  { units per second }
		base: TimeBase;                   { refernce to the time base }
	end;
	TimeRecordPtr = ^TimeRecord;

{*******************************************************************************

    MacOS versioning structures
    
        VersRec                 Contents of a 'vers' resource
        VersRecPtr              Pointer to a VersRecPtr
        VersRecHndl             Resource Handle containing a VersRec
        NumVersion              Packed BCD version representation (e.g. "4.2.1a3" is 0x04214003)
        UniversalProcPtr        Pointer to classic 68K code or a RoutineDescriptor
        
        ProcHandle              Pointer to a ProcPtr
        UniversalProcHandle     Pointer to a UniversalProcPtr
        
********************************************************************************}
{$ifc TARGET_RT_BIG_ENDIAN}
type
	NumVersion = packed record
{ Numeric version part of 'vers' resource }
		majorRev: UInt8;               {1st part of version number in BCD}
		minorAndBugRev: UInt8;         {2nd & 3rd part of version number share a byte}
		stage: UInt8;                  {stage code: dev, alpha, beta, final}
		nonRelRev: UInt8;              {revision level of non-released version}
	end;
{$elsec}
type
	NumVersion = packed record
{ Numeric version part of 'vers' resource accessable in little endian format }
		nonRelRev: UInt8;              {revision level of non-released version}
		stage: UInt8;                  {stage code: dev, alpha, beta, final}
		minorAndBugRev: UInt8;         {2nd & 3rd part of version number share a byte}
		majorRev: UInt8;               {1st part of version number in BCD}
	end;
{$endc}  {TARGET_RT_BIG_ENDIAN}
	NumVersionPtr = ^NumVersion;

const
{ Version Release Stage Codes }
	developStage = $20;
	alphaStage = $40;
	betaStage = $60;
	finalStage = $80;

type
	NumVersionVariant = record
		case SInt16 of
																		{  NumVersionVariant is a wrapper so NumVersion can be accessed as a 32-bit value  }
		0: (
			parts:				NumVersion;
			);
		1: (
			whole:				UInt32;
			);
	end;
	NumVersionVariantPtr = ^NumVersionVariant;
	NumVersionVariantHandle = ^NumVersionVariantPtr;
	VersRec = record
{ 'vers' resource format }
		numericVersion: NumVersion;         {encoded version number}
		countryCode: SInt16;            {country code from intl utilities}
		shortVersion: Str255;           {version number string - worst case}
		reserved: Str255;               {longMessage string packed after shortVersion}
	end;
	VersRecPtr = ^VersRec;
type
	VersRecHndl = ^VersRecPtr;
{********************************************************************************

    Old names for types
        
********************************************************************************}
type
	Byte = UInt8;
	SignedByte = SInt8;
	extended80 = Float80;
	extended80Ptr = ^extended80;
	extended96 = Float96;
	extended96Ptr = ^extended96;
	VHSelect = SInt8;
{********************************************************************************

    Debugger functions
    
********************************************************************************}
{
 *  Debugger()
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in CoreServices.framework
 *    CarbonLib:        in CarbonLib 1.0 and later
 *    Non-Carbon CFM:   in InterfaceLib 7.1 and later
 }
procedure Debugger; external name '_Debugger';
(* AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER *)


{
 *  DebugStr()
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in CoreServices.framework
 *    CarbonLib:        in CarbonLib 1.0 and later
 *    Non-Carbon CFM:   in InterfaceLib 7.1 and later
 }
procedure DebugStr( const (*var*) debuggerMsg: Str255 ); external name '_DebugStr';
(* AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER *)


{
 *  debugstr()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in InterfaceLib 7.1 and later
 }


{ Only for Mac OS native drivers }
{
 *  SysDebug()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in DriverServicesLib 1.0 and later
 }


{
 *  SysDebugStr()
 *  
 *  Availability:
 *    Mac OS X:         not available
 *    CarbonLib:        not available
 *    Non-Carbon CFM:   in DriverServicesLib 1.0 and later
 }



{ SADE break points }
{
 *  SysBreak()
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in CoreServices.framework
 *    CarbonLib:        in CarbonLib 1.0 and later
 *    Non-Carbon CFM:   in InterfaceLib 7.1 and later
 }
procedure SysBreak; external name '_SysBreak';
(* AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER *)


{
 *  SysBreakStr()
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in CoreServices.framework
 *    CarbonLib:        in CarbonLib 1.0 and later
 *    Non-Carbon CFM:   in InterfaceLib 7.1 and later
 }
procedure SysBreakStr( const (*var*) debuggerMsg: Str255 ); external name '_SysBreakStr';
(* AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER *)


{
 *  SysBreakFunc()
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in CoreServices.framework
 *    CarbonLib:        in CarbonLib 1.0 and later
 *    Non-Carbon CFM:   in InterfaceLib 7.1 and later
 }
procedure SysBreakFunc( const (*var*) debuggerMsg: Str255 ); external name '_SysBreakFunc';
(* AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER *)






end.
