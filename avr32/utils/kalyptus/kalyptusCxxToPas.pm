package kalyptusCxxToPas;

use File::Path;
use File::Basename;

use Carp;
use Ast;
use kdocAstUtil;
use kdocUtil;
use Iter;
use kalyptusDataDict;

use strict;
no strict "subs";

use vars qw/ @clist $host $who $now $gentext %functionId $docTop @functions
	$lib $rootnode $outputdir $opt $debug $typeprefix $eventHandlerCount $constructorCount *CLASS *HEADER *QTCTYPES *KDETYPES /;

my @qtcfunctions;
my %inheritance;
my @typeenums;

my %pasopmap = (
'<<' => ' shl ',
'>>' => ' shr ',
'|' => ' or ',
'&' => ' and '
);

BEGIN
{
@clist = ();

	# Page footer

	$who = kdocUtil::userName();
	$host = kdocUtil::hostName();
	$now = localtime;
	$gentext = "$who\@$host on $now, using kalyptus $main::Version.";

	$docTop =<<EOF
                             -------------------
    begin                : $now
    copyright            : (C) 2000-2001 Lost Highway Ltd. All rights reserved.
    email                : Lost_Highway\@tipitina.demon.co.uk
    generated by         : $gentext
 ***************************************************************************

 ***************************************************************************
 *                                                                         *
 *   This library is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Library General Public License as       *
 *   published by the Free Software Foundation; either version 2 of the    *
 *   License, or (at your option) any later version.                       *
 *                                                                         *
 ***************************************************************************

EOF

}


sub writeDoc
{
	( $lib, $rootnode, $outputdir, $opt ) = @_;

	$debug = $main::debuggen;

	mkpath( $outputdir ) unless -f $outputdir;

	my $file = "$outputdir/qt.pp";
	open( QTCTYPES, ">$file" ) || die "Couldn't create $file\n";
	print QTCTYPES "{***************************************************************************\n";
	print QTCTYPES $docTop,"}\n\n";
	print QTCTYPES "unit qt;\n\n";
	print QTCTYPES "  interface\n\n";
	print QTCTYPES "    {\$i qt_extra.inc}\n\n";
	print QTCTYPES "// typedef void (*qt_UserDataCallback)(void *, void *);\n";
	print QTCTYPES "// typedef int  (*qt_eventFilter)(qt_QObject*,qt_QEvent*);\n";
	print QTCTYPES "// typedef int (*qt_EventDelegate)(void *, char *, void *, char *);\n";
	print QTCTYPES "// extern qt_EventDelegate Qt_EventDelegate;\n";

	$file = "$outputdir/kde.pp";
	open( KDETYPES, ">$file" ) || die "Couldn't create $file\n";
	print KDETYPES "{***************************************************************************\n";
	print KDETYPES "                            kde_types.pas -  description\n";
	print KDETYPES $docTop,"}\n\n";
	print KDETYPES "unit kde;\n\n";
	print KDETYPES "  interface\n\n";
	print KDETYPES "    type\n";

	# Document all compound nodes
	Iter::LocalCompounds( $rootnode, sub { writeClassDoc( shift ); } );

	# write all classes sorted by inheritance

#	my @inheritance_sorted = sort {
#		    if ($inheritance{$a} eq "") {
#  		      if ($inheritance{$b} eq "") {
#		        return 0;
#		      } else {
#  		        return -1;
#  		      }
#		    } else {
# 		      if ($inheritance{$b} eq "") {
#  		        return 1;
#    		      }
#    		    }
#        	    my $parent=$inheritance{$a};
#        	    while ($parent ne "") {
#        	      if ($parent eq $b) {
#        	        return 1;
#        	      }
#        	      $parent=$inheritance{$parent};
#        	    }
#        	    $parent=$inheritance{$b};
#        	    while ($parent ne "") {
#        	      if ($parent eq $a) {
#        	        return -1;
#        	      }
#        	      $parent=$inheritance{$parent};
#        	    }
#        	    return 0;
#	    } keys %inheritance;

#	for my $key (@inheritance_sorted) {
	print "Start writing classes\n";
	while (keys %inheritance>0) {
	    my $key;
	    my $value;
  	    while ( ($key, $value) = each %inheritance) {
  	        if (!(exists $inheritance{$value}) || ($value eq "")) {
  	      	  if ($value eq "") {
	   	    print QTCTYPES "      ",$key,"H = class end;\n";
  	          } else {
	   	    print QTCTYPES "      ",$key,"H = class(",$value,"H) end;\n";
	   	  }
	   	  delete $inheritance{$key};
	        }
	    }
	}
	print "Finished writing classes\n";
	print QTCTYPES "\n";

	# write enums
	for my $enum (@typeenums)
	{
		print QTCTYPES $enum;
	}
	print QTCTYPES "\n";

	for my $func (@qtcfunctions)
	{
		print QTCTYPES $func,"\n";
	}
	print QTCTYPES "\nimplementation\nend.\n";

	print KDETYPES "\nimplementation\n\nend.\n";

	close QTCTYPES;
	close KDETYPES;
}




=head2 writeClassDoc

	Write documentation for one compound node.

=cut

sub writeClassDoc
{
	my( $node ) = @_;

	print "Enter: $node->{astNodeName}\n" if $debug;
	if( exists $node->{ExtSource} ) {
		warn "Trying to write doc for ".$node->{AstNodeName}.
			" from ".$node->{ExtSource}."\n";
		return;
	}

	my $typeName = $node->{astNodeName}."*";

	if ( kalyptusDataDict::pastypemap($typeName) eq "" ) {
		$typeprefix = ($typeName =~ /^Q/ ? "qt_" : "kde_");
		kalyptusDataDict::setpastypemap($typeName, $typeprefix.$node->{astNodeName}."*");
		print "'$typeName' => '$typeprefix$typeName',\n";
	} elsif ( kalyptusDataDict::ctypemap($typeName) =~ /^qt_/ ) {
		$typeprefix = "qt_";
	} elsif ( kalyptusDataDict::ctypemap($typeName) =~ /^kde_/ ) {
		$typeprefix = "kde_";
	} else {
		$typeprefix = "";
	}

	my $file = "$outputdir/".join("__", kdocAstUtil::heritage($node))."h.inc";
	my $docnode = $node->{DocNode};
	my @list = ();
	my $version = undef;
	my $author = undef;

#	if( $#{$node->{Kids}} < 0 || $node->{Access} eq "private" || exists $node->{Tmpl} ) {
	if( $#{$node->{Kids}} < 0 || $node->{Access} eq "private") {
		return;
	}

	open( HEADER, ">".lc("$file") ) || die "Couldn't create $file\n";
	$file =~ s/\h.inc/.cpp/;
	open( CLASS, ">".lc("$file") ) || die "Couldn't create $file\n";

	# Header

	my $short = "";
	my $extra = "";

	# ancestors
	my @ancestors = ();
	my $parent = "";

	Iter::Ancestors( $node, $rootnode, undef, undef,
		sub { # print
			my ( $ances, $name, $type, $template ) = @_;
			push @ancestors, $name;
		},
		undef
	);

	if ($#ancestors >= 0) {

  	  # nested classes aren't possible in Object Pascal
  	  # they are moved to level 1
  	  @ancestors[0] =~ s/[^:]*::([^:]*)/$1/;
  	  $inheritance{$node->{astNodeName}}=@ancestors[0];
	} else {
	  $inheritance{$node->{astNodeName}}="";
	}

	if ( kalyptusDataDict::pastypemap($typeName) =~ /^kde_/ ) {
# 		@qtcfunctions[$#qtcfunctions+1]="     {\$i ".$node->{astNodeName}."h.inc}\n";
	} else {
 		@qtcfunctions[$#qtcfunctions+1]="     {\$i ".$node->{astNodeName}."h.inc}\n";
        }

	print HEADER "{***************************************************************************\n";
	print HEADER "                            ", $node->{astNodeName},".pas -  description\n";
	print HEADER $docTop,"}\n\n";

	print CLASS "/***************************************************************************\n";
	print CLASS "                            ", $typeprefix, $node->{astNodeName}, ".cpp -  description\n";
	print CLASS $docTop,"*/\n\n";
	print CLASS "extern \"C\" {\n#include \"", $typeprefix, $node->{astNodeName}, ".h\"\n}\n\n";

	my $sourcename = $node->{Source}->{astNodeName};

	if ( $sourcename =~ m!.*(dom|kabc|kdeprint|kdesu|kio|kjs|kparts|ktexteditor|libkmid)/([^/]*$)! ) {
		$sourcename = $1."/".$2;
	} else {
		$sourcename =~ s!.*/([^/]*$)!$1!;
	}

	print CLASS "#include <",$sourcename , ">\n\n";

	$constructorCount = 0;

	Iter::MembersByType ( $node,
		sub { print HEADER "", $_[0], ""; print CLASS "", $_[0], ""; },
		sub {	my ($node, $kid ) = @_;
                 preParseMember( $node, $kid );
               },
		sub { print HEADER ""; print CLASS ""; }
	);

	if ( ! exists $node->{Pure} && $constructorCount > 0 ) {
		print CLASS "class ", $node->{astNodeName}, "Bridge : public ", kalyptusDataDict::addNamespace($node->{astNodeName}), "\n{\npublic:\n";

		Iter::MembersByType ( $node,
			sub { print HEADER "", $_[0], ""; print CLASS "", $_[0], ""; },
			sub {	my ($node, $kid ) = @_;
                    generateBridgeClass( $node, $kid );
                 },
			sub { print HEADER ""; print CLASS ""; }
			);

		generateBridgeEventHandlers($node);

		print CLASS "};\n\n";
	}

	%functionId = ();
	$eventHandlerCount = 0;

	Iter::MembersByType ( $node,
		sub { print HEADER "", $_[0], ""; print CLASS "", $_[0], ""; },
		sub {	my ($node, $kid ) = @_;
                               listMember( $node, $kid );
                         },
		sub { print HEADER ""; print CLASS ""; }
	);

	if ( $#ancestors > 0 ) {
		# 'type transfer' functions to cast for correct use of multiple inheritance
		foreach my $ancestor (@ancestors) {
			print HEADER "\n{\*\* Casts a '$typeprefix", $node->{astNodeName}, " *' to a '", kalyptusDataDict::pastypemap($ancestor."\*"), "' \}\n";
			print HEADER "function ", $typeprefix, $node->{astNodeName}, "_", $ancestor;
			print HEADER "(", $typeprefix, "instPointer : ",$node->{astNodeName}, "H) : ",kalyptusDataDict::pastypemap($ancestor."\*"),";cdecl;\n";

			print CLASS kalyptusDataDict::ctypemap($ancestor."\*"), " ", $typeprefix, $node->{astNodeName}, "_", $ancestor;
			print CLASS "(", $typeprefix, $node->{astNodeName}, "* instPointer){\n";
			print CLASS "\treturn (", kalyptusDataDict::ctypemap($ancestor."\*"), ") (", $ancestor, " *) (", $node->{astNodeName}, " *) instPointer;\n}\n";
		}
	}

	$file =~ s/\.cpp/.inc/;

	open(BODY, ">".lc("$file") ) || die "Couldn't create $file\n";

	for my $func (@functions)
	{
		print BODY $func,"\n";
	}

	@functions=();

	close BODY;
	close CLASS;
	close HEADER;

}


sub preParseMember
{
	my( $class, $m ) = @_;
	my $name = $m->{astNodeName};

	if( $m->{NodeType} eq "method" ) {
		# A JBridge class will only be generated if there is at least one
		# public or protected constructor
		if ( $name eq $class->{astNodeName} && $m->{Access} ne "private" ) {
			$constructorCount++;
		}
    }
}

sub generateBridgeEventHandlers
{
	my( $node ) = @_;
	my %allmem = ();
	my $key;

	my $m;
	my $name;

	kdocAstUtil::allMembers( \%allmem, $node );

	foreach $key (keys (%allmem)) {
		$m = $allmem{$key};
		$name = $m->{astNodeName} ;
		my $type = $m->{NodeType};
		my $docnode = $m->{DocNode};
		my $pasparams = $m->{Params};
		my $parent = $m->{Parent};
		my $cplusplusparams;

		if( $type eq "method" && $m->{Access} eq "protected"  && $name =~ /.*Event$/
		  && $name !~ /qwsEvent/ && $name !~ /x11Event/ && $name !~ /winEvent/ && $name !~ /macEvent/ && $name !~ /movableDropEvent/ ) {

			$pasparams =~ s/=\s*[-\"\w]*//g;
			$pasparams =~ s/\s+/ /g;
			$pasparams =~ s/\s*([,\*\&])\s*/$1 /g;
			$pasparams =~ s/^\s*void\s*$//;
			my $argId = 0;
			my @cargs = kdocUtil::splitUnnested(",", $pasparams);
			my $cplusplusargs = "";
			foreach my $arg ( @cargs ) {
				my $argType;
				my $cargType;

				$arg =~ s/\s*([^\s].*[^\s])\s*/$1/;
				if ( $arg =~ /(.*)\s+(\w+)$/ ) {
					$argType = $1;
					$arg = $2;
				} else {
					$argType = $arg;
					$argId++;
					$arg = "arg".$argId;
				}
				$cplusplusparams .= $argType." ".$arg.", ";
				$cplusplusargs .= $arg.", ";
			}
			$pasparams =~ s/; $//;
			$cplusplusparams =~ s/, $//;
			$cplusplusargs =~ s/, $//;

			$eventHandlerCount++;
			my $eventType = $cplusplusparams;
			$eventType =~ s/(.*)\*.*$/$1/;
			print CLASS "\tvoid $name(", $cplusplusparams, ") {\n",
			"\t\tif (Qt_EventDelegate == 0L || !(*Qt_EventDelegate)(this, \"", $name, "\", $cplusplusargs, \"$eventType\")) {\n",
			"\t\t\t", $parent->{astNodeName}, "::", $name, "($cplusplusargs);\n",
			"\t\t}\n",
			"\t\treturn;\n\t}\n";
		}
	}

}


sub changehex($)
{
  my $value = @_[0];
  $value =~ s/0x/\$/;
  return $value;
}

sub generateBridgeClass
{
	my( $class, $m ) = @_;
	my $name;
	my $function;

	$name = $m->{astNodeName} ;
	my $type = $m->{NodeType};
	my $docnode = $m->{DocNode};

	if( $type eq "method" && $m->{Access} ne "private" && $m->{Access} ne "private_slots" && $m->{Access} ne "signals" ) {
		if ( $m->{ReturnType} =~ /[<>]/ || $m->{Params} =~ /[<>]/ || $m->{Params} =~ /Impl/) {
#			print "template based method not converted: ", $m->{ReturnType}, " ", $m->{Params}, "\n";
			return;
		}

		my $returnType = $m->{ReturnType};
		my $pasparams = $m->{Params};
		my $cplusplusparams;
		# TODO port to $m->{ParamList}
		$pasparams =~ s/=\s*(("[^\"]*")|(\'.\')|(([-\w:.]*)\s*(\|\s*[-\w]*)*(\(\w*\))?))//g;
		$pasparams =~ s/\s+/ /g;
		$pasparams =~ s/\s*([,\*\&])\s*/$1 /g;
		$pasparams =~ s/^\s*void\s*$//;
		$pasparams =~ s/^\s*$//;
		my $argId = 0;
		my @cargs = kdocUtil::splitUnnested(",", $pasparams);
		$pasparams = "";
		foreach my $arg ( @cargs ) {
			my $argType;
			my $cargType;
			$arg =~ s/\s*([^\s].*[^\s])\s*/$1/;
			if ( $arg =~ /(.*)\s+(\w+)$/ ) {
				$argType = $1;
				$arg = $2;
			} else {
				$argType = $arg;
				$argId++;
				$arg = "arg".$argId;
			}
			$cplusplusparams .= $argType." ".$arg.", ";
			$pasparams .= $arg.", ";
		}
		$pasparams =~ s/, $//;
		$cplusplusparams =~ s/, $//;

		my $flags = $m->{Flags};

		if ( !defined $flags ) {
			warn "Method ".$m->{astNodeName}.  " has no flags\n";
		}

		my $extra = "";
		$extra .= "static " if $flags =~ "s";
		if ( $name =~ /operator/ ) {
			return;
		}


		if ( $name eq $class->{astNodeName} ) {
			if ( $returnType =~ "~" ) {
				print CLASS "\t~", $name, "Bridge() {}\n";
			} else {
				print CLASS $extra,
					"\t", $name, "Bridge(", $cplusplusparams, ") : $name($pasparams) {}\n";
			}
		} elsif( $type eq "method" && $m->{Access} eq "protected"  && $name =~ /.*Event$/ ) {
			;
		} elsif( $m->{Access} =~ /^protected/ ){
			if ( $returnType =~ "void" ) {
				print CLASS "\tvoid protected_$name(", $cplusplusparams, ") {\n",
				"\t\t", $class->{astNodeName}, "::$name($pasparams);\n",
				"\t\treturn;\n\t}\n";
			} else {
				print CLASS "\t$returnType protected_$name(", $cplusplusparams, ") {\n",
				"\t\treturn ($returnType) ", $class->{astNodeName}, "::$name($pasparams);\n\t}\n";
			}
		}
	}

}

sub listMember
{
	my( $class, $m ) = @_;
	my $name;
	my $function;

	$name = $m->{astNodeName} ;
	my $type = $m->{NodeType};
	my $docnode = $m->{DocNode};

	if ( $m->{ReturnType} =~ /~/ ) {
		$name = "~".$name;
	}

	if ( $functionId{$name} eq "" ) {
		$functionId{$name} = 0;
		$function = $name;
	} else {
		$functionId{$name}++;
		$function = $name.$functionId{$name};
	}

	$function =~ s/~//;

	if ($m->{ReturnType} eq "typedef") {
	} elsif( $type eq "method" && $m->{Access} ne "private" && $m->{Access} ne "private_slots" && $m->{Access} ne "signals" ) {
		if ( $m->{ReturnType} =~ /[<>]/ || $m->{Params} =~ /[<>]/  || $m->{Params} =~ /\.\.\./ || $m->{Params} =~ /Impl/
				|| $m->{ReturnType} =~ /QAuBucket/ || $m->{Params} =~ /QAuBucket/
				|| $m->{ReturnType} =~ /QMember/ || $m->{Params} =~ /QMember/   ) {
			return;
		}

		my $returnType = $m->{ReturnType};
		$returnType =~ s/const\s*//;
		$returnType =~ s/\s*([,\*\&])\s*/$1/;
		$returnType =~ s/^\s*//;
		$returnType =~ s/\s*$//;
		# map result type
		my $cplusplusreturntype=$returnType;
		if (kalyptusDataDict::pastypemap($returnType) ne "") {
		  $cplusplusreturntype=kalyptusDataDict::ctypemap($returnType)
		}
		if ( $returnType ne "" && kalyptusDataDict::pastypemap($returnType) eq "" ) {
			print "'$returnType' => '$typeprefix$returnType',\n";
		} else {
			$returnType = kalyptusDataDict::pastypemap($returnType);
		}
		$returnType =~ s/var /P/;
		if ($returnType eq "var" || $returnType eq "const") {
		  $returnType="pointer";
		}
		# TODO port to $m->{ParamList}
		my $pasparams = $m->{Params};
		my $cplusplusparams;
		my $argMod = "";
		my $cplusplusargs = "";
		$pasparams =~ s/\s+/ /g;
		$pasparams =~ s/\s*([,\*\&])\s*/$1 /g;
		$pasparams =~ s/^\s*void\s*$//;
		my $argId = 0;
		my @cargs = kdocUtil::splitUnnested(",", $pasparams);
		$pasparams = "";
		foreach my $arg ( @cargs ) {
			my $argType;
			my $cargType;
			if ( $arg =~ /^\s*$/ ) {
				next;
			}

			# A '<arg> = <value>' default parameter
			$arg =~ s/\s*([^\s].*[^\s])\s*/$1/;
			$arg =~ s/(\w+)\[\]/\* $1/;
			$arg =~ s/=\s*(("[^\"]*")|(\'.\')|(([-\w:.]*)\s*(\|\s*[-\w]*)*(\(\w*\))?))//;

			if ( $arg =~ /^(.*)\s+(\w+)\s*$/ ) {
				$argType = $1;
				# prepend with _ to avoid name conflicts
				$arg = "_".$2;
			} else {
				$argType = $arg;
				$argId++;
				$arg = "arg".$argId;
			}

			$arg =~ s/^id$/identifier/;
			$argType =~ s/\s*([^\s].*[^\s])\s*/$1/;
			$argType =~ s/\s*const//g;
			$argType =~ s/^\s*//;
			$argType =~ s/([\*\&])\s*([\*\&])/$1$2/;
			# print $argType."\n";
			$cargType = kalyptusDataDict::pastypemap($argType);
			# print $cargType."\n";

			if ( $argType =~ /^[A-Z][^:]*$/ &&  kalyptusDataDict::ctypemap($argType) eq "int" &&
			  kalyptusDataDict::ctypemap($class->{astNodeName}."::".$argType) ne "" ) {
				$cplusplusargs  .= "(".$class->{astNodeName}."::".$argType.")";
			} elsif ( $argType =~ /^\s*WFlags\s*$/ ) {
				$cplusplusargs  .= "(QWidget::WFlags)";
			} elsif ( $argType =~ /^\s*ArrowType\s*$/ ) {
				$cplusplusargs  .= "(Qt::ArrowType)";
			} elsif ( $argType =~ /^\s*Orientation\s*$/ ) {
				$cplusplusargs  .= "(Qt::Orientation)";
			} elsif ( $argType =~ /^\s*BrushStyle\s*$/ ) {
				$cplusplusargs  .= "(Qt::BrushStyle)";
			} elsif ( $argType =~ /^\s*BGMode\s*$/ ) {
				$cplusplusargs  .= "(Qt::BGMode)";
			} elsif ( $argType =~ /^\s*PenCapStyle\s*$/ ) {
				$cplusplusargs .= "(Qt::PenCapStyle)";
			} elsif ( $argType =~ /^\s*PenStyle\s*$/ ) {
				$cplusplusargs  .= "(Qt::PenStyle)";
			} elsif ( $argType =~ /^\s*PenJoinStyle\s*$/ ) {
				$cplusplusargs  .= "(Qt::PenJoinStyle)";
			} elsif ( $argType =~ /^\s*RasterOp\s*$/ ) {
				$cplusplusargs  .= "(Qt::RasterOp)";
			} elsif ( $argType =~ /^\s*TextFormat\s*$/ ) {
				$cplusplusargs  .= "(Qt::TextFormat)";
			} elsif ( $argType =~ /^\s*QDragMode\s*$/ ) {
				$cplusplusargs .= "(QDragObject::DragMode)";
			} elsif ( $argType =~ /^\s*GUIStyle\s*$/ ) {
				$cplusplusargs .= "(Qt::GUIStyle)";
			} elsif ( $argType =~ /^\s*Type\s*$/ ) {
				$cplusplusargs .= "(QEvent::Type)";
			} else {
				$cplusplusargs .= "(".kalyptusDataDict::addNamespace($argType).")";
			}

			if ( $cargType eq "" ) {
				print "'$argType' => '$typeprefix$argType',\n";
				$argType =~ s/\&.*$//;
				$pasparams .= $argMod." ".$arg." : ".$argType."; ";
				$cplusplusparams .= $argType." ".$arg.", ";
			} else {
				$cplusplusparams .= kalyptusDataDict::ctypemap($argType)." ".$arg.", ";
			 	my $pasargType=kalyptusDataDict::pastypemap($argType);
				if ($pasargType =~ s/^var//) {
				  $argMod="var";
				} else {
				  $argMod="";
				}
				# formal parameter?
				if ($pasargType eq "" && ($argMod eq "var" || $argMod eq "const")) {
			          $pasparams .= $argMod." ".$arg."; ";
			        } else {
				  $pasparams .= $argMod." ".$arg." : ".$pasargType."; ";
				}
			}

			if ( ( $cargType =~ /^qt_.*\*/ || $cargType =~ /^kde_.*\*/ ) && $argType =~ /^[^\*]*$/ ) {
				$argType =~ s/^(.*)\&.*$/$1/;
				$cplusplusargs .= "* (".kalyptusDataDict::addNamespace($argType)."*)".$arg.", ";
			} else {
				$cplusplusargs .= $arg.", ";
			}


		}
		$pasparams =~ s/; $//;
		$cplusplusparams =~ s/, $//;
		$cplusplusargs =~ s/, $//;

		my $flags = $m->{Flags};

		if ( !defined $flags ) {
			warn "Method ".$m->{astNodeName}.  " has no flags\n";
		}


		my $extra = "";
		$extra .= "static " if $flags =~ "s";

		if ( $name =~ /operator/  ) {
			return;
		}

		if ( $m->{Access} =~ /protected/ && $name ne $class->{astNodeName}  ) {
			if ( $class->{Pure} ) {
				return;
			}

			$name = "protected_".$name;
		}

		if ( $name eq $class->{astNodeName} && $class->{Pure} ) {
			return;
		}

		if ( defined $docnode ) {
			if ( defined $docnode->{Text} ) {
				print HEADER "\n{* ";
				my $node;
				my $line;
				foreach $node ( @{$docnode->{Text}} ) {
					next if $node->{NodeType} ne "DocText";
					$line = $node->{astNodeName};
					print HEADER $line, "\n";
				}
				print HEADER "}\n";
			}
		}
		# constructor
		if ( $name eq $class->{astNodeName} ) {
			print HEADER $extra,
				"function ", $typeprefix, "new_", $function,
				"(", $pasparams, ") : ".$name."H;cdecl;\n";
			@functions[$#functions+1]="function ". $typeprefix. "new_". $function.
				"(".$pasparams.") : ".$name."H;cdecl;external name ".
						"'".$typeprefix. "new_". $function. "';";
			print CLASS $extra,
				$typeprefix, $name, " * ", $typeprefix, "new_", $function,
				"(", $cplusplusparams, "){\n",
				"\treturn (", $typeprefix, $name, " *) new ", $name, "Bridge(", $cplusplusargs, ");\n}\n";
		# destructor
		} elsif ( $returnType =~ /~/  ) {
			print HEADER $extra,
				"procedure ", $typeprefix, "del_", $function,
				"(p : ", $class->{astNodeName}, "H);cdecl;\n";
			@functions[$#functions+1]="procedure ".$typeprefix. "del_". $function.
				"(p : ".$class->{astNodeName}."H);cdecl;external name ".
						"'". $typeprefix. "del_". $function."';";
			if (exists $class->{Pure} || $constructorCount == 0) {
				print CLASS $extra,
					"void ", $typeprefix, "del_", $function,
					"( ", $typeprefix, $class->{astNodeName}, "* p ){\n\tdelete (", kalyptusDataDict::addNamespace($class->{astNodeName}), "*) p;\n}\n";
			} else {
				print CLASS $extra,
					"void ", $typeprefix, "del_", $function,
					"( ", $typeprefix, $class->{astNodeName}, "* p ){\n\tdelete (", $class->{astNodeName}, "Bridge*) p;\n}\n";
			}
		} else {
			if ( $name =~ /.*Event$/ ) {
				return;
			}

			# Class or instance method
			my $selfstring;
			if ( $extra =~ /static/ ) {
				if ( exists $class->{Pure} || $constructorCount == 0 ) {
					$selfstring = kalyptusDataDict::addNamespace($class->{astNodeName})."::";
				} else {
					$selfstring = $class->{astNodeName}."Bridge::";
				}
				if ($returnType eq "void") {
					print HEADER "procedure ",
						$class->{astNodeName}, "_", $function,
						"(", $pasparams, ");cdecl;\n";
					@functions[$#functions+1]="procedure ".
						$class->{astNodeName}."_".$function.
						"(".$pasparams.");cdecl;external name ".
						"'".$typeprefix . $class->{astNodeName} . "_".$function."';";

				} else {
					print HEADER "function ",
						$class->{astNodeName}, "_", $function,
						"(", $pasparams, ") : ".$returnType.";cdecl;\n";
					@functions[$#functions+1]="function ".
						$class->{astNodeName}."_".$function.
						"(".$pasparams.") : ".$returnType.";cdecl;external name ".
						"'".$typeprefix . $class->{astNodeName} . "_".$function."';";
				}
				print CLASS $cplusplusreturntype,
					" ", $typeprefix, $class->{astNodeName}, "_", $function,
					"( ", $cplusplusparams, "){\n";
			} else {
				if ( exists $class->{Pure} || $constructorCount == 0 ) {
					$selfstring = "((".kalyptusDataDict::addNamespace($class->{astNodeName})."*)instPointer)->";
				} else {
					$selfstring = "((".$class->{astNodeName}."Bridge*)instPointer)->";
				}
				if ($returnType eq "void") {
					print HEADER "procedure ",
						$class->{astNodeName}, "_", $function,
						"(", "instPointer : ", $class->{astNodeName}, "H", ($pasparams eq "" ? "" : ";"), $pasparams, ");cdecl;\n";
					@functions[$#functions+1]="procedure ".
						$class->{astNodeName}."_".$function.
						"("."instPointer : ".$class->{astNodeName}."H".($pasparams eq "" ? "" : ";").$pasparams.
						");cdecl;external name ".
						"'".$typeprefix . $class->{astNodeName} . "_".$function."';";
				} else {
					print HEADER "function ",
						$class->{astNodeName}, "_", $function,
						"(", "instPointer : ", $class->{astNodeName}, "H", ($pasparams eq "" ? "" : ";"), $pasparams, ") : ",
						$returnType,";cdecl;\n";
					@functions[$#functions+1]="function ".
						$class->{astNodeName}."_".$function.
						"("."instPointer : ".$class->{astNodeName}."H".($pasparams eq "" ? "" : ";").$pasparams.
						") : ".$returnType.";cdecl;external name ".
						"'".$typeprefix . $class->{astNodeName} . "_".$function."';";
				}
				print CLASS $cplusplusreturntype,
					" ", $typeprefix, $class->{astNodeName}, "_", $function,
					"( ", $typeprefix, $class->{astNodeName}, "* instPointer", ($cplusplusparams eq "" ? "" : ","), $cplusplusparams, "){\n";
    		}
			if ( $cplusplusreturntype =~ /^\s*void\s*$/ ) {
				print CLASS "\t", $selfstring, $name, "(", $cplusplusargs, ");\n\treturn;\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QBrush\s*$/ ) {
				print CLASS "\tQBrush _b= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QBrush(_b.color(),_b.style());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QColorGroup\s*$/ ) {
				print CLASS "\tQColorGroup _c= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QColorGroup(_c.foreground(),_c.background(),_c.light(),_c.dark(),_c.mid(),_c.text(),_c.base());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QDateTime\s*$/ ) {
				print CLASS "\tQDateTime _dt= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QDateTime (_dt.date(),_dt.time());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QDate\s*$/ ) {
				print CLASS "\tQDate _d= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QDate(_d.year(),_d.month(),_d.day());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QPen\s*$/ ) {
				print CLASS "\tQPen _b= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QPen(_b.color(),_b.width(),_b.style());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QPoint\s*\&?\s*$/ ) {
				print CLASS "\tQPoint _p= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QPoint(_p.x(),_p.y());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QRect\s*$/ ) {
				print CLASS "\tQRect _r= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QRect(_r.left(),_r.top(),_r.width(),_r.height());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QSizePolicy\s*$/ ) {
				print CLASS "\tQSizePolicy _s= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QSizePolicy(_s.horData(),_s.verData(),_s.hasHeightForWidth());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QSize\s*$/ ) {
				print CLASS "\tQSize _s= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QSize(_s.width(),_s.height());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QStyle\s*$/ ) {
				print CLASS "\tQStyle * _s= \&", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ") _s;\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QTime\s*$/ ) {
				print CLASS "\tQTime _t= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QTime(_t.hour(),_t.minute(),_t.second(),_t.msec());\n}\n" ;
			} elsif ( $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?QWMatrix\s*$/ ) {
				print CLASS "\tQWMatrix _m= ", $selfstring, $name, "(", $cplusplusargs, ");\n" ;
				print CLASS "\treturn (", $cplusplusreturntype, ")new QWMatrix(_m.m11(),_m.m12(),_m.m21(),_m.m22(),_m.dx(),_m.dy());\n}\n" ;
			} elsif (	($cplusplusreturntype =~ /qt_/ || $returnType =~ /kde_/)
						&& $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?(\w*)\s*$/ )
			{
				my $valueType = kalyptusDataDict::addNamespace($3);
				print CLASS "\treturn (", $cplusplusreturntype, ")new $valueType(", $selfstring, $name, "(", $cplusplusargs, "));\n}\n"; ;
			} elsif (	($cplusplusreturntype =~ /qt_/ || $cplusplusreturntype =~ /kde_/)
					&& $m->{ReturnType} =~ /^\s*(inline)?\s*(const)?\s*?(\w*)\s*\&?\s*$/ )
			{
				my $constOpt = $2;
				my $valueType = kalyptusDataDict::addNamespace($3);
				print CLASS "\treturn (", $cplusplusreturntype, ") ($constOpt $valueType *)\&", $selfstring, $name, "(", $cplusplusargs, ");\n}\n"; ;
			} else {
				print CLASS "\treturn (", $cplusplusreturntype, ") ", $selfstring, $name, "(", $cplusplusargs, ");\n}\n" ;
			}
   		}
	} elsif( $type eq "enum" ) {
		# Convert each enum value to '#define <uppercased class name>_<enum name> <enum value>'
		my $enum = $m->{astNodeName};
		my $enumname = $enum;
	        my %enumMap = ();

		# Add a C++ to C type mapping for this enum - ie an int in C
		$enum =~ s/\s//g;

		kalyptusDataDict::setpastypemap($enum, $class->{astNodeName}.$enumname);
		kalyptusDataDict::setctypemap($enum, 'int');
		$enum = $class->{astNodeName}."::".$enum;
		kalyptusDataDict::setpastypemap($enum, $class->{astNodeName}.$enumname);
		# add C mapping as well
		kalyptusDataDict::setctypemap($enum, 'int');

		@typeenums[$#typeenums+1]= "      ".$class->{astNodeName}.$enumname." = (\n";
		my @enums = split(",", $m->{Params});
		my $first = 1;
		foreach my $enum ( @enums ) {
			if ($first!=1) {
			  @typeenums[$#typeenums+1]=",\n";
			}
		 	$first=0;
			$enum =~ s/\s//g;
			if ( $enum =~ /(.*)=(.*)\s*(\||\&|>>|<<|\+)\s*(.*)/ ) {
				# !!!! needs to be evaluted here
				# or'd, and'd or shifted pair of values
				@typeenums[$#typeenums+1]="        ".$class->{astNodeName}.$enumname."_".$1; # !!!!. "\t:= ".
#!!!!					($enumMap{$2} eq "" ? $2 : "dword(".$enumMap{$2}.")").$pasopmap{$3}. ($enumMap{$4} eq "" ? $4 : "dword(".$enumMap{$4}.")");
				$enumMap{$1} = $class->{astNodeName}.$enumname."_".$1;
			} elsif ( $enum =~ /(.*)=(.*)/ ) {
				@typeenums[$#typeenums+1]="        ".kalyptusDataDict::pasenummap($class->{astNodeName}.
				  $enumname."_".$1)."\t:= ".($enumMap{$2} eq "" ? changehex($2) : $enumMap{$2});
				$enumMap{$1} = $class->{astNodeName}.$enumname."_".$1;
			} else {
				@typeenums[$#typeenums+1]="        ".$class->{astNodeName}.$enumname."_".$enum;
				$enumMap{$enum} = $class->{astNodeName}.$enumname."_".$enum;
			}
		}
		@typeenums[$#typeenums+1]="\n      );\n\n";
	}

}


1;

#
