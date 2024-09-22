namespace eval ncicadd {
	
	# unsued currently ...:
	proc XnormStructure {ehandle} {
		ens::identifier::purgeProps $ehandle all 0
		set normOrder [ens::norm::getglobalparam normOrder]
		set normList [list deleteSearchInfo radical metalLigandBonds hsaturation functionalGroups stereo]
		set defaultParameterArray [ens::norm::createDefaultParameterArray]
		set parameterArgArray [ens::norm::getDefaultArgArray]
		set parameterArray [ens::norm::createParameterArray $defaultParameterArray $normList 1]
		proparray::rdelete ncicadd_parent
		proparray::rassign ncicadd_parent [ens::norm::structure $ehandle $normOrder $parameterArray $defaultParameterArray $parameterArgArray {} {} 0]
		# ens::norm::structure creates a parent structure implicitely, not needed:
		#ens delete [proparray::get parent parentstructure]
		return [proparray::rget parent]
	}
	
	proc testStructure {ehandle} {
		set testOrder [ens::test::getglobalparam testOrder]
		set defaultParameterArray [ens::test::createDefaultParameterArray]
		set parameterArray [ens::test::createParameterArray $defaultParameterArray $testOrder 1]
		return [ens::test::structure $ehandle $testOrder $parameterArray {} {} 0]
	}

	proc calcAllIdentifiers {ehandle} {
		array unset identifier	
		array unset structure
		array unset normArgs
		array unset testStatus
		proparray::rdelete allFICxx
		proparray::rdelete alluuuxx

		#set identifier(E_NCICADD_INPUT_HASHISY,hashcode) [ens get $ehandle E_HASHISY]
	
		ens new $ehandle E_FICXX_ID
		ens new $ehandle E_UUUXX_ID

		set structure(FICxx) [ens get $ehandle E_FICXX_STRUCTURE]
		set structure(uuuxx) [ens get $ehandle E_UUUXX_STRUCTURE]

		proparray::rassign allFICxx [ens metadata $ehandle E_FICXX_ID]
		proparray::rassign alluuuxx [ens metadata $ehandle E_UUUXX_ID]

		set FICxxReliable [expr ![regexp {unreliable} [proparray::get allFICxx flags]]]
		set uuuxxReliable [expr ![regexp {unreliable} [proparray::get alluuuxx flags]]] 

		set normArgs(FICxx,tautomer) [proparray::get allFICxx parameters norm args tautomer]
		set normArgs(FICxx,stereo) [proparray::get allFICxx parameters norm args stereo]
		set normArgs(uuuxx,tautomer) [proparray::get alluuuxx parameters norm args tautomer]
		set normArgs(uuuxx,stereo) [proparray::get alluuuxx parameters norm args stereo]
	
		# testStatus is indepentend of being calculated FICxx or uuuxx
		set testStatus(inorganic) [proparray::get allFICxx info test status inorganic]
		set testStatus(metalComplex) [proparray::get allFICxx info test status metalComplex]
		set testStatus(singleMetalAtoms) [proparray::get allFICxx info test status singleMetalAtoms]
		set testStatus(singleHydrogenAtoms) [proparray::get allFICxx info test status singleHydrogenAtoms]
		set testStatus(specialAtomTypes) [proparray::get allFICxx info test status specialAtomTypes]

		set structure(FICxx,tautomer) [ens dup $structure(FICxx)]
		set structure(uuuxx,tautomer) [ens dup $structure(uuuxx)]
	
		set FICxxTautomerReliable 1
		set uuuxxTautomerReliable 1

		if {!$testStatus(inorganic) \
			&& !$testStatus(metalComplex) \
			&& !$testStatus(singleMetalAtoms) \
			&& !$testStatus(singleHydrogenAtoms) \
			&& !$testStatus(specialAtomTypes) \
		} {
			set ::cactvs(setsize_exceeded) 0
			set FICxxTautomerReliable [expr ![catch {
				eval ens::norm::tautomer $structure(FICxx,tautomer) $normArgs(FICxx,tautomer)
				eval ens::norm::stereo $structure(FICxx,tautomer) $normArgs(FICxx,stereo)
			}]]
			if {$::cactvs(setsize_exceeded)} {set FICxxTautomerReliable 0}
			set ::cactvs(setsize_exceeded) 0
			set uuuxxTautomerReliable [expr ![catch {
				eval ens::norm::tautomer $structure(uuuxx,tautomer) $normArgs(uuuxx,tautomer)
				eval ens::norm::stereo $structure(uuuxx,tautomer) $normArgs(uuuxx,stereo)
			}]]
			if {$::cactvs(setsize_exceeded)} {set uuuxxTautomerReliable 0}
		}

		foreach struc [list $structure(FICxx) $structure(FICxx,tautomer) $structure(uuuxx) $structure(uuuxx,tautomer)] {
			ens taint $struc [list A_HASH A_STEREO_HASH M_HASHY M_HASHSY]
			ens purge $struc [list A_HASH A_STEREO_HASH M_HASHY M_HASHSY]
			ens taint $struc [list E_HASHISY E_HASHIY E_HASHSY E_HASHY]
			ens purge $struc [list E_HASHISY E_HASHIY E_HASHSY E_HASHY]
		}

		set identifier(FICTS,hashcode) [ens new $structure(FICxx) E_HASHISY]
		set identifier(FICTu,hashcode) [ens new $structure(FICxx) E_HASHIY]
		set identifier(FICuS,hashcode) [ens new $structure(FICxx,tautomer) E_HASHISY]
		set identifier(FICuu,hashcode) [ens new $structure(FICxx,tautomer) E_HASHIY]
		set identifier(uuuTS,hashcode) [ens new $structure(uuuxx) E_HASHSY]
		set identifier(uuuTu,hashcode) [ens new $structure(uuuxx) E_HASHY]
		set identifier(uuuuS,hashcode) [ens new $structure(uuuxx,tautomer) E_HASHSY]
		set identifier(uuuuu,hashcode) [ens new $structure(uuuxx,tautomer) E_HASHY]

		set identifier(FICTS,reliable) $FICxxReliable
		set identifier(FICTu,reliable) $FICxxReliable
		set identifier(FICuS,reliable) [expr $FICxxReliable && $FICxxTautomerReliable]
		set identifier(FICuu,reliable) [expr $FICxxReliable && $FICxxTautomerReliable]
		set identifier(uuuTS,reliable) $uuuxxReliable
		set identifier(uuuTu,reliable) $uuuxxReliable
		set identifier(uuuuS,reliable) [expr $uuuxxReliable && $uuuxxTautomerReliable]
		set identifier(uuuuu,reliable) [expr $uuuxxReliable && $uuuxxTautomerReliable]

		# that is stuff to stay compatible with old stuff
		
		ens set $ehandle E_FLG_FICTU_UNRELIABLE [expr !$identifier(FICTS,reliable)]
		ens set $ehandle E_FLG_FICTS_UNRELIABLE [expr !$identifier(FICTu,reliable)]
		ens set $ehandle E_FLG_FICUU_UNRELIABLE [expr !$identifier(FICuS,reliable)]
		ens set $ehandle E_FLG_FICUS_UNRELIABLE [expr !$identifier(FICuu,reliable)]
		ens set $ehandle E_FLG_UUUTU_UNRELIABLE [expr !$identifier(uuuTS,reliable)]
		ens set $ehandle E_FLG_UUUTS_UNRELIABLE [expr !$identifier(uuuTu,reliable)]
		ens set $ehandle E_FLG_UUUUS_UNRELIABLE [expr !$identifier(uuuuS,reliable)]
		ens set $ehandle E_FLG_UUUUU_UNRELIABLE [expr !$identifier(uuuuu,reliable)]


		foreach name [ens::identifier::getNames] {
			set propName [ens::identifier::getPropName $name]
			set propForceMagic [prop getparam $propName forcemagic]
			if {$identifier($name,reliable)} {
				set identifier($name,string) [ens::identifier::getString $name $identifier($name,hashcode)]
				ens set $ehandle $propName $identifier($name,string)
			} else {
				if {$propForceMagic} {
					set identifier($name,string) [ens::identifier::getString $name [prop get $propName magic]]
				} else {
					set identifier($name,string) [ens::identifier::getString $name $identifier($name,hashcode)]
				}
				#append sstatus "calculation of $propName, " 
				ens set $ehandle $propName $identifier($name,string)
				ens metadata $ehandle $propName flags unreliable
			}
		}

		ens set $ehandle E_FICUS_STRUCTURE $structure(FICxx,tautomer)
		
		ens::norm::deleteStereoInfo $structure(uuuxx,tautomer)
		ens set $ehandle E_UUUUU_STRUCTURE $structure(uuuxx,tautomer)

		ens delete $structure(FICxx,tautomer)
		ens delete $structure(uuuxx,tautomer)

		return $ehandle
	}

	if 0 {catch {
	prop create E_FLG_FICTU_UNRELIABLE default 0
	prop create E_FLG_FICTS_UNRELIABLE default 0
	prop create E_FLG_FICUU_UNRELIABLE default 0
	prop create E_FLG_FICUS_UNRELIABLE default 0
	prop create E_FLG_UUUTU_UNRELIABLE default 0
	prop create E_FLG_UUUTS_UNRELIABLE default 0
	prop create E_FLG_UUUUS_UNRELIABLE default 0
	prop create E_FLG_UUUUU_UNRELIABLE default 0
	}}
}

namespace eval proparray {
		
	variable proparray
	variable listidentifier "list:"
			
	proc names {args} {
		variable proparray
		set onlychildnames 0
		while {[string first "-" $args] == 0} {
			set arg0 [lindex $args 0]
			switch -- $arg0 {
				-onlychildnames {set onlychildnames 1}
				default {}
			}
			set args [lrange $args 1 end]
		}
		set namePattern {}
		foreach arg $args {
			set namePattern [concat $namePattern $arg]
		}
		set names [array names proparray $namePattern\*]
		if {$onlychildnames} {
			regsub -all "$namePattern " $names {} names
		}
		return $names
	}
	
	proc sublist {list} {
		variable listidentifier
		if {$list == ""} {return \{\}}
		set element0 [lindex $list 0]
		if {$element0 == $listidentifier} {
			return $list
		}
		return [list [concat $listidentifier $list]]
	}
			
	proc issublist {list} {
		variable listidentifier
		variable erroridentifier
		set element0 [lindex $list 0]
		if {$element0 == $listidentifier} {
			return 1
		}
		return 0
	}
	
	proc nosublists {string} {
		variable listidentifier
		return [regsub -all "$listidentifier " $string {}]
	}
	
	proc assign {args} {
		variable proparray	
 		set ifexists 0
		set forceerrorifnotexists 0
		while {[string first "-" $args] == 0} {
			set arg0 [lindex $args 0]
			switch -- $arg0 {
				-ifexists {set ifexists 1}
				-forceerrorifnotexists {set forceerrorifnotexists 1}
				default {}
			}
			set args [lrange $args 1 end]
		}
		set fieldName {}
		foreach arg [lrange $args 0 end-1] {
			set fieldName [concat $fieldName $arg]
			
		}
		delete [lrange $fieldName 0 end-1]
		set value [lindex $args end]
		set l [llength $value]
		if {$forceerrorifnotexists && ![info exists proparray($fieldName)]} {
			error "proparray::assign: existence of field '$fieldName' is enforced but the field does not exist"
		}
		if {$ifexists && ![info exists proparray($fieldName)]} {
			return {}
		}
		if {$l > 1} {
			set proparray($fieldName) [sublist $value]
		} else {
			set proparray($fieldName) $value
		}
		return $proparray($fieldName)
	}
			
	proc rassign {args} {
		variable proparray
 		set fieldName {}
		foreach arg [lrange $args 0 end-1] {
			set fieldName [concat $fieldName $arg]
		}
		set lend [lindex $args end]
		foreach {element value} $lend {
			set newFieldName [concat $fieldName $element]
			set l [llength $value]
			if {$l == 0} {
				assign $newFieldName \{\}
			}
			if {$l == 1 || [issublist $value]} {
				assign $newFieldName $value		
			} else {
				rassign $newFieldName $value
			}
		}
		return $fieldName
	}
	
	proc delete {args} {
		variable proparray	
 		set fieldName {}
		foreach arg $args {
			set fieldName [concat $fieldName $arg]
			if {![catch {unset proparray($fieldName)}]} {
				return 1
			}
		}
		return 0
	}
	
	proc rdelete {args} {
		variable proparray
		set fieldName {}
		foreach arg $args {
			set fieldName [concat $fieldName $arg]
		}
		set fieldNamePattern [concat $fieldName \*]
		set fieldList [array names proparray $fieldNamePattern]
 		set status 0
		foreach field $fieldList {
			set status [expr $status || [delete $field]]
		}
		return $status
	}
	
	proc get {args} {
		variable proparray
 		set forceemptystring 0
		while {[string first "-" $args] == 0} {
			set arg0 [lindex $args 0]
			switch -- $arg0 {
				-forceemptystring {
					set forceemptystring 1
				}
				default {
				}
			}
			set args [lrange $args 1 end]
		}
		set fieldName {}
 		foreach arg $args {
			set fieldName [concat $fieldName $arg]
		}
		if {[info exists proparray($fieldName)]} {
			if {[llength $proparray($fieldName)] > 1 && [issublist $proparray($fieldName)]} {
 				return [lrange $proparray($fieldName) 1 end]
			} else {
 				if {$forceemptystring && $proparray($fieldName) == "{}"} {
					return {}
				} else {
					return $proparray($fieldName)
				}
			}
		} else {
 			error "proparray::get: unknown field '$fieldName'"
		}
	}
		
	proc rget {args} { 
		variable proparray
 		if {$args == ""} {
			error "proparray::rget: 'no arguments'"
		}
		set nosublists 0
		while {[string first "-" $args] == 0} {
			set arg0 [lindex $args 0]
			switch -- $arg0 {
				-nosublists {set nosublists 1}
				default {}
			}
			set args [lrange $args 1 end]
		}
		set fieldName {}
		foreach arg $args {
			set fieldName [concat $fieldName $arg]
		}
		set fieldNamePattern [concat $fieldName \*]
		set fieldList [array names proparray $fieldNamePattern]
		foreach field $fieldList {
			set value [get $field]
			if {[llength $value] > 1} {set value [sublist $value]}
			set parentFields [lrange $field 0 end-1]
			set subField [lindex $field end]
			if {![info exists returnArray($parentFields)]} {
				set returnArray($parentFields) [concat $subField $value]
			} else {
				set returnArray($parentFields) [concat $returnArray($parentFields) $subField $value]
			}
		}		
		set fieldList [array names returnArray]
		set i 0
		set break 0
 		while 1 {
			set fieldList [lsort -decreasing [array names returnArray]]
			set level [llength [lindex $fieldList 0]]
			if {$break} {break}
			set break 1
 			foreach field $fieldList {
				set l [llength $field]
				if {$l > 1} {
					set break [expr $break && 0]
  				} else {
					set break [expr $break && 1]
 				}
			}		
 			foreach field $fieldList {
				set fieldLevel [llength $field]
				if {$fieldLevel < $level} {continue}
				set value $returnArray($field)
				set subField [lindex $field end]
				set parentFields [lrange $field 0 end-1]
 				if {$parentFields == ""} {continue}
				if {![info exists returnArray($parentFields)]} {
					set returnArray($parentFields) [concat $subField [list $value]]
					set fieldArray($field) $returnArray($field)
					unset returnArray($field)
				} else {
					array set tmpArray $returnArray($parentFields)
					if {![info exists tmpArray($subField)]} {
						set tmpArray($subField) $value
					} else {
						set tmpArray($subField) [concat $tmpArray($subField) $value]
					}
					set returnArray($parentFields) [array get tmpArray]
					array unset tmpArray
					set fieldArray($field) $returnArray($field)
					unset returnArray($field)
				}
			}			
		}
 		if {[info exists fieldArray($args)]} {
			# $args is a certain deeper level field (pattern), all subfields deeper in the hierachy are returned
 			set returnString $fieldArray($args)
		} else {
			if {[info exists returnArray($args)]} {
				# $args is a first level field (pattern), all subfields deeper in the hierachy are returned
				set returnString $returnArray($args)
			} else {
				if {$args == "*"} {
					# $args=* is regarded as root field -> all subfields of returnArray are returned
					# WARNING "*" doesnt work properly
					set returnString [array get returnArray]
				} else {
					set returnString {}
				}
			}
		}
		if {$nosublists} {
			set returnString [nosublists $returnString]
		}
		return $returnString
	}
}

namespace eval atom {
	
	namespace eval filterlist {
	
		variable filterlist
		
		set filterlist(regularAtomTypes) "normal"
		set filterlist(specialAtomTypes) "!normal"
		set filterlist(removeExplicitStdVal) [concat !metal !hydrogen $filterlist(regularAtomTypes)]
		set filterlist(noHydrogenAddtion) $filterlist(specialAtomTypes)
		set filterlist(unchargedAtoms) [concat !charged !hydrogen !boron !metal]
		set filterlist(chargedAtoms) [concat charged !hydrogen !boron !metal]
		set filterlist(checkForChargeAtomList) [concat !metal !boron !hydrogen]
			
		proc get {name} {
			variable filterlist
			if {[info exists filterlist($name)]} {
				return $filterlist($name)
			} else {
				error "unknown filter '$name'"
			}
		}
	}

	namespace eval test {}
	
	namespace eval element {
		
		# rows of 'table0' in CACTVS contain basic information about any element 
		# of the PSE
		table loop table0 row {
			set symbol [lindex $row 0]
			if {$symbol == "\?"} {continue}
			set ismetal [lindex $row 6]
			#set element($symbol,ismetal) $ismetal
			set group [lindex $row 3]
			set element($symbol,organicRelevance) 0
			set valenceList [lindex $row 12]
			if {[llength $valenceList]} {
				set element($symbol,maxValence) [eval max $valenceList]
				set element($symbol,minValence) [eval min $valenceList]
			} else {
				set element($symbol,maxValence) 6
				set element($symbol,minValence)	0		
			}
			if {$ismetal} {
				if {$group == 1} {
					set element($symbol,minimalComplexCoordinationNumber) 6
					set element($symbol,hydridCharacter) "ionic"
					set element($symbol,oxidCharacter) "ionic"
				} elseif {$group == 2} {
					set element($symbol,minimalComplexCoordinationNumber) 6
					set element($symbol,hydridCharacter) "covalent"
					set element($symbol,oxidCharacter) "ionic"
				} elseif {$group >= 3 && $group <=11} {
					set element($symbol,minimalComplexCoordinationNumber) 6
					set element($symbol,hydridCharacter) "complex"
					set element($symbol,oxidCharacter) "covalent"
				} elseif {$group >= 12 && $group <= 16} {
					set element($symbol,minimalComplexCoordinationNumber) 4
					set element($symbol,hydridCharacter) "covalent"
					set element($symbol,oxidCharacter) "covalent"
				} elseif {$group == 19 || $group == 20} {
					set element($symbol,minimalComplexCoordinationNumber) 6
					set element($symbol,hydridCharacter) "keep"
					set element($symbol,oxidCharacter) "keep"
				}
			} else {
				set element($symbol,maxValenceLonePairs) [expr ([table celldata table0 $symbol shellelectrons] - $element($symbol,minValence)) / 2]
				set element($symbol,maxValenceLonePairElectrons) [expr $element($symbol,maxValenceLonePairs) * 2]

			}
		}
		set element(D,organicRelevance) 0
		set element(T,organicRelevance) 0
		
		proc get {symbol attribute} {
			variable element
			if {$symbol == "?"} {return 0}
			if {[info exists element($symbol,$attribute)]} {
				return $element($symbol,$attribute)
			} else {
				error "atom::element::get: unknown attribute '$attribute' for atom element '$symbol'"
			}
		}
			
		proc assign {symbolList attribute value} {
			variable element
			foreach symbol $symbolList {
				if {[info exists element($symbol,$attribute)]} {
					set element($symbol,$attribute) $value
				} else {
					error "atom::element::assign: unknown attribute '$attribute' for atom element '$symbol'"			
				}
			}
		}
		
		# we overwrite some of the defaults here:
		assign [list H D T C O] organicRelevance 10
		#assign [list O] organicRelevance 9
		assign [list P N] organicRelevance 8
		assign [list S Cl Br] organicRelevance 6
		assign [list Si F I Na] organicRelevance 5
		assign [list K Mg] organicRelevance 4
		assign [list Se Pt Co Fe Ca As Au] organicRelevance 3
		assign [list Cu Zn Cr Hg Cd] organicRelevance 2
		assign [list B Pb Al Mn Li Ag] organicRelevance 1
		
		assign [list Ni Pd Pt Cu] minimalComplexCoordinationNumber 4
		assign [list Ag Au] minimalComplexCoordinationNumber 2
		
		assign Be hydridCharacter "covalent"
 		assign [list Sc Y Cs Fr Ra] hydridCharacter "keep"
		
		assign Be oxidCharacter "covalent"
 		assign [list Al] oxidCharacter "ionic"
		
		assign [list V Nb Ta] maxValence 5
	}
}

namespace eval ens {
 		
	namespace eval parameter {} {
		
		variable parameter
		set parameter(maxAtoms) 400
		set parameter(maxRingRatio) 2
		
		proc get {name} {
			variable parameter
			if {[info exists parameter($name)]} {
				return $parameter($name)
			} else {
				error "ens::parameter::get: unknown parameter '$name'"
			}
		}
	}

	namespace eval resonance {
		if 0 {catch {
		::prop create A_NCICADD_RESONANCE_STEREO_DELETED datatype boolean default 0
		::prop create B_NCICADD_RESONANCE_CROSSED datatype boolean default 0
		}}
		::filter create resonancedeletedstereoatom property A_NCICADD_RESONANCE_STEREO_DELETED value1 1 operator eq 
		::filter create resonancecrossedbond property B_NCICADD_RESONANCE_CROSSED value1 1 operator eq
	}

	namespace eval tautomer {
		if 0 {catch {
		::prop create A_NCICADD_TAUTO_STEREO_DELETED datatype boolean default 0
		::prop create B_NCICADD_TAUTO_CROSSED datatype boolean default 0
		}}
		::filter create tautodeletedstereoatom property A_NCICADD_TAUTO_STEREO_DELETED value1 1 operator eq 
		::filter create tautocrossedbond property B_NCICADD_TAUTO_CROSSED value1 1 operator eq
	}

	namespace eval filter {}
	
	namespace eval test {
				
		namespace eval aux {}

		variable test
		
		set test(global,testOrder) [list \
			noAtoms \
			singleAtom \
			empty \
			organic \
			pseudoOrganic \
			inorganic \
			specialAtomTypes \
			isotopes \
			metalAtoms \
			singleMetalAtoms \
			singleHydrogenAtoms \
			sizeLimit \
			clusterCompound \
			noStereo \
			unspecifiedStereo \
			partialStereo \
			fullStereo \
			meso \
			enantiomer \
			diastereomer \
			neutralSalt \
			organoMetallic \
			metalComplex \
			radical \
		]
		
		proc getglobalparam {parameter} {
			variable test
			if {[info exists test(global,$parameter)]} {
				return $test(global,$parameter)
			} else {
				error "unknown global test parameter '$parameter'"
			}
		}
				
		proc createDefaultParameterArray {} {
			foreach operation [getglobalparam testOrder] {
				set tmpArray($operation) 0
			}
			return [array get tmpArray]
		}
		
		proc createParameterArray {defaultArrayList testList value} {
			array set tmpArray $defaultArrayList
			switch $testList {
				all -
				any -
				alloperation -
				anyoperation {set testList [getglobalparam testOrder]}
				default {}
			}
			switch $value {
				on -
				ON -
				true -
				TRUE -
				1 {set bool 1}
				off -
				OFF -
				false -
				FALSE -
				0 {set bool 0}
				default {set bool 0}
			}
			foreach test $testList {
				if {![info exists tmpArray($test)]} {
					error "ens::test::createParameterArray: unknown test '$test' in array list '$array'"
				}
				set tmpArray($test) $bool
			}
			return [array get tmpArray]
		}

		if 0 {catch {
		prop create E_NCICADD_TEST_STATUS_BITSET datatype bitvector default 0
		prop create E_NCICADD_TEST_ERROR_BITSET datatype bitvector default 0
		}}
	}
		
	namespace eval norm {
	
		variable norm
		#set norm(global,debug) 1
		set norm(global,normOrder) [list \
			singleMetalAtoms \
			singleHydrogenAtoms \
			singleHalogenAtoms \
			deleteSearchInfo \
			radical \
			functionalGroups \
			hsaturation \
			metalLigandBonds \
			desalt \
			deleteMetalComplexCenter \
			resonance \
			grabLargestFragment \
			uncharge \
			tautomer \
			stereo \
			deleteStereoInfo \
			deleteIsotopeLabels \
		]
			
		set norm(deleteIsotopeLabels,argList) {}
		set norm(radical,argList) {}
		set norm(hsaturation,argList) [list 0 0 {} [atom::filterlist::get noHydrogenAddtion] nometals {}]
		set norm(functionalGroups,argList) {}
		set norm(metalLigandBonds,argList) {}
		set norm(deleteStereoInfo,argList) {}
		set norm(stereo,argList) [list 1 1 0 0 0 0]
		set norm(deleteSearchInfo,argList) {}
		set norm(desalt,argList) {}
		set norm(deleteMetalComplexCenter,argList) {}
		set norm(resonance,argList) [list 1000 0 E_HASHY 1 1]
		set norm(uncharge,argList) [list 1 E_HASHY]
		set norm(singleMetalAtoms,argList) {}
		set norm(singleHydrogenAtoms,argList) {}
		set norm(singleHalogenAtoms,argList) {}
		set norm(tautomer,argList) [list 1000 0 E_HASHY 0 0 0 0 1 0]
		set norm(grabLargestFragment,argList) {}
	
		if 0 {catch {
		prop create A_NCICADD_NORM_CHARGE datatype boolean default 0
		}}
		filter create normcharge prop A_NCICADD_NORM_CHARGE operator eq value 1
		
		proc assign {attribute value} {
			variable norm
			if {![info exists norm(global,$attribute)]} {
				error "ens::norm::assign: unknown attribute '$attribute'"
			} 
			set norm($attribute) $value
			return $norm($attribute)
		}
				
		proc getglobalparam {attribute} {
			variable norm
			if {![info exists norm(global,$attribute)]} {
				error "ens::norm::getglobalparam: unknown attribute '$attribute'"
			} 
			return $norm(global,$attribute)
		}
		
		proc getArgList {operation} {
			variable norm
			return $norm($operation,argList)
		}
		
		proc getDefaultArgArray {} {
			variable norm
			foreach operation [getglobalparam normOrder] {
				set tmpArray($operation) $norm($operation,argList)
			}
			return [array get tmpArray]
		}
		
		proc createDefaultParameterArray {} {
			foreach operation [getglobalparam normOrder] {
				set tmpArray($operation) 0
			}
			return [array get tmpArray]
		}
		
		proc getArgArray {arrayList operationArgList} {
			array set tmpArray $arrayList
			foreach {operation argList} $operationArgList {
				if {![info exists tmpArray($operation)]} {
					error "ens::norm::getArgArray: unknown normalization operation '$operation' in array list '$array'"
				}
				set tmpArray($operation) $argList
				
			}
			return [array get tmpArray]
		}
			
		proc createParameterArray {arrayList operationList value} {
			array set tmpArray $arrayList
			switch $operationList {
				all -
				any -
				alloperation -
				anyoperation {set operationList [getglobalparam normOrder]}
				default {}
			}
			switch $value {
				on -
				ON -
				true -
				TRUE -
				1 {set bool 1}
				off -
				OFF -
				false -
				FALSE -
				0 {set bool 0}
				default {set bool 0}
			}
			foreach operation $operationList {
				if {![info exists tmpArray($operation)]} {
					error "ens::norm::createParameterArray: unknown normalization operation '$operation' in array list '$arrayList'"
				}
				set tmpArray($operation) $bool
			}
			return [array get tmpArray]
		}
	}
		
	namespace eval identifier {
	
		namespace eval postcmd {
			
			variable postcmd
			
			namespace eval test {
				namespace eval true {}
				namespace eval false {}
			}

			namespace eval norm {
				namespace eval true {}
				namespace eval false {}
			}

			set postcmd(test,true,noAtoms) noAtoms
			set postcmd(test,true,singleAtom) \{\}
			set postcmd(test,true,organic) \{\}
			set postcmd(test,true,pseudoOrganic) \{\}
			set postcmd(test,true,inorganic) inorganic
			set postcmd(test,true,empty) empty
			set postcmd(test,true,specialAtomTypes) specialAtomTypes
			set postcmd(test,true,isotopes) \{\}
			set postcmd(test,true,metalAtoms) \{\}
			set postcmd(test,true,singleMetalAtoms) singleMetalAtoms 
			set postcmd(test,true,singleHydrogenAtoms) singleHydrogenAtoms
			set postcmd(test,true,sizeLimit) sizeLimit
			set postcmd(test,true,clusterCompound) clusterCompound
			set postcmd(test,true,noStereo) noStereo
			set postcmd(test,true,unspecifiedStereo) \{\}
			set postcmd(test,true,partialStereo) \{\}
			set postcmd(test,true,fullStereo) \{\}
			set postcmd(test,true,meso) \{\}
			set postcmd(test,true,diastereomer) \{\}
			set postcmd(test,true,enantiomer) \{\}
 			set postcmd(test,true,neutralSalt) \{\}
			set postcmd(test,true,organoMetallic) \{\}
			set postcmd(test,true,metalComplex) metalComplex
			set postcmd(test,true,radical) radical
			set postcmd(test,false,noAtoms) \{\}
			set postcmd(test,false,singleAtom) \{\}
			set postcmd(test,false,organic) \{\}
			set postcmd(test,false,pseudoOrganic) \{\}
			set postcmd(test,false,inorganic) \{\}
			set postcmd(test,false,empty) \{\}
			set postcmd(test,false,specialAtomTypes) \{\}
			set postcmd(test,false,isotopes) \{\}
			set postcmd(test,false,metalAtoms) metalAtoms
			set postcmd(test,false,singleMetalAtoms) \{\} 
			set postcmd(test,false,singleHydrogenAtoms) \{\}
			set postcmd(test,false,sizeLimit) \{\}
			set postcmd(test,false,clusterCompound) \{\}
			set postcmd(test,false,noStereo) \{\}
			set postcmd(test,false,unspecifiedStereo) \{\}
			set postcmd(test,false,partialStereo) \{\}
			set postcmd(test,false,fullStereo) \{\}
			set postcmd(test,false,meso) \{\}
			set postcmd(test,false,diastereomer) \{\}
			set postcmd(test,false,enantiomer) \{\}
 			set postcmd(test,false,neutralSalt) \{\}
			set postcmd(test,false,metalComplex) metalComplex
			set postcmd(test,false,organoMetallic) \{\}
			set postcmd(test,false,radical) radical

			set postcmd(norm,true,singleMetalAtoms) \{\}
			set postcmd(norm,true,singleHydrogenAtoms) \{\}
			set postcmd(norm,true,singleHalogenAtoms) \{\}
			set postcmd(norm,true,deleteSearchInfo) \{\}
			set postcmd(norm,true,deleteIsotopeLabels) \{\}
			set postcmd(norm,true,radical) \{\}
			set postcmd(norm,true,metalLigandBonds) \{\}
			set postcmd(norm,true,hsaturation) \{\}
			set postcmd(norm,true,functionalGroups) \{\}
			set postcmd(norm,true,desalt) \{\}
			set postcmd(norm,true,deleteMetalComplexCenter) deleteMetalComplexCenter
			set postcmd(norm,true,resonance) \{\}
			set postcmd(norm,true,uncharge) uncharge
			set postcmd(norm,true,grabLargestFragment) grabLargestFragment
			set postcmd(norm,true,tautomer) tautomer
			set postcmd(norm,true,stereo) \{\}
			set postcmd(norm,true,deleteStereoInfo) \{\}
			set postcmd(norm,false,singleMetalAtoms) \{\}
			set postcmd(norm,false,singleHydrogenAtoms) \{\}
			set postcmd(norm,false,singleHalogenAtoms) \{\}
			set postcmd(norm,false,deleteSearchInfo) \{\}
			set postcmd(norm,false,deleteIsotopeLabels) \{\}
			set postcmd(norm,false,radical) \{\}
			set postcmd(norm,false,metalLigandBonds) \{\}
			set postcmd(norm,false,hsaturation) \{\}
			set postcmd(norm,false,functionalGroups) \{\}
			set postcmd(norm,false,desalt) \{\}
			set postcmd(norm,false,deleteMetalComplexCenter) \{\}
			set postcmd(norm,false,resonance) \{\}
			set postcmd(norm,false,uncharge) \{\}
			set postcmd(norm,false,grabLargestFragment) \{\}
			set postcmd(norm,false,tautomer) \{\}
			set postcmd(norm,false,stereo) \{\}
			set postcmd(norm,false,deleteStereoInfo) \{\}
			
			proc get {class boolean cmdName} {
				variable postcmd
				if {[info exists postcmd($class,$boolean,$cmdName)]} {
					return $postcmd($class,$boolean,$cmdName)
				} else {
					error "unknown command name '$cmdName' in class '$class' for boolean '$boolean'"
				}
			}
			
			# unused
			proc test::true::dummy {switchArray} {
				proparray::rdelete dummy
				proparray::rassign dummy $switchArray
				proparray::assign -forceerrorifnotexists dummy norm parameters singleMetalAtoms -1
				proparray::assign -forceerrorifnotexists dummy norm parameters singleHydrogenAtoms -1
				proparray::assign -forceerrorifnotexists dummy norm parameters singleHalogenAtoms -1
				proparray::assign -forceerrorifnotexists dummy norm parameters deleteSearchInfo -1
				proparray::assign -forceerrorifnotexists dummy norm parameters radical -1
				proparray::assign -forceerrorifnotexists dummy norm parameters functionalGroups -1
				proparray::assign -forceerrorifnotexists dummy norm parameters hsaturation -1
				proparray::assign -forceerrorifnotexists dummy norm parameters metalLigandBonds -1
				proparray::assign -forceerrorifnotexists dummy norm parameters desalt -1
				proparray::assign -forceerrorifnotexists dummy norm parameters deleteMetalComplexCenter -1
				proparray::assign -forceerrorifnotexists dummy norm parameters resonance -1
				proparray::assign -forceerrorifnotexists dummy norm parameters uncharge -1
				proparray::assign -forceerrorifnotexists dummy norm parameters grabLargestFragment -1
				proparray::assign -forceerrorifnotexists dummy norm parameters tautomer -1
				proparray::assign -forceerrorifnotexists dummy norm parameters stereo -1
				proparray::assign -forceerrorifnotexists dummy norm parameters deleteStereoInfo -1
				proparray::assign -forceerrorifnotexists dummy norm parameters deleteIsotopeLabels -1
				return [proparray::rget dummy]
			}

			proc test::true::singleMetalAtoms {switchArray} {
				proparray::rdelete singleMetalAtoms
				proparray::rassign singleMetalAtoms $switchArray
 				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters singleHydrogenAtoms -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters singleHalogenAtoms -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters deleteSearchInfo -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters radical -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters functionalGroups -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters hsaturation -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters metalLigandBonds -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters desalt -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters deleteMetalComplexCenter -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters resonance -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters uncharge -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters grabLargestFragment -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters tautomer -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters stereo -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters deleteStereoInfo -1
				proparray::assign -forceerrorifnotexists singleMetalAtoms norm parameters deleteIsotopeLabels -1
				return [proparray::rget singleMetalAtoms]
			}

			proc test::true::singleHydrogenAtoms {switchArray} {
				proparray::rdelete singleHydrogenAtoms
				proparray::rassign singleHydrogenAtoms $switchArray
 				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters singleHalogenAtoms -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters deleteSearchInfo -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters radical -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters functionalGroups -1
 				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters metalLigandBonds -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters desalt -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters deleteMetalComplexCenter -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters resonance -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters uncharge -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters grabLargestFragment -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters tautomer -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters stereo -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters deleteStereoInfo -1
				proparray::assign -forceerrorifnotexists singleHydrogenAtoms norm parameters deleteIsotopeLabels -1
				return [proparray::rget singleHydrogenAtoms]
			}

			proc test::false::radical {switchArray} {
				proparray::rdelete radical
				proparray::rassign radical $switchArray
				proparray::assign -forceerrorifnotexists radical norm parameters radical -1
				return [proparray::rget radical]
			}

			proc test::true::radical {switchArray} {
				proparray::rdelete radical
				proparray::rassign radical $switchArray
				#proparray::assign -forceerrorifnotexists radical norm parameters resonance -1
				return [proparray::rget radical]
			}

			proc test::true::empty {switchArray} {
				proparray::rdelete empty
				proparray::rassign empty $switchArray
				proparray::assign -forceerrorifnotexists empty norm exec -1
				return [proparray::rget empty]
			}

			proc test::true::noAtoms {switchArray} {
				proparray::rdelete noatoms
				proparray::rassign noatoms $switchArray
				proparray::assign -forceerrorifnotexists noatoms norm exec -1
				return [proparray::rget noatoms]
			}

			proc test::true::sizeLimit {switchArray} {
				proparray::rdelete sizelimit
				proparray::rassign sizelimit $switchArray
				proparray::assign -forceerrorifnotexists sizelimit norm exec -1
				return [proparray::rget sizelimit]
			}

			proc test::true::specialAtomTypes {switchArray} {
				proparray::rdelete special
				proparray::rassign special $switchArray
				proparray::assign -forceerrorifnotexists special norm exec -1
				return [proparray::rget special]
			}

			proc test::true::clusterCompound {switchArray} {
				proparray::rdelete clustercompound
				proparray::rassign clustercompound $switchArray
				proparray::assign -forceerrorifnotexists clustercompound norm exec -1
				return [proparray::rget clustercompound]
			}

			proc test::false::metalAtoms {switchArray} {
				proparray::rdelete metalAtoms
				proparray::rassign metalAtoms $switchArray
				proparray::assign -forceerrorifnotexists metalAtoms norm parameters metalLigandBonds -1
				return [proparray::rget metalAtoms]
			}

			proc test::true::metalComplex {switchArray} {
				proparray::rdelete metalComplexSwitches
				proparray::rassign metalComplexSwitches $switchArray
				proparray::assign -forceerrorifnotexists metalComplexSwitches norm parameters resonance -1
				proparray::assign -forceerrorifnotexists metalComplexSwitches norm parameters tautomer -1
				return [proparray::rget metalComplexSwitches]
			}

			proc test::false::metalComplex {switchArray} {
				proparray::rdelete metalComplexSwitches
				proparray::rassign metalComplexSwitches $switchArray
				proparray::assign -forceerrorifnotexists metalComplexSwitches norm parameters deleteMetalComplexCenter -1
				return [proparray::rget metalComplexSwitches]
			}

			proc test::true::noStereo {switchArray} {
				proparray::rdelete noStereo
				proparray::rassign noStereo $switchArray
				#proparray::assign -forceerrorifnotexists noStereo norm parameters stereo -1
				return [proparray::rget noStereo]
			}

			proc test::true::inorganic {switchArray} {
				proparray::rdelete inorganicSwitches
				proparray::rassign inorganicSwitches $switchArray
				proparray::assign -forceerrorifnotexists inorganicSwitches norm parameters tautomer -1
				proparray::assign -forceerrorifnotexists inorganicSwitches norm parameters desalt -1
				proparray::assign -forceerrorifnotexists inorganicSwitches norm parameters uncharge -1
 				proparray::assign -forceerrorifnotexists inorganicSwitches norm parameters grabLargestFragment -1
				return [proparray::rget inorganicSwitches]
			}

			proc norm::true::deleteMetalComplexCenter {ehandle normParameter normArgList} {
 				set gstatus [ens::norm::grabLargestFragment $ehandle]
				set ustatus [ens::norm::uncharge $ehandle 0 E_HASHY]
				set hstatus [ens::norm::hsaturation $ehandle 0 1 {} [atom::filterlist::get noHydrogenAddtion] {nometals nospecial} {}]
				set fstatus [ens::norm::functionalGroups $ehandle]
				return [expr $gstatus || $ustatus || $hstatus || $fstatus]
			}

			proc norm::true::grabLargestFragment {ehandle normParameter normArgList} {
				set dstatus [ens::norm::desalt $ehandle]
				set hstatus [ens::norm::hsaturation $ehandle 0 1 {} [atom::filterlist::get noHydrogenAddtion] {nometals nospecial} {}]
				return [expr $dstatus || $hstatus]
			}
			
			proc norm::true::tautomer {ehandle normParameter normArgList} {
				proparray::rdelete posttauto
				proparray::rassign posttauto norm parameter $normParameter
				if {[proparray::get posttauto norm parameter hsaturation]} {
					set hstatus [ens::norm::hsaturation $ehandle 0 1 {} [atom::filterlist::get noHydrogenAddtion] {nometals nospecial} {atom bond}]
				}
				return $hstatus
			}

			proc norm::true::uncharge {ehandle normParameter normArgList} {
				#set fstatus 0
				set fstatus [ens::norm::functionalGroups $ehandle]
				set hstatus [ens::norm::hsaturation $ehandle 0 1 {} [atom::filterlist::get noHydrogenAddtion] {nometals nospecial} {atom bond}]
 				return [expr $hstatus || $fstatus]
			}
		}
		
		variable identifier
		
		set testOrder [ens::test::getglobalparam testOrder]
		set defaultTestParameterArray [ens::test::createDefaultParameterArray]
		
		set normOrder [ens::norm::getglobalparam normOrder]
		set normBaseList [list deleteSearchInfo metalLigandBonds hsaturation functionalGroups]
		set normLargestFragment [list singleMetalAtoms singleHydrogenAtoms singleHalogenAtoms radical desalt deleteMetalComplexCenter grabLargestFragment]
		set defaultNormParameterArray [ens::norm::createDefaultParameterArray]
		array set normParameterArgs [ens::norm::getDefaultArgArray]
		array set normBaseListArray [ens::norm::createParameterArray $defaultNormParameterArray $normBaseList 1]

		# setting global default values for all identifiers
		set identifier(global,debug) 0
		set identifier(global,debugtrace) \{\}
		set identifier(global,addtag) 1
		set identifier(global,addprimarytag) 1
		set identifier(global,primarytag) "xxxxx" ;# will be set to identifier name in proc create
		set identifier(global,addsecondarytag) 1
		set identifier(global,secondarytag) 01-xx
		set identifier(global,tagseparator) "-"
		set identifier(global,datatype) string
		set identifier(global,timeout) 0
		set identifier(global,magic) "FFFFFFFFFFFFFFFF"
		set identifier(global,forcemagic) 0
		set identifier(global,default) "0000000000000000"
		set identifier(global,maxtautomers) 1000
		set identifier(global,norm) 1
		set identifier(global,postnorm) 1
		set identifier(global,test) 1
		set identifier(global,posttest) 1
		set identifier(global,functiontype) tcl
		set identifier(global,prefix) "NCICADD"
		set identifier(global,names) [list FICTu FICTS FICuu FICuS uuuTu uuuTS uuuuu uuuuS FICxx uuuxx ncicadd_parent]
		set identifier(global,regexpNormName) [list {\*} {E_} {NCICADD} {_ID} {_}]
		set identifier(global,generalPurgeProps) [list E_SMILES A_HASH A_HASHS M_HASH M_HASHS]
		set identifier(global,normBaseParameters) [array get normBaseListArray]
		set identifier(global,normExemptionPropName) "E_IDENTIFIER_NORM_EXEMPTION_LIST" 
					
 		set identifier(FICTu,scope) public
		set identifier(FICTS,scope) public
		set identifier(FICuu,scope) public
		set identifier(FICuS,scope) public
		set identifier(uuuTu,scope) public 
		set identifier(uuuTS,scope) public
		set identifier(uuuuu,scope) public
		set identifier(uuuuS,scope) public
		set identifier(FICxx,scope) private
		set identifier(uuuxx,scope) private
		set identifier(ncicadd_parent,scope) private

		set identifier(FICTu,csBaseHash) E_HASHIY 
		set identifier(FICTS,csBaseHash) E_HASHISY
		set identifier(FICuu,csBaseHash) E_HASHIY
		set identifier(FICuS,csBaseHash) E_HASHISY
		set identifier(uuuTu,csBaseHash) E_HASHY 
		set identifier(uuuTS,csBaseHash) E_HASHSY
		set identifier(uuuuu,csBaseHash) E_HASHY
		set identifier(uuuuS,csBaseHash) E_HASHSY
		set identifier(FICxx,csBaseHash) E_HASHIY
		set identifier(uuuxx,csBaseHash) E_HASHY
		set identifier(ncicadd_parent,csBaseHash) E_HASHISY
    
		set identifier(FICTu,testOrder) $testOrder
		set identifier(FICTS,testOrder) $testOrder
		set identifier(FICuu,testOrder) $testOrder
		set identifier(FICuS,testOrder) $testOrder
		set identifier(uuuTu,testOrder) $testOrder
		set identifier(uuuTS,testOrder) $testOrder
		set identifier(uuuuu,testOrder) $testOrder
		set identifier(uuuuS,testOrder) $testOrder
		set identifier(FICxx,testOrder) $testOrder
		set identifier(uuuxx,testOrder) $testOrder
		set identifier(ncicadd_parent,testOrder) $testOrder
    	
		set identifier(FICTu,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(FICTS,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(FICuu,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(FICuS,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(uuuTu,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(uuuTS,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(uuuuu,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(uuuuS,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(FICxx,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(uuuxx,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]
		set identifier(ncicadd_parent,testParameters) [ens::test::createParameterArray $defaultTestParameterArray all 1]

 		set identifier(FICTu,normOrder) $normOrder
		set identifier(FICTS,normOrder) $normOrder
		set identifier(FICuu,normOrder) $normOrder
		set identifier(FICuS,normOrder) $normOrder
		set identifier(uuuTu,normOrder) $normOrder
		set identifier(uuuTS,normOrder) $normOrder
		set identifier(uuuuu,normOrder) $normOrder
		set identifier(uuuuS,normOrder) $normOrder
		set identifier(FICxx,normOrder) $normOrder
		set identifier(uuuxx,normOrder) $normOrder
		set identifier(ncicadd_parent,normOrder) $normOrder

		# order does not matter in the following list:
		set normList(FICTu) [concat $normBaseList resonance stereo deleteStereoInfo]
		set normList(FICTS) [concat $normBaseList resonance stereo]
		set normList(FICuu) [concat $normBaseList resonance stereo tautomer deleteStereoInfo]
		set normList(FICuS) [concat $normBaseList resonance stereo tautomer]
		set normList(uuuTu) [concat $normBaseList $normLargestFragment resonance stereo deleteIsotopeLabels uncharge deleteStereoInfo]
		set normList(uuuTS) [concat $normBaseList $normLargestFragment resonance stereo deleteIsotopeLabels uncharge]
		set normList(uuuuu) [concat $normBaseList $normLargestFragment resonance stereo deleteIsotopeLabels uncharge tautomer deleteStereoInfo]
		set normList(uuuuS) [concat $normBaseList $normLargestFragment resonance stereo deleteIsotopeLabels uncharge tautomer]
		set normList(FICxx) [concat $normBaseList resonance stereo]
		set normList(uuuxx) [concat $normBaseList $normLargestFragment resonance stereo deleteIsotopeLabels uncharge]
		set normList(ncicadd_parent) [list deleteSearchInfo hsaturation functionalGroups stereo]

		set identifier(FICTu,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(FICTu) 1]
		set identifier(FICTS,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(FICTS) 1]
		set identifier(FICuu,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(FICuu) 1]
		set identifier(FICuS,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(FICuS) 1]
		set identifier(uuuTu,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(uuuTu) 1]
		set identifier(uuuTS,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(uuuTS) 1]
		set identifier(uuuuu,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(uuuuu) 1]
		set identifier(uuuuS,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(uuuuS) 1]
		set identifier(FICxx,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(FICxx) 1]
		set identifier(uuuxx,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(uuuxx) 1]
		set identifier(ncicadd_parent,normParameters) [ens::norm::createParameterArray $defaultNormParameterArray $normList(ncicadd_parent) 1]

		array set FICxxParameterArgs [array get normParameterArgs]
		set FICxxParameterArgs(hsaturation) [list 0 0 {} [atom::filterlist::get noHydrogenAddtion] {noatoms nometals nospecial} {}]
		set FICxxParameterArgs(uncharge) [list 0 E_HASHY]

		array set uuuxxParameterArgs [array get normParameterArgs]
		set uuuxxParameterArgs(hsaturation) [list 0 1 {} [atom::filterlist::get noHydrogenAddtion] {nometals nospecial} {}]
		set uuuxxParameterArgs(uncharge) [list 1 E_HASHY]

		set identifier(FICTu,normParameterArgs) [array get FICxxParameterArgs]
		set identifier(FICTS,normParameterArgs) [array get FICxxParameterArgs]
		set identifier(FICuu,normParameterArgs) [array get FICxxParameterArgs]
		set identifier(FICuS,normParameterArgs) [array get FICxxParameterArgs]
		set identifier(uuuTu,normParameterArgs) [array get uuuxxParameterArgs]
		set identifier(uuuTS,normParameterArgs) [array get uuuxxParameterArgs]
		set identifier(uuuuu,normParameterArgs) [array get uuuxxParameterArgs]
		set identifier(uuuuS,normParameterArgs) [array get uuuxxParameterArgs]
		set identifier(FICxx,normParameterArgs) [array get FICxxParameterArgs]
		set identifier(uuuxx,normParameterArgs) [array get uuuxxParameterArgs]
		set identifier(ncicadd_parent,normParameterArgs) [array get FICxxParameterArgs]

		#array set FICTSParameterArgs $identifier(FICTS,normParameterArgs)
		#array set FICTuParameterArgs $identifier(FICTu,normParameterArgs)
		#set FICTSParameterArgs(stereo) [list 1 1 0 1]
		#set FICTuParameterArgs(stereo) [list 1 1 0 1]
		#set identifier(FICTS,normParameterArgs) [array get FICTSParameterArgs]
		#set identifier(FICTu,normParameterArgs) [array get FICTuParameterArgs]

		#array set uuuTSParameterArgs $identifier(uuuTS,normParameterArgs)
		#array set uuuTuParameterArgs $identifier(uuuTu,normParameterArgs)
		#set uuuTSParameterArgs(stereo) [list 1 1 0 1]
		#set uuuTuParameterArgs(stereo) [list 1 1 0 1]
		#set identifier(uuuTS,normParameterArgs) [array get uuuTSParameterArgs]
		#set identifier(uuuTu,normParameterArgs) [array get uuuTuParameterArgs]

		
		set postTestTrueCmdList {}
		set postTestFalseCmdList {}
		foreach {parameter bool} [ens::test::createDefaultParameterArray] {
			lappend postTestTrueCmdList $parameter [postcmd::get test true $parameter]
			lappend postTestFalseCmdList $parameter [postcmd::get test false $parameter]
		}
		set postNormTrueCmdList {}
		set postNormFalseCmdList {}
		foreach {parameter bool} [ens::norm::createDefaultParameterArray] {
			lappend postNormTrueCmdList $parameter [postcmd::get norm true $parameter]
			lappend postNormFalseCmdList $parameter [postcmd::get norm false $parameter]
		}
		set postTestCmdList [list true $postTestTrueCmdList false $postTestFalseCmdList]
		set postNormCmdList [list true $postNormTrueCmdList false $postNormFalseCmdList]
				
		set identifier(FICTu,postTestCmds) $postTestCmdList
		set identifier(FICTS,postTestCmds) $postTestCmdList
		set identifier(FICuu,postTestCmds) $postTestCmdList
		set identifier(FICuS,postTestCmds) $postTestCmdList
		set identifier(uuuTu,postTestCmds) $postTestCmdList
		set identifier(uuuTS,postTestCmds) $postTestCmdList
		set identifier(uuuuu,postTestCmds) $postTestCmdList
		set identifier(uuuuS,postTestCmds) $postTestCmdList
		set identifier(FICxx,postTestCmds) $postTestCmdList
		set identifier(uuuxx,postTestCmds) $postTestCmdList
		set identifier(ncicadd_parent,postTestCmds) $postTestCmdList
 		
		set identifier(FICTu,postNormCmds) $postNormCmdList
		set identifier(FICTS,postNormCmds) $postNormCmdList
		set identifier(FICuu,postNormCmds) $postNormCmdList
		set identifier(FICuS,postNormCmds) $postNormCmdList
		set identifier(uuuTu,postNormCmds) $postNormCmdList
		set identifier(uuuTS,postNormCmds) $postNormCmdList
		set identifier(uuuuu,postNormCmds) $postNormCmdList
		set identifier(uuuuS,postNormCmds) $postNormCmdList
		set identifier(FICxx,postNormCmds) $postNormCmdList
		set identifier(uuuxx,postNormCmds) $postNormCmdList
		set identifier(ncicadd_parent,postNormCmds) $postNormCmdList

		proc exists {identifierName} {
			variable identifier
			if {[lsearch $identifier(global,names) $identifierName] != -1} {
				return 1
			}
			return 0
		}
				
		proc getparam {identifierName parameter} {
			variable identifier
			if {[info exists identifier($identifierName,$parameter)]} {
				return $identifier($identifierName,$parameter)
			} else {
				error "unknown parameter '$parameter' for identifier '$identifierName'"
			}
		}
		
		proc getglobalparam {parameter} {
			variable identifier
			if {[info exists identifier(global,$parameter)]} {
				return $identifier(global,$parameter)
			} else {
				error "unknown global identifier parameter '$parameter'"
			}
		}
		
		proc globalparamexists {parameter} {
			variable identifier
			if {[info exists identifier(global,$parameter)]} {
				return 1
			}
			return 0
		}
				
		proc getNames {{onlyPublicNames 1}} {
			variable identifier
			set returnList {}
			foreach name $identifier(global,names) {
				set identifierName [normName $name]
				if {$onlyPublicNames} {
					if {[getparam $identifierName scope] == "public"} {
						lappend returnList $name
					} 
				} else {
					lappend returnList $name
				}
			}
			return $returnList
		}

		proc getPropNames {{onlyPublicNames 1}} {
			variable identifier
			set returnList {}
			foreach name $identifier(global,names) {
				set identifierName [normName $name]
				set propName [getPropName $identifierName]
				if {$onlyPublicNames} {
					if {[getparam $identifierName scope] == "public"} {
						lappend returnList $propName
					} 
				} else {
					lappend returnList $propName
				}
			}
			return $returnList
		}
		
		proc normName {identifierName} {
			set string $identifierName
			set availableNameList [getglobalparam names]
			switch $string {
				\* -
				any -
				all {
					return $availableNameList
				}
				default {
					set patternList [getglobalparam regexpNormName]
					foreach pattern $patternList {
						if {$string=="ncicadd_parent"} continue
						regsub -all $pattern $string {} string
					}
					set string [string tolower $string] 
					set index [lsearch [string tolower $availableNameList] $string]
					if {$index != -1} {
						return [lindex $availableNameList $index] 
					} else {
						error "ens::identifier::normName: can not norm identifier name string '$identifierName'"
					}
				}
			}
			return {}	
		}
				
		proc getPropName {identifierName} {
			set identifierName [normName $identifierName]
			set propName "E_[string toupper $identifierName]_ID"
			return $propName
		}
		
		proc getOrigName {identifierName} {
			set identifierName [normName $identifierName]
			set prefix [getglobalparam prefix]
			set propName "$prefix\_[string toupper $identifierName]_ID"
			return $propName
		}
		
		proc getStructurePropName {identifierName} {
			set identifierName [normName $identifierName]
			set propName "E_[string toupper $identifierName]_STRUCTURE"
			return $propName
		}

		proc getStructurePropOrigName {identifierName} {
			set identifierName [normName $identifierName]
			set prefix [getglobalparam prefix]
			set propName "$prefix\_[string toupper $identifierName]_STRUCTURE"
			return $propName
		}

		proc getPropTagString {identifierName} {
			set identifierName [normName $identifierName]
			set secondarytag [getglobalparam secondarytag]
			set propTagString "$identifierName-$secondarytag"
			return $propTagString
		}
		
		proc getPropCompFunctionName {identifierName} {
			set identifierName [normName $identifierName]
			set upperNameString [string toupper $identifierName]
			set propCompFunctionName "::ens::identifier::get$upperNameString"
			return $propCompFunctionName
		}

		proc getString {identifier string} {
			set returnString $string
			set propName [ens::identifier::getPropName [ens::identifier::normName $identifier]]
			set addtag [prop getparam $propName addtag]
			set addprimarytag [prop getparam $propName addprimarytag]
			set primarytag [prop getparam $propName primarytag]
			set addsecondarytag [prop getparam $propName addsecondarytag]
			set secondarytag [prop getparam $propName secondarytag]
			set tagseparator [prop getparam $propName tagseparator]
			if {$addtag} {
				if {$addprimarytag} {
					append returnString $tagseparator $primarytag
				}
				if {$addsecondarytag} {
					set sum 0
					loop i 0 [string length $returnString] {
						scan [string index $returnString $i] %c value
						incr sum $value
					}
					set checkSum [format %02x [expr $sum % 256]]
					set secondarytag 01-[string toupper $checkSum]
					append returnString $tagseparator $secondarytag
				}
			}
			return $returnString 
		}

		proc getStringFromSqlHex {identifier string} {
			return [getString $identifier [string toupper [format %016x 0x$string]]]
		}

		proc getStringFromSqlInt {identifier int} {
			return [getString $identifier [string toupper [format %016x $int]]]
		}
		
		proc create {{autopath {}}} {
			variable identifier
			set returnList {}
			foreach identifierName [getglobalparam names] {
				proparray::rdelete *
				set debug [getglobalparam debug]
				set debugtrace [getglobalparam debugtrace]
				set scope [getparam $identifierName scope]
				set csBaseHash [getparam $identifierName csBaseHash]
				set upperNameString [string toupper $identifierName]
				set addtag [getglobalparam addtag]
				set addprimarytag [getglobalparam addprimarytag]
				set primarytag $identifierName
				set addsecondarytag [getglobalparam addsecondarytag]
				set secondarytag [getglobalparam secondarytag]
				set tagString [getPropTagString $identifierName]
				set tagIdentifierSeparator [getglobalparam tagseparator]
				set propname [getPropName $identifierName]
				set datatype [getglobalparam datatype]
				set prefix [getglobalparam prefix]
				set origname [getOrigName $identifierName]
				set functiontype [getglobalparam functiontype]
				set timeout [getglobalparam timeout]
				set magic [getglobalparam magic]
				set forcemagic [getglobalparam forcemagic]
				set default [getglobalparam default]
				set compfunction [getPropCompFunctionName $identifierName]
				set test [getglobalparam test]
				set testorder [getparam $identifierName testOrder]
				set testparameters [getparam $identifierName testParameters]
				set posttest [getglobalparam posttest]
				set postnorm [getglobalparam postnorm]
				set postnormcmds [getparam $identifierName postNormCmds]
				set posttestcmds [getparam $identifierName postTestCmds]
				set norm [getglobalparam norm]
				set normorder [getparam $identifierName normOrder]
				set normparameters [getparam $identifierName normParameters]
				set normdefaultparameters [ens::norm::createDefaultParameterArray]
				set normargs [getparam $identifierName normParameterArgs]
  				
				#
				# fetch all parameters from the cactvs base hash code 
				#
				set csBaseHashParameters [prop get $csBaseHash parameters]
				set hashParameterList {}
				foreach {baseParamName baseParamValue} $csBaseHashParameters {
					if {[globalparamexists $baseParamName]} {
						lappend hashParameterList $baseParamName [getglobalparam $baseParamName]
					} else {
						lappend hashParameterList $baseParamName [list $baseParamValue]
					}
				}
				set structurepropname [getStructurePropName $identifierName]
				set structureproporigname [getStructurePropOrigName $identifierName]
 				
				foreach {arg val} $normargs {
					proparray::assign normargs $arg [proparray::sublist $val] 
				}
				set normargs [proparray::rget normargs]
				
				proparray::rassign parameters $hashParameterList
				proparray::rassign parameters [list \
					addtag $addtag \
					addprimarytag $addprimarytag \
					addsecondarytag $addsecondarytag \
					primarytag $primarytag \
					secondarytag $secondarytag \
					tagseparator $tagIdentifierSeparator \
					scope $scope \
					csbasehash $csBaseHash \
					forcemagic $forcemagic \
					structurepropname $structurepropname \
					debug $debug \
					test [list exec $test order [proparray::sublist $testorder] parameters $testparameters] \
					norm [list exec $norm order [proparray::sublist $normorder] parameters $normparameters args $normargs ] \
					post [list test [list exec $posttest parameters $testparameters cmds $posttestcmds switches [list forcemagic 0 unreliable 0 norm [list exec 0 parameters $normdefaultparameters]]] norm [list exec $postnorm parameters $normparameters cmds $postnormcmds]] \
				]
				set params [proparray::rget parameters]
				if 0 {catch {prop create $propname \
					origname $origname \
					functiontype $functiontype \
					compfunc $compfunction \
					timeout $timeout \
					magic $magic \
					default $default \
					parameters $params \
					defaultparameters $params}}
				if 0 {catch {prop create $structurepropname \
					origname $structureproporigname	\
					datatype ens}}
				# patch for CACTVS > 3.366
				#puts $scriptpath
				set prop_interp [prop get $propname interpreter]
				if {[string length $autopath]} {
					$prop_interp eval "lappend auto_path $autopath"
				} else {
					#set interpreter [prop get $structurepropname interpreter]
					#interp eval $interpreter "source $::env(PWD)/identifier.tcl"
				}
 				# patch end
				proparray::rdelete parameters
				lappend returnList $propname
			}
			return $returnList
		}

		if {[getglobalparam debug]} {
			if 0 {catch {
			prop create E_IDENTIFIER_HANDLE datatype string
			prop create E_IDENTIFIER_NORM_CMD datatype string
			prop create E_IDENTIFIER_NORM_ARG datatype string
			prop create E_IDENTIFIER_NORM_STATUS datatype string
			prop create E_IDENTIFIER_NORM_PARAMETER datatype string
			prop create E_IDENTIFIER_NORM_DATASET datatype dataset
			}}
		}
 	}


}

proc ens::filter::counterIonAtoms {ehandle} {
	set atomList {}
	foreach mol [ens mols $ehandle] {
		if {[mol atoms $ehandle $mol {} count] == 1} {
			switch [mol get $ehandle $mol A_IUPAC_GROUP] {
				1 -
				2 -
				17 {set atomList [concat $atomList [mol atoms $ehandle $mol]]}
			}
			if {[mol atoms $ehandle $mol metal bool]} {
				set atomList [concat $atomList [mol atoms $ehandle $mol]]
			}
		}
	}
	return [lsort -unique $atomList]
}

proc ens::resonance::countPiSystem {ehandle} {
	set pis_count [llength [::ens pis $ehandle]]
	set triplebonds_count [llength [::ens get $ehandle B_LABEL triplebond]]
	set rvalue [expr $pis_count - $triplebonds_count]
	return $rvalue
}

proc ens::resonance::rate {ehandle {hashcode E_HASHY} {comment 0}} {
	set orighandle $ehandle
	set ehandle [ens dup $ehandle]
	set chargedAtomLabelList [::ens atoms $ehandle {charged !metal !boron !hydrogen} count]
	ens taint $ehandle {atom bond}
	ens uncharge $ehandle
	ens need $ehandle R_TYPE
	ens need $ehandle A_ISAROMATIC
	set srating [expr \
		100 * [ens rings $ehandle {aroring sssrring} count] + \
		150 * [ens rings $ehandle {carbocycle aroring sssrring} count] + \
		[ens bonds $ehandle [list doublebond cxbond !arobond] count] + \
		2 * [ens bonds $ehandle [list doublebond N O] count] + \
		2 * [ens bonds $ehandle [list doublebond P O] count] + \
		-1 * [ens bonds $ehandle [list P H] count] + \
		-1 * [ens bonds $ehandle [list S H] count] + \
		-1 * [ens bonds $ehandle [list Se H] count] + \
		-1 * [ens bonds $ehandle [list Te H] count] + \
		4 * [match ss -mode all {C=N[OH]} $ehandle] + \
		-4 * [match ss -mode all {C=N(=O)[OH]} $ehandle] + \
		1 * [ens atoms $ehandle [list carbon h3] count] + \
		2 * [ens bonds $ehandle [list doublebond C O] count] + \
		10 * [match ss -mode all -charge 1 {[C](O[C])=[N+][C]} $ehandle] +\
		1 * [match ss -mode all {NC(=N)[N][!H]} $ehandle] +\
		1 * [match ss -mode all -charge 1 {[NH2]-C(=[NH2;+1])} $ehandle] +\
		2 * [match ss -mode all {[N;R][C;R]([N])=[N;R]} $ehandle] +\
		1 * [match ss -mode all {[N]=[N]=[N]} $ehandle] +\
		100 * [match ss -mode all -charge 1 {[O-][N+]([C])([C])[C]} $ehandle] +\
		100 * [match ss -mode all -charge 1 {[O-][N+]([C])=[C]} $ehandle] +\
		25 * [match ss -mode all {[C]1([C]=[C][C]([C]=[C]1)=,:[N,S,O])=,:[N,S,O]} $ehandle] +\
		-1 * [match ss -mode all {[S](=[C])([C])[C]} $ehandle] +\
		25 * [match ss -mode all -charge 1 {[P+]([C])([C])([C])[C]} $ehandle] +\
		25 * [match ss -mode all -charge 1 {[N;+1](-[O;-1])(=[N;+0])-[N;+0]} $ehandle]
	]
	set piSystemCount [countPiSystem $ehandle]
	set failedValences [ens valcheck $ehandle]
	set rating [expr $srating - $piSystemCount - ($failedValences * 250) - ($chargedAtomLabelList * 2)]
	if {$comment} {
		ens set $orighandle E_COMMENT $rating
	}
	ens delete $ehandle
	return $rating
}

proc ens::resonance::canonic {structures deleteStructures hashcode} {
	set ehandle [lindex $structures 0]
	set dup [ens dup $ehandle]
	ens uncharge $dup
	set bestrating [rate $ehandle $hashcode]
	set besth [ens get $dup $hashcode]
	ens delete $dup
	set idx 0
	set bestidx 0
	foreach ens $structures {
		set rating [rate $ens $hashcode]
		set dup [ens dup $ens]
		ens uncharge $dup
		set h [ens get $dup $hashcode]
		ens delete $dup
 		if {$rating > $bestrating || ($rating == $bestrating && [prop compare $hashcode $h $besth] > 0)} {
 			set bestrating $rating
			set besth $h
			set bestidx $idx
		}
 		incr idx
	}
	if {$bestidx > 0} {
		#ens delete $eh
		set canonicStructure [lvarpop structures $bestidx]
	} else {
		set canonicStructure [lvarpop structures 0]
	}
	if {$deleteStructures && $structures != ""} {
 		eval ens delete $structures
	}
	return $canonicStructure
}

proc ens::resonance::createSet {ehandle {maxens 1000} {timeout 0}} {

	set transform1 [list [list {[*;-1:1]-[*;+1:2]>>[*:1]=[*:2] uncharge1} 1 forward]]
	set transform2 [list [list {[*;-1:1]=[*;+1:2]>>[*:1]#[*:2] uncharge2} 1 forward]]
	set transform3 [list [list {[*;+1:1]=[C:2][*;-1:3]>>[*:1][C:2]=[*:3] uncharge3} 1 forward]]
	set transform4 [list [list {[*;-1:1]=[C:2][*;+1:3]>>[*:1][C:2]=[*:3] uncharge4} 1 forward]]
	set transform5 [list [list {[*;+1:1]#[*;+1:2][*;-2:3]>>[*:1]=[*;+1:2]=[*;-1:3] uncharge5} 1 forward]]
	set transform6 [list [list {[*;-1:1]#[*;-1:2][*;+2:3]>>[*:1]=[*;-1:2]=[*;+1:3] uncharge6} 1 forward]]

	set transform7 [list [list {[*;X3&v3&-1,X2&v2&-1,X1&v1&-1:1]-[*:2]=[*:3]>>[*:1]=[*:2]-[*;X3&v3&-1,X2&v2&-1,X1&v1&-1:3] Shift1}]]
 	set transform8 [list [list {[*;X3&v3&+1,X2&v2&+1,X1&v1&+1:1]-[*:2]=[*:3]>>[*:1]=[*:2]-[*;X3&v3&+1,X2&v2&+1,X1&v1&+1:3] Shift2}]]
 	set transform9 [list [list {[*;-1:1]=[*:2][X;X3&v3&+0,X2&v2&+0,X1&v1&+0:3]>>[*;X3&v3&+0,X2&v2&+0,X1&v1&+0:1][*:2]=[X;-1:3] Shift3}]]
	set transform10 [list [list {[*;+1:1]=[*:2]-[X;X3&v3&+0,X2&v2&+0,X1&v1&+0:3]>>[*;X3&v3&+0,X2&v2&+0,X1&v1&+0:1]-[*:2]=[X;+1:3] Shift4}]]
	set transform11 [list [list {[C;X2&v4&+0:1]#[X;+1:2]>>[C;X2&v3&+1:1]=[X;X2&v3&+0,X1&v2&+0:2] Shift5}]]
	set transform12 [list [list {[C;X3&v4&+0:1]=[X;X3&v4+1,X2&v3&+1,X1&v2&+1:2]>>[C;+1:1]-[X;X3&v3&+0,X2&v2&+0,X1&v1&+0:2] Shift6}]]
	set transform13 [list [list {[C;X3&v3&+1:1](-[X:3])(-[X:4])-[X;X3&v3&+0,X2&v2&+0,X1&v1&+0:2]>>[C;X3&v4&+0:1](-[X:3])(-[X:4])=[X;X2&v2&+1,X1&v1+1:2] Shift7}]]

	set transform14 [list [list {[N;X3&v5+0:1]=[*:2]>>[N;+1:1]-[*;-1:2] create1} 1 forward]]
	set transform15 [list [list {[X:1]#[X:2]>>[X;+1:1]=[X;-1:2] create2} 1 forward]]

	set transforms [concat $transform1 $transform2 $transform3 $transform4 $transform5 $transform6 $transform7 $transform8 $transform9 $transform10 $transform11 $transform12 $transform13 $transform14 $transform15]

	if {[catch {ens transform $ehandle $transforms bidirectional multistep all {nohadd nozwitterioncollapse filtercharges checkkekule filterkekule chargeneutral setname} none {} $maxens $timeout} structures]} {
		error "transform failure: $structures"
	}
	set structures [concat [ens dup $ehandle] $structures]
	return $structures
}

proc ens::resonance::crossPseudoStereoBonds {structures} {
	set status 0
	array unset bStereoCount
	set structureCount [llength $structures]
	set ehandle [lindex $structures 0]
	if {$ehandle == ""} {return $status}
	foreach bond [ens bonds $ehandle !hbond] {
		set bStereoCount($bond) 0
	}
	# counting stereo bonds in each structure
	foreach structure $structures {
		foreach bond [ens bonds $structure bstereogenic] {
			incr bStereoCount($bond)
		}
	}
	# make statistic which stereo bond occurs in each structure and remains unchanged:
	# these might be a real stereo bonds, all other are no stereo bonds and are getting crossed
	foreach structure $structures {
		foreach bond [ens bonds $structure bstereogenic] {
			if {$bStereoCount($bond) != $structureCount} {
				if {![lcontain [bond get $structure $bond B_FLAGS] crossed]} {
					set status 1
				}
				bond create $structure $bond crossed
				bond set $structure $bond B_NCICADD_RESONANCE_CROSSED 1
			}
		}
	}
	return $status
}

proc ens::resonance::deletePseudoStereoAtoms {structures} {
	set status 0
	array unset possStereoCount
	set structureCount [llength $structures]
	set ehandle [lindex $structures 0]
	if {$ehandle == ""} {return $status}
	foreach atom [ens atoms $ehandle] {
		set possStereoCount($atom) 0
	}
	# counting stereo
	foreach structure $structures {
		foreach atom [ens atoms $structure astereogenic] {
			incr possStereoCount($atom)
		}
	}
	foreach structure $structures {
		foreach atom [ens atoms $structure astereogenic] {
			if {$possStereoCount($atom) != $structureCount} {
				if {[atom nget $structure $atom A_LABEL_STEREO]!=0} {
					set status 1
					atom set $structure $atom A_NCICADD_TAUTO_STEREO_DELETED 1
				}
				foreach bond [atom bonds $structure $atom] {
					if {[lcontain [bond get $structure $bond B_FLAGS] lowwedgetip] ||
						[lcontain [bond get $structure $bond B_FLAGS] highwedgetip]} {
						set status 1
						atom set $structure $atom A_NCICADD_RESONANCE_STEREO_DELETED 1
						#bond set $structure $bond B_COLOR red
						#atom set $structure $atom A_FLAGS boxed
					}
					if {!$leaveUntouched} {
						bond set $structure $bond B_FLAGS none
					}
				}
				if {!$leaveUntouched} {
					atom set $structure $atom A_LABEL_STEREO undef
					atom set $structure $atom A_CIP_STEREO undef
				}
				if {$reportAny} {
					# reports also critical atoms without explicit stereochemistry
					atom set $structure $atom A_NCICADD_RESONANCE_STEREO_DELETED 1
					#atom set $structure $atom A_COLOR red
					set status 1
				}
			}
		}
	}
	return $status
}

proc ens::resonance::chargeIsExclusivelyOnNitroGroups {ehandle chargedAtomLabelList} {
	set nitroGroup [ens create {[C][N;+1](=[O])-[O;-1]} smarts]
	set nitroCount [match ss -charge 1 -mode distinct $nitroGroup $ehandle matchList]
	ens delete $nitroGroup
	if {!$nitroCount} {return 0}
	set nitroChargeList {}
	foreach match $matchList {
		lassign $match cmatch nmatch o1match o2match
		lappend nitroChargeList [lindex $nmatch 1]
		lappend nitroChargeList [lindex $o2match 1]
	}
	set failedValenceList {}
	foreach atom [ens atoms $ehandle [atom::filterlist::get checkForChargeAtomList]] {
		set dup [ens dup $ehandle]
		ens hadd $dup
		if {![atom valcheck $dup $atom]} {
			lappend chargedAtomLabelList $atom
		}
		ens delete $dup
	}
	set nitroChargeList [lsort -integer -unique $nitroChargeList]
	set chargedAtomLabelList [lsort -integer -unique $chargedAtomLabelList]
	if {$nitroChargeList == $chargedAtomLabelList} {
		return 1
	}
	return 0
}

proc ens::tautomer::rate {ehandle {explain 0} {hashcode E_HASHY} {comment 0}} {
	ens taint $ehandle {atom bond}
	ens need $ehandle R_TYPE 
	ens need $ehandle A_ISAROMATIC
	set rating [expr [ens rings $ehandle {aroring sssrring} count]*100 + \
		[ens rings $ehandle {carbocycle aroring sssrring} count]*150 + \
		[ens bonds $ehandle [list doublebond cxbond !arobond] count] + \
		2*[ens bonds $ehandle [list doublebond N O] count] + \
		2*[ens bonds $ehandle [list doublebond P O] count] - \
		[ens bonds $ehandle [list P H] count] - \
		[ens bonds $ehandle [list S H] count] - \
		[ens bonds $ehandle [list Se H] count] - \
		[ens bonds $ehandle [list Te H] count] + \
		4* [match ss -mode all {C=N[OH]} $ehandle] + \
		-4* [match ss -mode all {C=N(=O)[OH]} $ehandle] + \
		1 * [ens atoms $ehandle [list carbon h3] count] + \
		2 * [ens bonds $ehandle [list doublebond C O] count] +\
		1 * [match ss -mode all {NC(=N)[N][!H]} $ehandle] +\
		1 * [match ss -mode all -charge 1 {[NH2]-C(=[NH2;+1])} $ehandle] +\
		100 * [match ss -mode all -charge 1 {[O-][N+]([C])([C])[C]} $ehandle] +\
		100 * [match ss -mode all -charge 1 {[O-][N+]([C])=[C]} $ehandle] +\
		25 * [match ss -mode all {[C]1([C]=[C][C]([C]=[C]1)=,:[N,S,O])=,:[N,S,O]} $ehandle] \
	]
	if {$explain} {
		puts "arorings [ens rings $ehandle {aroring sssrring} count]"
		puts "C-arorings [ens rings $ehandle {carbocycle aroring sssrring} count]"
		puts "C=X bonds [ens bonds $ehandle [list doublebond cxbond !arobond] count]"
		puts "N=O bonds [ens bonds $ehandle [list doublebond N O] count]"
		puts "P-H bonds [ens bonds $ehandle [list P H] count]"
		puts "S-H bonds [ens bonds $ehandle [list S H] count]"
		puts "Se-H bonds [ens bonds $ehandle [list Se H] count]"
		puts "Te-H bonds [ens bonds $ehandle [list Te H] count]"
		puts "Oximes [match ss -mode all {C=N[OH]} $ehandle]"
		puts "minus Aci-Nitrogroup [match ss -mode all {C=N(=O)[OH]} $ehandle]"
		puts "CH3 groups [ens atoms $ehandle [list carbon h3] count]"
		puts "C=O groups [ens bonds $ehandle [list doublebond C O] count]"
	}
	if {$comment} {
		ens set $ehandle E_COMMENT $rating
	}
	return $rating
}

proc ens::tautomer::createSet {ehandle {maxens 1000} {timeout 0} {setcount 0} {usekekuleset 0} {addh 0} {restricted 0} {preservecoordinates 0} {maxtransforms 1000}} {
	if {$addh} {
		ens hadd $ehandle
	}
	set tlist {}
	switch $restricted {
		restricted { 
			set restricted 1
		}
		full {
			set restricted 0
		}
	}
	if {1} {
		if {$restricted} {
			# simple enol/thioenol transform
			lappend tlist {{[O,S,Se,Te;X1:1]=[Cz1:2][CX4R{0-2}:3]([#1:4])[a,i:5]>>[#1:4][O,S,Se,Te;X2:1][Cz1:2]=[CX3:3][a,i:5] restricted 1.3 enol/thioenol}}
			lappend tlist {{[N,n,S,s,O,o,Se,Te:1]=[NX2,nX2,C,c,P,p:2]([N,n,S,O,Se,Te:3][#1:4])[i,a:5]>>[#1:4][N,n,S,O,Se,Te:1][NX2,nX2,C,c,P,p:2](=[N,n,S,s,O,o,Se,Te:3])[i,a:5] 1.3 restricted hetero atom hydrogen shift} 1 bidirectional {checkaro checkkekule preservecharges setname}}
			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[c,nX2:6][C,c:5]=[C,c,nX2:2][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,nX2:6]=[C,c:5][C,c,nX2:2]=[NX2,S,O,Se,Te:3] 1.5 aro heteroatom H shift}}
#			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[nX2,NX2,S,O,Se,Te,Cz0X3:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te,Cz0X4:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[#1:4][N,n:1][C,c,n;e6:2]=[O,NX2,nX2:3]>>[NX2,nX2:1]=[C,c,n;e6:2][O,NX3,nX3:3][#1:4] Restricted 1.3 aro heteroatom H shift}}
			lappend tlist {{[#1:6][N,n:1][C,c,n;e6:2]=[C,c,n;e6:3][C,c,n;e6:4]=[O,NX2,nX2:5]>>[NX2,nX2:1]=[C,c,n;e6:2][C,c,n;e6:3]=[C,c,n;e6:4][O,NX3,nX3:5][#1:6] restricted 1.5 aro heteroatom H shift}}
		} else {
			lappend tlist {{[O,S,Se,Te;X1:1]=[C;z{1-2}:2][CX4R{0-2}:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][#6;z{1-2}:2]=[C,cz{0-1}R{0-1}:3] 1.3 enol/thioenol}}
			# long-range enol transform
			lappend tlist {{[O,S,Se,Te;X1:1]=[Cz1H0:2][C:5]=[C:6][CX4z0,NX3:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][Cz1:2]=[C:5][C:6]=[Cz0,N:3] 1.5 enol}}
			# simple imine transform
			lappend tlist {{[#1,a:5][NX2:1]=[Cz1:2][CX4R{0-2}:3][#1:4]>>[#1,a:5][NX3:1]([#1:4])[Cz1,Cz2:2]=[C:3] simple imine}}
			lappend tlist {{[Cz0R0X3:1]([C:5])=[C:2][Nz0:3][#1:4]>>[#1:4][Cz0R0X4:1]([C:5])[c:2]=[nz0:3] special imine}}
			# aro heteroatom shift
			lappend tlist {{[#1:4][N:1][C;e6:2]=[O,NX2:3]>>[NX2,nX2:1]=[C,c;e6:2][O,N:3][#1:4] 1.3 aro heteroatom H shift}}
			# hetero atom hydrogen exchange
			lappend tlist {{[N,n,S,s,O,o,Se,Te:1]=[NX2,nX2,C,c,P,p:2][N,n,S,O,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][NX2,nX2,C,c,P,p:2]=[N,n,S,s,O,o,Se,Te:3] 1.3 hetero atom hydrogen shift}}
			# long-range hetero atom hydrogen exchange
			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[C,c,nX2,NX2:6][C,c:5]=[C,c,nX2:2][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,nX2,NX2:6]=[C,c:5][C,c,nX2:2]=[NX2,S,O,Se,Te:3] 1.5 aro heteroatom H shift (1)}}
			lappend tlist {{[n,s,o:1]=[c,n:6][c:5]=[c,n:2][n,s,o:3][#1:4]>>[#1:4][n,s,o:1][c,n:6]=[c:5][c,n:2]=[n,s,o:3] 1.5 aro heteroatom H shift (2)}}
			# changed!
			lappend tlist {{[nX2,NX2,S,O,Se,Te,Cz0X3:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te,Cz0X4:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
#			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[#1:1][n,N,O:2][c,nX2,C:3]=[c,nX2,C:4][c,nX2:5]=[c,nX2:6][c,nX2:7]=[c,nX2:8][c,nX2,C:9]=[n,N,O:10]>>[N,n,O:2]=[C,c,nX2:3][c,nX2:4]=[c,nX2:5][c,nX2:6]=[c,nX2:7][c,nX2:8]=[c,nX2:9][n,O:10][#1:1] 1.9 aro heteroatom H shift}}
			lappend tlist {{[#1:1][n,N,O:2][c,nX2,C:3]=[c,nX2,C:4][c,nX2:5]=[c,C,nX2:6][c,C,nX2:7]=[c,C,nX2:8][c,nX2,C:9]=[c,C,nX2:10][c,C,nX2:11]=[nX2,NX2,O:12]>>[NX2,nX2,O:2]=[C,c,nX2:3][c,C,nX2:4]=[c,C,nX2:5][c,C,nX2:6]=[c,C,nX2:7][c,C,nX2:8]=[c,C,nX2:9][c,C,nX2:10]=[c,C,nX2:11][nX2,O:12][#1:1] 1.11 aro heteroatom H shift}}
	
			# keten/inol exchange
			lappend tlist {{[O,S,Se,Te;X1:1]=[C:2]=[C:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][C:2]#[C:3] keten-inol exchange}}
			# nitro/aci with ionic nitro group
			lappend tlist {{[#1:1][C:2][N+:3]([O-:5])=[O:4]>>[C:2]=[N+:3]([O-:5])[O:4][#1:1] nitro/aci ionic} 1 bidirectional {checkcharges setname}}
			# nitro/aci with pentavalent nitro group
			lappend tlist {{[#1:1][C:2][N:3](=[O:5])=[O:4]>>[C:2]=[N:3](=[O:5])[O:4][#1:1] nitro/aci pentavalent}}
			# nitroso/oxim
			lappend tlist {{[#1:1][O:2][Nz1:3]=[C:4]>>[O:2]=[Nz1:3][C:4][#1:1] nitroso/oxim}}
			# nitroso/oxim through aro ring to phenol
			lappend tlist {{[#1:1][O:2][N:3]=[C:4][C:5]=[C:6][C:7]=[O:8]>>[O:2]=[N:3][c:4]=[c:5][c:6]=[c:7][O:8][#1:1] nitroso/oxim via phenol}}
			# cyanuric acid and various other special cases
			lappend tlist {{[#1:1][O:2][C:3]#[N:4]>>[O:2]=[C:3]=[N:4][#1:1] cynanuric acid}}
			lappend tlist {{[#1:1][O,N:2][C:3]=[S,Se,Te:4]=[O:5]>>[O,N:2]=[C:3][S,Se,Te:4][O:5][#1:1] formamidinesulfonic acid}}
			lappend tlist {{[#1:1][C0:2]#[N0:3]>>[C-:2]#[N+:3][#1:1] isocyanide} 1 bidirectional {checkcharges checkaro setname}}
			lappend tlist {{[#1:1][O:2][P:3]>>[O:2]=[P:3][#1:1] phosphonic acid}}
			lappend tlist {{[#1:1][O,S,N:2][c,C;z2;r5:3]=[C,c;r5:4][c,C;r5:5]>>[O,S,N:2]=[Cz2r5:3][C&r5R{0-2}:4]([#1:1])[C,c;r5:5] furanones}}
		}
	} else {
		if {$restricted} {
			# simple enol/thioenol transform
			lappend tlist {{[O,S,Se,Te;X1:1]=[C;x{1-2}:2][CX4R{0-2}:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][#6;x{1-2}:2]=[C,cx{0-1}R{0-1}:3] 1.3 enol/thioenol}}
			lappend tlist {{[N,n,S,s,O,o,Se,Te:1]=[NX2,nX2,C,c,P,p:2]([N,n,S,O,Se,Te:3][#1:4])[i,a:5]>>[#1:4][N,n,S,O,Se,Te:1][NX2,nX2,C,c,P,p:2](=[N,n,S,s,O,o,Se,Te:3])[i,a:5] 1.3 Restricted hetero atom hydrogen shift} 1 bidirectional {checkaro checkkekule preservecharges setname}}
			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[c,nX2:6][C,c:5]=[C,c,nX2:2][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,nX2:6]=[C,c:5][C,c,nX2:2]=[NX2,S,O,Se,Te:3] 1.5 aro heteroatom H shift}}
#			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[nX2,NX2,S,O,Se,Te,Cx0X3:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te,Cx0X4:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[#1:4][N,n:1][C,c,n;e6:2]=[O,NX2,nX2:3]>>[NX2,nX2:1]=[C,c,n;e6:2][O,NX3,nX3:3][#1:4] Restricted 1.3 Aro heteroatom H shift}}
			lappend tlist {{[#1:6][N,n:1][C,c,n;e6:2]=[C,c,n;e6:3][C,c,n;e6:4]=[O,NX2,nX2:5]>>[NX2,nX2:1]=[C,c,n;e6:2][C,c,n;e6:3]=[C,c,n;e6:4][O,NX3,nX3:5][#1:6] Restricted 1.5 Aro heteroatom H shift}}
		} else {
			lappend tlist {{[O,S,Se,Te;X1:1]=[C;z{1-2}:2][CX4R{0-2}:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][#6;z{1-2}:2]=[C,cz{0-1}R{0-1}:3] 1.3 enol/thioenol}}
			# long-range enol transform
			lappend tlist {{[O,S,Se,Te;X1:1]=[Cx1H0:2][C:5]=[C:6][CX4x0,NX3:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][Cx1:2]=[C:5][C:6]=[Cx0,N:3] 1.5 enol}}
			# simple imine transform
			lappend tlist {{[#1,a:5][NX2:1]=[Cx1:2][CX4R{0-2}:3][#1:4]>>[#1,a:5][NX3:1]([#1:4])[Cx1,Cx2:2]=[C:3] Simple imine}}
			lappend tlist {{[Cx0R0X3:1]([C:5])=[C:2][Nx0:3][#1:4]>>[#1:4][Cx0R0X4:1]([C:5])[c:2]=[nx0:3] Special imine}}
			# aro heteroatom shift
			lappend tlist {{[#1:4][N:1][C;e6:2]=[O,NX2:3]>>[NX2,nX2:1]=[C,c;e6:2][O,N:3][#1:4] 1.3 Aro heteroatom H shift}}
			# hetero atom hydrogen exchange
			lappend tlist {{[N,n,S,s,O,o,Se,Te:1]=[NX2,nX2,C,c,P,p:2][N,n,S,O,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][NX2,nX2,C,c,P,p:2]=[N,n,S,s,O,o,Se,Te:3] 1.3 Hetero atom hydrogen shift}}
			# long-range hetero atom hydrogen exchange
			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[C,c,nX2,NX2:6][C,c:5]=[C,c,nX2:2][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,nX2,NX2:6]=[C,c:5][C,c,nX2:2]=[NX2,S,O,Se,Te:3] 1.5 aro heteroatom H shift (1)}}
			lappend tlist {{[n,s,o:1]=[c,n:6][c:5]=[c,n:2][n,s,o:3][#1:4]>>[#1:4][n,s,o:1][c,n:6]=[c:5][c,n:2]=[n,s,o:3] 1.5 aro heteroatom H shift (2)}}
#			lappend tlist {{[nX2,NX2,S,O,Se,Te:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[nX2,NX2,S,O,Se,Te,Cx0X3:1]=[c,C,NX2,nX2:6][C,c:5]=[C,c,NX2,nX2:2][C,c,NX2,nX2:7]=[C,c,NX2,nX2:8][N,n,S,s,O,o,Se,Te:3][#1:4]>>[#1:4][N,n,S,O,Se,Te,Cx0X4:1][C,c,NX2,nX2:6]=[C,c:5][C,c,NX2,nX2:2]=[C,c,NX2,nX2:7][C,c,NX2,nX2:8]=[NX2,S,O,Se,Te:3] 1.7 aro heteroatom H shift}}
			lappend tlist {{[#1:1][n,N,O:2][c,nX2,C:3]=[c,nX2,C:4][c,nX2:5]=[c,nX2:6][c,nX2:7]=[c,nX2:8][c,nX2,C:9]=[n,N,O:10]>>[N,n,O:2]=[C,c,nX2:3][c,nX2:4]=[c,nX2:5][c,nX2:6]=[c,nX2:7][c,nX2:8]=[c,nX2:9][n,O:10][#1:1] 1.9 aro heteroatom H shift}}
			lappend tlist {{[#1:1][n,N,O:2][c,nX2,C:3]=[c,nX2,C:4][c,nX2:5]=[c,C,nX2:6][c,C,nX2:7]=[c,C,nX2:8][c,nX2,C:9]=[c,C,nX2:10][c,C,nX2:11]=[nX2,NX2,O:12]>>[NX2,nX2,O:2]=[C,c,nX2:3][c,C,nX2:4]=[c,C,nX2:5][c,C,nX2:6]=[c,C,nX2:7][c,C,nX2:8]=[c,C,nX2:9][c,C,nX2:10]=[c,C,nX2:11][nX2,O:12][#1:1] 1.11 aro heteroatom H shift}}
	
			# keten/inol exchange
			lappend tlist {{[O,S,Se,Te;X1:1]=[C:2]=[C:3][#1:4]>>[#1:4][O,S,Se,Te;X2:1][C:2]#[C:3] keten-inol exchange}}
			# nitro/aci with ionic nitro group
			lappend tlist {{[#1:1][C:2][N+:3]([O-:5])=[O:4]>>[C:2]=[N+:3]([O-:5])[O:4][#1:1] nitro/aci ionic} 1 bidirectional {checkcharges setname}}
			# nitro/aci with pentavalent nitro group
			lappend tlist {{[#1:1][C:2][N:3](=[O:5])=[O:4]>>[C:2]=[N:3](=[O:5])[O:4][#1:1] nitro/aci pentavalent}}
			# nitroso/oxim
			lappend tlist {{[#1:1][O:2][Nx1:3]=[C:4]>>[O:2]=[Nx1:3][C:4][#1:1] nitroso/oxim}}
			# nitroso/oxim through aro ring to phenol
			lappend tlist {{[#1:1][O:2][N:3]=[C:4][C:5]=[C:6][C:7]=[O:8]>>[O:2]=[N:3][c:4]=[c:5][c:6]=[c:7][O:8][#1:1] nitroso/oxim via phenol}}
			# cyanuric acid and various other special cases
			lappend tlist {{[#1:1][O:2][C:3]#[N:4]>>[O:2]=[C:3]=[N:4][#1:1] cynanuric acid}}
			lappend tlist {{[#1:1][O,N:2][C:3]=[S,Se,Te:4]=[O:5]>>[O,N:2]=[C:3][S,Se,Te:4][O:5][#1:1] formamidinesulfonic acid}}
			lappend tlist {{[#1:1][C0:2]#[N0:3]>>[C-:2]#[N+:3][#1:1] isocyanide} 1 bidirectional {checkcharges checkaro setname}}
			lappend tlist {{[#1:1][O:2][P:3]>>[O:2]=[P:3][#1:1] phosphonic acid}}
			lappend tlist {{[#1:1][O,S,N:2][c,C;x2;r5:3]=[C,c;r5:4][c,C;r5:5]>>[O,S,N:2]=[Cx2r5:3][C&r5R{0-2}:4]([#1:1])[C,c;r5:5] furanones}}
		}
	}
	# to trace the applied transforms: add 'setname' flag
	set trafoflags {preservecharges checkaro setname} 
	if {$preservecoordinates} {
		lappend trafoflags preservecoordinates
	}
	if {$usekekuleset} {
		set kset [ens get $ehandle E_KEKULESET]
		if {[catch {dataset transform $kset $tlist bidirectional multistep all $trafoflags none {} $maxens $timeout $maxtransforms} tautomers]} {
			error "transform failure: $tautomers"
		}
	} else {
		if {[catch {ens transform $ehandle $tlist bidirectional multistep all $trafoflags none {} $maxens $timeout $maxtransforms} tautomers]} {
			error "transform failure: $tautomers"
		}
	}
 	if {$setcount} {
		ens set $ehandle E_TAUTOMER_COUNT [expr [llength $tautomers] + 1]
	}
	set tautomers [concat [ens dup $ehandle] $tautomers]
	return $tautomers
}

proc ens::tautomer::canonic {tautomers deleteTautomers hashcode} {
	set ehandle [lindex $tautomers 0]
	set bestrating [rate $ehandle 0 $hashcode]
	set besth [ens get $ehandle $hashcode]
	set idx 0
	set bestidx 0
	foreach ens $tautomers {
		set rating [rate $ens 0 $hashcode]
		set h [ens get $ens $hashcode]
		if {$rating > $bestrating || ($rating == $bestrating && [prop compare $hashcode $h $besth] > 0)} {
			set bestrating $rating
			set besth $h
			set bestidx $idx
		}
		incr idx
	}
	if {$bestidx > 0} {
		#ens delete $eh
		set canonicEns [lvarpop tautomers $bestidx]
	} else {
		set canonicEns [lvarpop tautomers 0]
	}
	if {$deleteTautomers && $tautomers != ""} {
 		eval ens delete $tautomers
	}
	return $canonicEns
} 

proc ens::tautomer::deletePseudoStereoAtoms {structures {reportAny 0} {leaveUntouched 0}} {
	set status 0
	array unset possStereoCount
	set structureCount [llength $structures]
	set ehandle [lindex $structures 0]
	if {$ehandle == ""} {return $status}
	foreach atom [ens atoms $ehandle] {
		set possStereoCount($atom) 0
	}
	# counting stereo
	foreach structure $structures {
		foreach atom [ens atoms $structure astereogenic] {
			incr possStereoCount($atom)
		}
	}
	foreach structure $structures {
		foreach atom [ens atoms $structure astereogenic] {
			if {$possStereoCount($atom) != $structureCount} {
				if {[atom nget $structure $atom A_LABEL_STEREO]!=0} {
					set status 1
					atom set $structure $atom A_NCICADD_TAUTO_STEREO_DELETED 1
				}
				foreach bond [atom bonds $structure $atom] {
					if {[lcontain [bond get $structure $bond B_FLAGS] lowwedgetip] ||
						[lcontain [bond get $structure $bond B_FLAGS] highwedgetip]} {
						set status 1
						atom set $structure $atom A_NCICADD_TAUTO_STEREO_DELETED 1
						bond set $structure $bond B_COLOR red
						atom set $structure $atom A_FLAGS boxed
					}
					if {!$leaveUntouched} {
						bond set $structure $bond B_FLAGS none
					}
				}
				if {!$leaveUntouched} {
					atom set $structure $atom A_LABEL_STEREO undef
					atom set $structure $atom A_CIP_STEREO undef
				}
				if {$reportAny} {
					# reports also critical atoms without explicit stereochemistry
					atom set $structure $atom A_NCICADD_TAUTO_STEREO_DELETED 1
					#atom set $structure $atom A_COLOR red
					set status 1
				}
			}
		}
	}
	return $status
}

proc ens::tautomer::crossPseudoStereoBonds {tautomers {reportAny 0} {leaveUntouched 0}} {
	set status 0
	array unset bStereoCount
	set tautoCount [llength $tautomers]
	set ehandle [lindex $tautomers 0]
	if {$ehandle == ""} {return $status}
	foreach bond [ens bonds $ehandle !hbond] {
		set bStereoCount($bond) 0
	}
	# counting stereo bonds in each tautomer
	foreach tautomer $tautomers {
		#ens need $tautomer B_STEREOGENIC
		foreach bond [ens bonds $tautomer bstereogenic] {
			incr bStereoCount($bond)
		}
	}
	# make statistic which stereo bond occurs in each tautomer and remains unchanged:
	# these might be a real stereo bonds, all other are no stereo bonds and are getting crossed
	foreach tautomer $tautomers {
		foreach bond [ens bonds $tautomer bstereogenic] {
			if {$bStereoCount($bond) != $tautoCount} {
				if {![bond get $tautomer $bond B_FLAGS(crossed)]} {
					bond set $tautomer $bond B_NCICADD_TAUTO_CROSSED 1
					bond set $tautomer $bond B_COLOR red
					set status 1
				}
				if {!$leaveUntouched} {
					bond create $tautomer $bond crossed
				}
				if {$reportAny} {
					# reports also critical bonds without explicit stereochemistry
					bond set $tautomer $bond B_NCICADD_TAUTO_CROSSED 1
					bond set $tautomer $bond B_COLOR red
					set status 1
				}
			}
		}
	}
	return $status
}

proc atom::test::organoMetallic {ehandle atom} {
	if {![atom filter $ehandle $atom metal]} {
		return 0
	}
	if {![atom neighbors $ehandle $atom carbon bool]} {
		return 0
	}
	if {[atom::test::complexCenter $ehandle $atom]} {
		return 0
	}
	return 1
}

proc atom::test::complexCenter {ehandle atom} {
	if {![atom filter $ehandle $atom metal]} {
		return 0
	} else {
		set dup [ens dup $ehandle]
		ens hadd $dup {} {nometals nohighvalence}
		set metal $atom
		set metalAtomSymbol [atom get $dup $metal A_SYMBOL]
		set maxValence [atom::element::get $metalAtomSymbol maxValence]
		set bordersum 0
		foreach neighborAtom [atom neighbors $ehandle $metal !metal] {
			set bond [bond get $ehandle [list $metal $neighborAtom] B_LABEL]
			incr bordersum [bond get $dup $bond B_ORDER]
			if {[bond filter $dup $bond complexbond]} {
				incr bordersum 1
			}
		}
		if {$bordersum > $maxValence} {
			# metal center exceeds max valence by bond order sum
			ens delete $dup
			return 1
		} else {
			# metal ligand exceeds maxValence or is member of a pi system:
			foreach metalLigand [atom neighbors $dup $metal !metal] {
				set atomSymbol [atom get $dup $metalLigand A_SYMBOL]
				set ligandMaxValence [atom::element::get $atomSymbol maxValence]
				set ligandNeigbors [atom neighbors $dup $metalLigand !metal count]
				if {$ligandNeigbors > $ligandMaxValence} {
					ens delete $dup
					return 1
				}
				foreach piSystem [atom pis $dup $metalLigand] {
					set ddup [ens dup $dup]
					foreach deleteMetalLabel [ens atoms $ddup metal] {
						atom delete $ddup $deleteMetalLabel
					}
					if {[pi exists $ddup $piSystem] && [pi atoms $ddup $piSystem {} bool]} {
						foreach piAtom [pi atoms $ddup $piSystem] {
							if {$piAtom == $metalLigand} {continue}
							if {[bond exists $ehandle [list $metal $piAtom]]} {
								ens delete $ddup
								ens delete $dup
								return 1
							}
						}
					}
					ens delete $ddup
				}
			}
		}
		ens delete $dup
	}
	return 0
}

proc ens::test::noAtoms {ehandle} {
 	set atomFilterList [atom::filterlist::get regularAtomTypes]		
	return [expr ![ens atoms $ehandle $atomFilterList bool]]
}

proc ens::test::singleAtom {ehandle} {
 	set atomFilterList [atom::filterlist::get regularAtomTypes]		
	set atomCount [ens atoms $ehandle $atomFilterList count]
	if {$atomCount == 1} {return 1}
	return 0
}

proc ens::test::empty {ehandle} {
 	if {![ens atoms $ehandle {} bool]} {
		set empty [ens create]
		set emptyPackString [ens pack $empty]
		ens delete $empty
		if {[ens pack $ehandle] == $emptyPackString} {
			return 1
		}
	}
	return 0
}

proc ens::test::pseudoOrganic {ehandle} {
	if {[organic $ehandle]} {
		return 0
	}	
	set rsum 0
	foreach element [ens get $ehandle A_SYMBOL] {
		if {[catch {atom::element::get $element organicRelevance} relevance]} {
			set relevance 0
		}
		incr rsum $relevance
	}
	set ccbondCount [expr 20 * [ens bonds $ehandle ccbond count]]
	set cxbondCount [expr 10 * [ens bonds $ehandle cxbond count]]
	set chbondCount [expr 10 * [ens bonds $ehandle chbond count]]
	set xhbondCount [ens bonds $ehandle xhbond count]
	set xxbondCount [ens bonds $ehandle xxbond count]
	set atomCount [ens atoms $ehandle {} count]
	if {$atomCount == 1} {
		set n [expr ($rsum * 10)]
 	} else {
		set n [expr ($rsum * [max $chbondCount 1] * [max $ccbondCount 1] * [max $cxbondCount 1] * [max $xhbondCount 1])]
	}
	set t [expr (10.0 * $atomCount * [max $xxbondCount 1])]
	set rating [expr $n / [max $t 1]]
 	if {$rating >= 1} {return 1}
	return 0
}

proc ens::test::organic {ehandle} {
	set dup [ens dup $ehandle]
	ens hadd $dup {} nometals
	set isOrganic [expr [::ens bonds $dup chbond bool] \
		|| [::ens bonds $dup {cxbond doublebond} bool] \
		|| [ens atoms $dup {1 oxygen nitrogen sulphur phosphorus hydrogen} count] == [ens atoms $dup {} count] \
	]
	#puts "OO $isOrganic [ens atoms $dup {1 oxygen nitrogen sulphur phosphorus hydrogen} count] == [ens atoms $dup {} count]"
	ens delete $dup
	
	return $isOrganic
}

proc ens::test::inorganic {ehandle} {
	return [expr ![organic $ehandle] && ![pseudoOrganic $ehandle]]
}

proc ens::test::specialAtomTypes {ehandle} {
 	return [ens atoms $ehandle [atom::filterlist::get specialAtomTypes] bool]
}

proc ens::test::isotopes {ehandle} {
	return [ens atoms $ehandle isotopeatom bool]
}

proc ens::test::metalAtoms {ehandle} {
	return [ens atoms $ehandle metal bool]
}

proc ens::test::singleMetalAtoms {ehandle} {
	if {![ens atoms $ehandle {} bool]} {return 0}
	if {[ens bonds $ehandle {} bool]} {return 0}
	if {[ens atoms $ehandle {} count] == [ens atoms $ehandle metal count]} {
		return 1
	}
	return 0
}

proc ens::test::singleHydrogenAtoms {ehandle} {
	if {![ens atoms $ehandle {} bool]} {return 0}
	if {[ens bonds $ehandle {} bool]} {return 0}
	if {[ens atoms $ehandle {} count] == [ens atoms $ehandle hydrogen count]} {
		return 1
	}
	return 0
}

proc ens::test::sizeLimit {ehandle} {
 	set maxAtoms [ens::parameter::get maxAtoms]
	set ncount [ens atoms $ehandle [atom::filterlist::get regularAtomTypes] count]
	if {($ncount > $maxAtoms)} {
		return 1
	}
	return 0
}

proc ens::test::clusterCompound {ehandle} {
	# check for chemical cluster compounds
	# calcuates the ratio of max atom valences to atm neighbor number
	set acount [ens atoms $ehandle [list !hydrogen [atom::filterlist::get regularAtomTypes]] count]
	set rsum 0
	foreach atom [ens atoms $ehandle [list !hydrogen [atom::filterlist::get regularAtomTypes]]] {
		set symbol [atom get $ehandle $atom A_SYMBOL]
		set maxValence [atom::element::get $symbol maxValence]
		set bsum 0
		foreach bond [atom bonds $ehandle $atom !hbond] {
			set bsum [expr $bsum + [bond get $ehandle $bond B_ORDER]]
		}
		# the minimum of bsum and maxValence is needed for metal complexes
		set valenceRatio [expr double([min $bsum $maxValence]) / [max $maxValence 1]]
		set ringNumber [atom rings $ehandle $atom {} count]
		set ringRatio [expr double($ringNumber) / [max $maxValence 1]]
		set rsum [expr $rsum + $valenceRatio + $ringRatio]
	}
	set averageRatio [expr $rsum / [max $acount 1]]
	if {$averageRatio >= 1.75} {
		return 1
	}
	return 0
}

proc ens::test::aux::stereoAtomCount {ehandle} {
	ens new $ehandle {A_STEREOGENIC A_STEREOINFO}
	set possStereoCenterCount [ens atoms $ehandle astereogenic count]
	set definedStereoCenterCount [ens atoms $ehandle stereoatom count]
	return [list $possStereoCenterCount $definedStereoCenterCount]
}

proc ens::test::aux::stereoBondCount {ehandle} {
	ens new $ehandle {B_STEREOGENIC B_STEREOINFO}
	set possStereoCenterCount [ens bonds $ehandle bstereogenic count]
	set definedStereoCenterCount [ens bonds $ehandle stereobond count]
	return [list $possStereoCenterCount $definedStereoCenterCount]
}

proc ens::test::noStereo {ehandle} {
	lassign [aux::stereoAtomCount $ehandle] possStereoAtomCenter definedStereoAtomCenter
	lassign [aux::stereoBondCount $ehandle] possStereoBondCenter definedStereoBondCenter
	if {$possStereoAtomCenter == 0 && $possStereoBondCenter == 0} {
		return 1
	}
	return 0
}

proc ens::test::unspecifiedStereo {ehandle} {
	if {[noStereo $ehandle]} {return 0}
	lassign [aux::stereoAtomCount $ehandle] possStereoAtomCenter definedStereoAtomCenter
	lassign [aux::stereoBondCount $ehandle] possStereoBondCenter definedStereoBondCenter
	if {$definedStereoAtomCenter == 0 && $definedStereoBondCenter == 0} {
		return 1
	}
	return 0
}

proc ens::test::partialStereo {ehandle} {
	if {[noStereo $ehandle] || [unspecifiedStereo $ehandle]} {return 0}
	lassign [aux::stereoAtomCount $ehandle] possStereoAtomCenter definedStereoAtomCenter
	lassign [aux::stereoBondCount $ehandle] possStereoBondCenter definedStereoBondCenter
	if {($possStereoAtomCenter && ($possStereoAtomCenter > $definedStereoAtomCenter)) \
		|| ($possStereoBondCenter && ($possStereoBondCenter > $definedStereoBondCenter)) \
		|| (($possStereoAtomCenter > $definedStereoAtomCenter) && ($possStereoBondCenter > $definedStereoBondCenter)) \
	} {
		return 1
	}
	return 0
}

proc ens::test::fullStereo {ehandle} {
	if {[noStereo $ehandle] || [unspecifiedStereo $ehandle] || [partialStereo $ehandle]} {return 0}
	lassign [aux::stereoAtomCount $ehandle] possStereoAtomCenter definedStereoAtomCenter
	lassign [aux::stereoBondCount $ehandle] possStereoBondCenter definedStereoBondCenter
	if {$definedStereoAtomCenter == $possStereoAtomCenter && $definedStereoBondCenter == $possStereoBondCenter} {
		return 1
	}
	return 0
}

proc ens::test::enantiomer {ehandle} {
	lassign [aux::stereoAtomCount $ehandle] dummy definedStereoAtomCenter
	if {[fullStereo $ehandle] && $definedStereoAtomCenter == 1} {
		return 1
 	}
	return 0
}

proc ens::test::diastereomer {ehandle} {
	if {[meso $ehandle]} {return 0}
	lassign [aux::stereoAtomCount $ehandle] dummy definedStereoAtomCenter
	if {[fullStereo $ehandle] && $definedStereoAtomCenter >= 2} {
		return 1
 	}
	return 0
}

proc ens::test::meso {ehandle} {
	ens need $ehandle E_CHIRALITY
	if {[ens get $ehandle E_CHIRALITY] == "meso"} {
		return 1
	}
	return 0
}

proc ens::test::neutralSalt {ehandle} {
	set ensCharge [::ens get $ehandle E_CHARGE]
	if {$ensCharge != 0} {return 0}
	set molLabel [::ens mols $ehandle]
	if {[llength $molLabel] < 2} {return 0}
	set molChargeList {}
	foreach mol $molLabel {
		set chargedAtoms [mol get $ehandle $mol A_FORMAL_CHARGE charged]
		if {[llength $chargedAtoms]} {
			set chargeSum [expr [regsub -all {\s} $chargedAtoms {+}]]
		} else {
			set chargeSum 0
		}
		if {$chargeSum != 0} {
			lappend molChargeList $chargeSum
		}
	}
	if {[llength $molChargeList]} {
		set molChargeListSum [expr [regsub -all {\s} $molChargeList {+}]]
	} else {
		set molChargeListSum 99
	}
	if {$molChargeListSum == 0} {
		return 1
	} 
	return 0
}

proc ens::test::organoMetallic {ehandle} {
 	if {![::ens atoms $ehandle metal bool]} {
		return 0
	}
	foreach metal [ens atoms $ehandle metal] {
		if {[atom::test::organoMetallic $ehandle $metal]} {
			return 1
		}
	}
	return 0
}

proc ens::test::metalComplex {ehandle} {
	foreach metal [::ens atoms $ehandle metal] {
		if {[atom::test::complexCenter $ehandle $metal]} {
			return 1
		}
	}
	return 0
}

proc ens::test::radical {ehandle} {
	if {![ens valid $ehandle A_RADICAL]} {return 0}
	set radicalList [lsort -unique [ens get $ehandle A_RADICAL]]
	if {$radicalList == "no"} {return 0}
	return 1 
}

proc ens::test::structure {ehandle testOrder parameters postTrueCmds postFalseCmds debug} {
	set globalErrorStatus 0
	set returnString {}
	array set parameterArray $parameters
	array set statusArray [createDefaultParameterArray]
	array set postTrueCmdArray $postTrueCmds
	array set postFalseCmdArray $postFalseCmds
	set testStatusVector {}
	set testErrorVector {}
	foreach test $testOrder {
		set testCmd "ens::test::$test"
		set time0 [clock clicks -milliseconds]
		if {$parameterArray($test)} {
			set cmdMsg {}
			set errorStatus($test) 0
			set errorMsg($test) {}
			set postStatusArray($test) {}
			if {![catch {eval $testCmd $ehandle} cmdMsg]} {
				set cmdStatus $cmdMsg
				set postCmd {}
				set postCommandString {}
				if {$cmdStatus && [info exists postTrueCmdArray($test)]} {
					set postCmd $postTrueCmdArray($test)
					set postCommandString $postCmd
				}
				if {!$cmdStatus && [info exists postFalseCmdArray($test)]} {
					set postCmd $postFalseCmdArray($test)
					set postCommandString $postCmd
				}
				if {$postCommandString != ""} {
					set postStatus [catch {eval $postCommandString} postMsg]
				} else {
					set postMsg {}
					set postStatus 0
				}
				if {!$postStatus} {
					set testStatus($test) $cmdStatus
					set errorStatus($test) 0
					set switchStatusArray($test) $postMsg
				} else {
					set testStatus($test) $cmdStatus
					set errorStatus($test) 1
 					set errorMsg($test) "error: post command failed: $postMsg"
					set globalErrorStatus 1
				}			
			} else {
				set testStatus($test) 0
				set errorStatus($test) 1
				set errorMsg($test) "error: test command failed: $cmdMsg"
				set globalErrorStatus 1
			}
			set testStatusVector $testStatus($test)$testStatusVector
			set testErrorVector $errorStatus($test)$testErrorVector
 		} else {
			set testStatusVector "0$testStatusVector"
			set testErrorVector "0$testErrorVector"
		}
		set time1 [clock clicks -milliseconds]
		set timeArray($test) [expr $time1 - $time0]
	}
	set returnString [list \
		status [array get testStatus] \
		errorstatus [array get errorStatus] \
		errormsg [array get errorMsg] \
		switchstatus [array get switchStatusArray] \
		statusbitset $testStatusVector \
		errorbitset $testErrorVector \
		time [array get timeArray] \
		globalerror $globalErrorStatus \
	]	
 	#ens set $ehandle E_NCICADD_TEST_STATUS_BITSET $testStatusVector
	#ens set $ehandle E_NCICADD_TEST_ERROR_BITSET $testErrorVector
	return $returnString
}

proc ens::norm::deleteIsotopeLabels {ehandle} {
	# args: ehandle normParameters
	set status 0
	set symbolList1 [::ens get $ehandle A_SYMBOL]
	::ens purge $ehandle A_ISOTOPE
	::ens get $ehandle A_SYMBOL
	set symbolList2 [::ens get $ehandle A_SYMBOL]
	if {$symbolList1 != $symbolList2} {
		return 1
	}
	return $status
}

proc ens::norm::radical {ehandle} {
 	set status 0
	#  re-calculate any radicals to CACTVS standard
	::ens purge $ehandle A_HYDROGENS_NEEDED
	::ens purge $ehandle A_RADICAL
	::ens taint $ehandle A_RADICAL
	::ens new $ehandle A_RADICAL
	# delete radical information for any atom in molecules with more than two heavy atoms
	# for smaller molecules there are some special cases
	set atomCount [::ens atoms $ehandle !hydrogen count]
	if {$atomCount > 2} {
		foreach atom [::ens atoms $ehandle radical] {
			::atom set $ehandle $atom A_RADICAL no
			set status 1
		}
	} elseif {$atomCount == 2} {
		set radicalCount [::ens atoms $ehandle {radical !metal} count]
		if {$radicalCount == 2} {
			::bond change $ehandle [::ens atoms $ehandle] 1
			set status 1
		}
	}
 	return $status
}

proc ens::norm::deleteMetalComplexCenter {ehandle} {
 	# "careful" deletion of metal center of metal complexes
	set status 0
	set metalComplexCenterList {}
	# look what the complex center are
	foreach metal [::ens atoms $ehandle metal] {
		# only those metal centers are touched which are have proper bond type complex
		# i.e. there is a need that metal complexes have been normalized before.
		if {[atom::test::complexCenter $ehandle $metal]} {
			lappend metalComplexCenterList $metal
		}
	}
	# deletion:
	foreach metal $metalComplexCenterList  {
		foreach ligand [::atom neighbors $ehandle $metal] {
			::bond delete $ehandle [list $metal $ligand]
			# uncharge the ligand atom but not for very small molecules like C#O
			if {[mol atoms $ehandle [atom mol $ehandle $ligand] !hydrogen count] > 2} {
				::atom set $ehandle $ligand A_FORMAL_CHARGE 0
			}
		}
		::atom delete $ehandle $metal
		set status 1
	}
	return $status
}

proc ens::norm::deleteSearchInfo {ehandle} {
	set status 0
	set validSearchInfo [::ens valid $ehandle A_QUERY]
	if {$validSearchInfo} {
		ens purge $ehandle A_QUERY
		set status 1
	}
	return $status
}

proc ens::norm::functionalGroups {ehandle} {
 	set status 0
	ens lock $ehandle A_RADICAL
	ens need $ehandle A_TERMINAL_DISTANCE recalc
	# C-[O,S](terminal) bond correction
	foreach heteroAtomType [list oxygen sulphur] {
		foreach carbonHeteroAtomBond [ens bonds $ehandle [list carbon $heteroAtomType]] {
			if {[bond filter $ehandle $carbonHeteroAtomBond doublebond]} {continue}
			set carbonAtom [bond atoms $ehandle $carbonHeteroAtomBond carbon]
			set heteroAtom [bond atoms $ehandle $carbonHeteroAtomBond $heteroAtomType]
			if {[atom filter $ehandle $heteroAtom {terminal !charged}]} {
				atom set $ehandle $heteroAtom A_FORMAL_CHARGE -1
				atom set $ehandle $heteroAtom A_NCICADD_NORM_CHARGE 1
				set status 1
			}
		}
	}
	# X-[O,S](terminal)n (n>1) bond correction
	foreach heteroAtom [ens atoms $ehandle [list 1 oxygen sulphur]] {
		if {[atom filter $ehandle $heteroAtom !terminal]} {continue}
		set centerHeteroAtom [atom neighbors $ehandle $heteroAtom [list 1 nitrogen phosphorus sulphur]]
		if {[lempty $centerHeteroAtom]} {continue}
		if {[bond filter $ehandle [list $heteroAtom $centerHeteroAtom] !singlebond]} {continue}
		set centerHeteroAtomNeighborList [atom neighbors $ehandle $centerHeteroAtom [list 1 oxygen sulphur]]
		if {[llength $centerHeteroAtomNeighborList] == 1} {continue}
		foreach centerHeteroAtomNeighbor $centerHeteroAtomNeighborList {
			if {[atom filter $ehandle $centerHeteroAtomNeighbor {terminal !charged singlebond}]} {
				atom set $ehandle $centerHeteroAtomNeighbor A_FORMAL_CHARGE -1
				atom set $ehandle $centerHeteroAtomNeighbor A_NCICADD_NORM_CHARGE 1
				set status 1
			}
		}
	}

	# nitro correction (any O~N~O groups)
	set substructureList [list {N(~[O;D1,H1])(~[O;D1,H1])~[*;!O]} {N(~O)(~O)O[*]} {N(O)(O)O}]
	set matchModeList [list distinct distinct all]
	set substructureStatusList [list 1 1 1] 
	foreach substructure $substructureList matchMode $matchModeList substructureStatus $substructureStatusList {
		match ss -mode $matchMode -bondorder 0 $substructure $ehandle atomMappingList
		foreach atomMapping $atomMappingList {
			lassign $atomMapping nitrogenMapping oxygen1Mapping oxygen2Mapping anyAtomMapping
			lassign $nitrogenMapping nitrogenSubAtom nitrogenStAtom
			lassign $oxygen1Mapping oxygen1SubAtom oxygen1StAtom
			lassign $oxygen2Mapping oxygen2SubAtom oxygen2StAtom
			lassign $anyAtomMapping anySubAtom anyStAtom
			if {![atom exists $ehandle $anyStAtom]} {continue}
			if {[atom neighbors $ehandle $nitrogenStAtom metal bool]} {break}
			if {[atom neighbors $ehandle $nitrogenStAtom complexbond bool]} {break}
			if {![atom filter $ehandle $oxygen1StAtom terminal] || ![atom filter $ehandle $oxygen2StAtom terminal]} {
				if {![atom filter $ehandle $oxygen1StAtom terminal] && [atom neighbors $ehandle $oxygen1StAtom !hydrogen count] != 1} {
					continue
				}
				if {![atom filter $ehandle $oxygen2StAtom terminal] && [atom neighbors $ehandle $oxygen2StAtom !hydrogen count] != 1} {
					continue
				}
			}
			set stAtomList [list $nitrogenStAtom $oxygen1StAtom $oxygen2StAtom]
			set oxygen1StBond [list $nitrogenStAtom $oxygen1StAtom]
			set oxygen2StBond [list $nitrogenStAtom $oxygen2StAtom]
			set nitrogenAnyAtomBond [list $nitrogenStAtom $anyStAtom]
			set oxygen1StSingleBonded [bond filter $ehandle $oxygen1StBond singlebond]
			set oxygen2StSingleBonded [bond filter $ehandle $oxygen2StBond singlebond]
			set oxygen1StDoubleBonded [bond filter $ehandle $oxygen1StBond doublebond]
			set oxygen2StDoubleBonded [bond filter $ehandle $oxygen2StBond doublebond]
			set nitrogenAnyStAtomSingleBonded [bond filter $ehandle $nitrogenAnyAtomBond singlebond]
			set nitrogenAnyStAtomDoubleBonded [bond filter $ehandle $nitrogenAnyAtomBond doublebond]
			set oxygen1StCharge [atom get $ehandle $oxygen1StAtom A_FORMAL_CHARGE]
			set oxygen2StCharge [atom get $ehandle $oxygen2StAtom A_FORMAL_CHARGE]
			set nitrogenStCharge [atom get $ehandle $nitrogenStAtom A_FORMAL_CHARGE]
			if {[atom filter $ehandle $anyStAtom oxygen]} {
				# only nitrate coded incorrectly as N(-O)(-O)(-O) passes the following: 
				if {!($oxygen1StSingleBonded && $oxygen2StSingleBonded && $nitrogenAnyStAtomSingleBonded \
					&& $oxygen1StCharge == -1 && $oxygen2StCharge == -1) \
				} {
					break
				} else {
					atom set $ehandle $anyStAtom A_FORMAL_CHARGE -1
				}
			}
			foreach bond [list $oxygen1StBond $oxygen2StBond] {
				if {[bond filter $ehandle $bond triplebond]} {
					bond change $ehandle $bond -1
					set status $substructureStatus
				}
			}
			foreach stAtom $stAtomList {
				if {[atom neighbors $ehandle $stAtom hydrogen bool]} {
					atom hstrip $ehandle $stAtom
					set status $substructureStatus
				}
			}
			# check whether both N-O bonds are single bonds and correct it if necessarry, if
			# nitrogen-anyAtom bond is a double bond it might be a special resonance form
			# of the nitro group with a larger resonance aromatic system.
			if {!$nitrogenAnyStAtomDoubleBonded} {
				if {$oxygen1StSingleBonded && $oxygen2StSingleBonded} {
					if {$oxygen1StCharge == -1 && $oxygen2StCharge == -1 && $nitrogenStCharge == 2} {
						bond uncharge $ehandle $oxygen1StBond
						set oxygen1StSingleBonded 0
 						set oxygen1StDoubleBonded 1
						set status $substructureStatus
					} else {
						bond change $ehandle $oxygen2StBond 1
						set oxygen2StSingleBonded 0
						set oxygen2StDoubleBonded 1
						set status $substructureStatus
					}
				}
				if {$oxygen1StDoubleBonded && $oxygen2StDoubleBonded && !$oxygen1StCharge && !$oxygen2StCharge} {
					bond change $ehandle $oxygen1StBond -1 1
					set oxygen1StDoubleBonded 0
					set oxygen1StSingleBonded 1
					set status $substructureStatus
				}	
			} else {
				set localStatus 0
				# if the nitrogenAtom-anyAtom-Bond is a doublebond and the neighbors of anyAtom are memeber
				# of a pi system, it might be a special form of the nitro group:
				set anyAtomNeighbors [atom neighbors $ehandle $anyStAtom !hydrogen [list exclude $nitrogenStAtom]]
				set anyAtomNeighborAtomIsPi 0
				foreach atom $anyAtomNeighbors {
					if {![lempty [atom pis $ehandle $atom]]} {
						set anyAtomNeighborAtomIsPi 1
					} 
				}
				if {$anyAtomNeighborAtomIsPi} {
					if {$oxygen1StDoubleBonded} {
						bond change $ehandle $oxygen1StBond -1 1
						set oxygen1StDoubleBonded 0
						set oxygen1StSingleBonded 1
						set localStatus 1
					}
					if {$oxygen2StDoubleBonded} {
						bond change $ehandle $oxygen2StBond -1 1
						set oxygen2StDoubleBonded 0
						set oxygen2StSingleBonded 1
						set localStatus 1
					}
					if {$oxygen1StCharge != -1 || $oxygen2StCharge != -1} {
						atom set $ehandle $oxygen1StAtom A_FORMAL_CHARGE -1
						atom set $ehandle $oxygen2StAtom A_FORMAL_CHARGE -1
						set oxygen2StCharge -1
						set oxygen1StCharge -1
						set localStatus 1
					}

					if {$nitrogenStCharge != 1} {
						atom set $ehandle $nitrogenStAtom A_FORMAL_CHARGE 1
						set localStatus 1
					}

				}
				if {$localStatus} {
					set status $substructureStatus
					continue
				}
			}
			if {$nitrogenStCharge != 1} {
				atom set $ehandle $nitrogenStAtom A_FORMAL_CHARGE 1
				set status $substructureStatus
			}		
			# check if the nitro group is represented correcty including charges, 
			# if not not -> correct charges, bond order should be correct already1
			# first two are the classic resonance forms, third is a resonance form
			# in larger resonance systems
			if {($oxygen1StSingleBonded && $oxygen1StCharge == -1 && $oxygen2StDoubleBonded && !$oxygen2StCharge && $nitrogenAnyStAtomSingleBonded && $nitrogenStCharge == 1) \
				|| ($oxygen1StDoubleBonded && !$oxygen1StCharge && $oxygen2StSingleBonded && $oxygen2StCharge == -1 && $nitrogenAnyStAtomSingleBonded && $nitrogenStCharge == 1) \
				|| ($oxygen1StSingleBonded && $oxygen1StCharge == -1 && $oxygen2StSingleBonded && $oxygen2StCharge == -1 && $nitrogenAnyStAtomDoubleBonded && $nitrogenStCharge == 1) \
			} {
				#set status 2
				continue	
			} else {
				if {$oxygen1StDoubleBonded} {
					if {!($oxygen1StCharge == 0 && $oxygen2StCharge == -1)} {
						atom set $ehandle $oxygen1StAtom A_FORMAL_CHARGE 0
						atom set $ehandle $oxygen2StAtom A_FORMAL_CHARGE -1
						set status $substructureStatus
					}
				} else {
					if {!($oxygen1StCharge == -1 && $oxygen2StCharge == 0)} {
						atom set $ehandle $oxygen1StAtom A_FORMAL_CHARGE -1
						atom set $ehandle $oxygen2StAtom A_FORMAL_CHARGE 0
						set status $substructureStatus
					}
				}
			}
		}		
	}
	# N-oxides RR"R'''-[N+]-[O-]: correction
	foreach bond [ens bonds $ehandle {oxygen nitrogen}] {
		set oxygenAtom [bond atoms $ehandle $bond oxygen]
		set nitrogenAtom [bond atoms $ehandle $bond nitrogen]
		if {[atom filter $ehandle $oxygenAtom terminal]} {
			set nitrogenCarbonNeighbors [atom neighbors $ehandle $nitrogenAtom carbon]
			set nitrogenCarbonNeighborCount [atom neighbors $ehandle $nitrogenAtom carbon count]
			set bondOrderSum 0
			#set carbonNeighborsInPiSystem 0
			foreach carbonNeighbor $nitrogenCarbonNeighbors {
				incr bondOrderSum [bond get $ehandle [list $nitrogenAtom $carbonNeighbor] B_ORDER]
				#if {[atom pis $ehandle $carbonNeighbor {} bool]} {
				#	foreach piSystem [atom pis $ehandle $carbonNeighbor] {
				#		incr carbonNeighborsInPiSystem  [pi atoms $ehandle $piSystem {} count]
				#	}
				#}
			} 
			if {$bondOrderSum == 3 && $nitrogenCarbonNeighborCount >= 2} {
				set oxygenAtomCharge [atom get $ehandle $oxygenAtom A_FORMAL_CHARGE]
				set nitrogenAtomCharge [atom get $ehandle $nitrogenAtom A_FORMAL_CHARGE]
				set nitrogenOxygenBondOrder [bond get $ehandle [list $oxygenAtom $nitrogenAtom] B_ORDER]
				if {!($oxygenAtomCharge == 1 && $nitrogenAtomCharge == 1 && $nitrogenOxygenBondOrder == 1)} {
					switch $nitrogenOxygenBondOrder {
						3 {continue}
						2 {
							bond change $ehandle [list $nitrogenAtom $oxygenAtom] -1 1
							set status 1
						}
						1 {
							if {!$nitrogenAtomCharge || !$oxygenAtomCharge} {
								atom set $ehandle $nitrogenAtom A_FORMAL_CHARGE +1
								atom set $ehandle $oxygenAtom A_FORMAL_CHARGE -1
								set status 1
							}
						}
						default {}
					}
				}
			}
		}
	}
	# nitrogen correction	
	foreach nitrogenAtom [ens atoms $ehandle nitrogen] {
		# quarternary nitrogen without charge
		if {[atom get $ehandle $nitrogenAtom A_FORMAL_CHARGE] == 1} {continue}
		set nitrogenNeighborCount [atom neighbors $ehandle $nitrogenAtom {!complexbond !metal} count]
		if {$nitrogenNeighborCount == 4 \
			&& ![atom neighbors $ehandle $nitrogenAtom charged bool] \
		} {
			atom set $ehandle $nitrogenAtom A_FORMAL_CHARGE 1
			set status 2
		}
		# nitrogen atoms with three substituents, at least one double bonded, without charge
		if {$nitrogenNeighborCount == 3 \
			&& [atom neighbors $ehandle $nitrogenAtom doublebond count] == 1 \
			&& [atom neighbors $ehandle $nitrogenAtom singlebond count] >= 1 \
			&& [atom neighbors $ehandle $nitrogenAtom !charged bool] \
		} {
			atom set $ehandle $nitrogenAtom A_FORMAL_CHARGE 1
			set status 2
		}
		# dazonium cation R-N#N -> R-[N+]#N
		if {$nitrogenNeighborCount == 2 \
			&& [atom neighbors $ehandle $nitrogenAtom {nitrogen} count] == 1 \
			&& [atom neighbors $ehandle $nitrogenAtom {nitrogen triplebond terminal} count] == 1 \
			&& [atom neighbors $ehandle $nitrogenAtom singlebond count] == 1 \
		} {
			set nitrogenNeighborAtom [atom neighbors $ehandle $nitrogenAtom nitrogen]
			set nitrogenNeighborAtomCharge [atom get $ehandle $nitrogenNeighborAtom A_FORMAL_CHARGE]
			switch $nitrogenNeighborAtomCharge {
				0 {
					atom set $ehandle $nitrogenAtom A_FORMAL_CHARGE 1
					set status 1
				}
				1 {
					atom set $ehandle $nitrogenNeighborAtom A_FORMAL_CHARGE 0
					atom set $ehandle $nitrogenAtom A_FORMAL_CHARGE 1
					set status 1
				}
				default {}
			}
		}
	}
	# oxygen corrections
	# oxygen formal charge on [O]([C])=[*] +1
	match ss -mode distinct {[O]([C])=[*]} $ehandle atomMappingList
	foreach atomMapping $atomMappingList {
		lassign $atomMapping oxygenMapping carbonMapping anyAtomMapping
		lassign $oxygenMapping oxygenSubAtom oxygenStAtom
		lassign $carbonMapping carbonSubAtom carbonStAtom
		lassign $anyAtomMapping anySubAtom anyStAtom
		set stAtomList [list $oxygenStAtom $carbonStAtom $anyStAtom]
		set continue 0
		foreach stAtom $stAtomList {
			if {[atom filter $ehandle $stAtom charged]} {
				set continue 1
			}
		}
		if {$continue} {continue}
		if {[atom filter $ehandle $oxygenStAtom aromatic]} {continue}
		if {[atom bonds $ehandle $oxygenStAtom complexbond bool]} {continue}
		if {[atom neighbors $ehandle $oxygenStAtom hydrogen bool]} {
			atom hstrip $ehandle $oxygenStAtom
			set status 1
		}
		set oxygenAtomCharge [atom get $ehandle $oxygenStAtom A_FORMAL_CHARGE]
		switch $oxygenAtomCharge {
			1 {#do nothing}
			default {
				atom set $ehandle $oxygenStAtom A_FORMAL_CHARGE 1
				set status 1
			}
		}
	}
	# sulfur corrections
	foreach sulphurAtom [ens atoms $ehandle {sulphur !complexbond}] {
		#set sulfurAtomNeighbors [atom neighbors $ehandle $sulfurAtom !hydrogen]
		set sulphurCharge [atom get $ehandle $sulphurAtom A_FORMAL_CHARGE]
		set sulphurNeighborCount [atom neighbors $ehandle $sulphurAtom {!hydrogen !metal} count]
		set sulphurCarbonNeighborBondCount [atom neighbors $ehandle $sulphurAtom {carbon singlebond} count]
		if {$sulphurNeighborCount == 3 && $sulphurCarbonNeighborBondCount == 3} {
			if {$sulphurCharge == 1} {
				continue 
			} else {
				atom set $ehandle $sulphurAtom A_FORMAL_CHARGE 1
				set status 1
			}
		}
		set sulphurHeteroNeighborBondCount [atom neighbors $ehandle $sulphurAtom {heteroatom doublebond} count]
		if {$sulphurNeighborCount == 2 && $sulphurCarbonNeighborBondCount == 1 && $sulphurHeteroNeighborBondCount == 1} {
			if {$sulphurCharge == 1} {
				continue
			} else {
				atom set $ehandle $sulphurAtom A_FORMAL_CHARGE 1
				set status 1
			}
		}
	}
	# halogen corrections
	foreach halogenAtom [ens atoms $ehandle halogen] {
		set halogenNeighborCount [atom neighbors $ehandle $halogenAtom {} count]
		set halogenNeighbors [atom neighbors $ehandle $halogenAtom {}]
		set halogenCharge [atom get $ehandle $halogenAtom A_FORMAL_CHARGE]
		switch $halogenNeighborCount {
			0 {
				if {$halogenCharge == 0 && [ens mols $ehandle {} count] > 1} {
					atom set $ehandle $halogenAtom A_FORMAL_CHARGE -1
					atom set $ehandle $halogenAtom A_NCICADD_NORM_CHARGE 1
					set status 1
				}
				if {$halogenCharge == -1 && [ens mols $ehandle {} count] > 1} {
					atom set $ehandle $halogenAtom A_NCICADD_NORM_CHARGE 1
				}
			}
			1 {
				set halogenNeighbor $halogenNeighbors
				set halogenNeighborCharge [atom get $ehandle $halogenNeighbor A_FORMAL_CHARGE]
				# "regular" halogen subtituent in an organic compound
				if {[atom filter $ehandle $halogenNeighbor carbon]} {
					if {$halogenCharge != 0} {
						atom set $ehandle $halogenAtom A_FORMAL_CHARGE 0
						set status 1
					}
				}
				# HX normalization
				if {[atom filter $ehandle $halogenNeighbor hydrogen]} {
					if {!$halogenCharge && !$halogenNeighborCharge} {
						bond change $ehandle [list $halogenAtom $halogenNeighbor] -1 -1
						set status 1
					} else {
						bond delete $ehandle [list $halogenAtom $halogenNeighbor]
						atom set $ehandle $halogenAtom A_FORMAL_CHARGE -1
						atom set $ehandle $halogenNeighbor A_FORMAL_CHARGE 1
						set status 1
					}
					atom set $ehandle $halogenAtom A_NCICADD_NORM_CHARGE 1
					atom set $ehandle $halogenNeighbor A_NCICADD_NORM_CHARGE 1
				}
			}
			default {
				set halogenOxygenNeighborCount [atom neighbors $ehandle $halogenAtom {oxygen terminal} count]
				set halogenOxygenNeighbors [atom neighbors $ehandle $halogenAtom {oxygen terminal}]
				set halogenMetalNeighborCount [atom neighbors $ehandle $halogenAtom {metal terminal} count]
				set halogenMetalNeighbors [atom neighbors $ehandle $halogenAtom {metal terminal}]
				# halogen oxides
				if {$halogenOxygenNeighborCount == $halogenNeighborCount || [expr $halogenOxygenNeighborCount + $halogenMetalNeighborCount] == $halogenNeighborCount} {
					# a miscoded salt:
					if {$halogenMetalNeighborCount == 1} {
						set halogenMetalNeighbor $halogenMetalNeighbors
						bond delete $ehandle [list $halogenAtom $halogenMetalNeighbor]
						atom set $ehandle $halogenAtom A_FORMAL_CHARGE 0
						atom set $ehandle $halogenMetalNeighbor A_FORMAL_CHARGE +1
 						atom set $ehandle $halogenMetalNeighbor A_NCICADD_NORM_CHARGE 1
 						set status 1
					}
					foreach oxygenAtom $halogenOxygenNeighbors {
						if {[atom filter $ehandle $oxygenAtom {doublebond charged}]} {
							atom set $ehandle $oxygenAtom A_FORMAL_CHARGE 0
							set status 1
						}
						if {[atom filter $ehandle $oxygenAtom {singlebond charged}]} {
							if {[atom get $ehandle $halogenAtom A_FORMAL_CHARGE] != -1} {
								atom set $ehandle $oxygenAtom A_FORMAL_CHARGE -1
								set status 1
							}
						}
						if {[atom filter $ehandle $oxygenAtom {singlebond !charged}]} {
							atom set $ehandle $oxygenAtom A_FORMAL_CHARGE -1
							set status 1
						}
						if {[atom filter $ehandle $oxygenAtom hneighbor]} {
							atom hstrip $ehandle $oxygenAtom
							set status 1
						}	
					}
					set oxygenSingleBondCount [atom neighbors $ehandle $halogenAtom singlebond count]
					set oxygenDoubleBondCount [atom neighbors $ehandle $halogenAtom doublebond count]

					# more than one oxgen atom is single bonded
					if {$oxygenSingleBondCount > 1} {
						foreach oxygenAtom $halogenOxygenNeighbors {
							set oxygenSingleBondCount [atom neighbors $ehandle $halogenAtom singlebond count]
							if {$oxygenSingleBondCount == 1} {break}
							if {[bond filter $ehandle [list $halogenAtom $oxygenAtom] singlebond]} {
								set halogenCharge [atom get $ehandle $halogenAtom A_FORMAL_CHARGE]
								set oxygenCharge [atom get $ehandle $oxygenAtom A_FORMAL_CHARGE] 
								if {$halogenCharge > 0 && $oxygenCharge == -1} {
									bond uncharge $ehandle [list $halogenAtom $oxygenAtom]
								} else {
									atom set $ehandle $halogenAtom A_FORMAL_CHARGE 0
									atom set $ehandle $oxygenAtom A_FORMAL_CHARGE 0
									bond change $ehandle [list $halogenAtom $oxygenAtom] 1
									set status 1
								}
							}
						}
					} elseif {$oxygenSingleBondCount == 1} {
						set singleBondedOxygenAtom [atom neighbors $ehandle $halogenAtom singlebond]
						set oxygenAtomCharge [atom get $ehandle $singleBondedOxygenAtom A_FORMAL_CHARGE]
						if {[atom get $ehandle $singleBondedOxygenAtom A_FORMAL_CHARGE] != -1} {
							atom set $ehandle $singleBondedOxygenAtom A_FORMAL_CHARGE -1
							atom set $ehandle $halogenAtom A_NCICADD_NORM_CHARGE 1
							set status 1
						}
					}
					if {$oxygenDoubleBondCount == $halogenOxygenNeighborCount} {
							foreach oxygenAtom $halogenOxygenNeighbors {
							if {[bond filter $ehandle [list $halogenAtom $oxygenAtom] doublebond]} {
								bond change $ehandle [list $halogenAtom $oxygenAtom] -1
								atom set $ehandle $oxygenAtom A_FORMAL_CHARGE -1
								atom set $ehandle $halogenAtom A_NCICADD_NORM_CHARGE 1
								set status 1
								break
							}
						}
					}
				}
			} 
		}
	}
	# phosphorus corrections
	set pstatus 0
	set dup [ens dup $ehandle]
	set origChargePattern [ens atoms $ehandle charged]
	set transform0 [list [list {[P;X5&v5&+0:1][H]>>[P;v4&+1:1]}]]
	#set transform1 [list [list {[H:3][P;X5&+0:1]-[O;X1&-0:2]>>[P:1]-[O:2][H:3]}]]
	set transform2 [list [list {[P;X4&v4&+0,X4&v4&+1:1]-[O;X1&-0:2]>>[P;v4&+0:1]-[O;-1:2]}]]
	set transform3 [list [list {[P;X4&v4&+1:1]-[O;X1&-1:2]>>[P;v4&+0:1]=[O;+0:2]}]]
	set transform4 [list [list {[P;X4&v4&+0,X4&v4&+1:1]-[O;X2:2][H]>>[P;v4&+0:1]=[O;+0:2]}]]
	set transform5 [list [list {[P;X4&v4;+0:1]>>[P;+1:1]}]]
	set transform6 [list [list {[P;X4&v4&+1:1][O;X1&-1:2]>>[P:1]=[O;+0:2]}]]
	set transform7 [list [list {[P;X3&v5:1](=[O;X1:2])=[O;X1:3]>>[P:1](=[O;+0:2])-[O;-1:3]}]]
	
	foreach transform [list $transform0 $transform2 $transform3 $transform4 $transform5 $transform6 $transform7] {
		set correctedEns [ens transform $dup $transform forward exhaustive first {nohadd removeh filtercharges}]
		if [llength $correctedEns] {
			set pstatus 1
			ens copy $correctedEns $dup
			ens delete $correctedEns
		} else {
			ens delete $correctedEns
		}
	}

	if {$pstatus} {
 		foreach atom [ens atoms $dup charged] {
 			if {![lcontain $origChargePattern $atom] && [atom filter $dup $atom oxygen]} {
				atom set $dup $atom A_NCICADD_NORM_CHARGE 1
			}
		}
		
 		ens copy $dup $ehandle
		ens delete $dup
		set status 1
	} else {
		ens delete $dup
	}
 	
	if {![lempty [ens get $ehandle A_FORMAL_CHARGE]]} {
		set grossCharge [expr [regsub -all { } [ens get $ehandle A_FORMAL_CHARGE] {+}]]
		if {$grossCharge != 0} {
			foreach atom [ens atoms $ehandle normcharge] {
				atom set $ehandle $atom A_FORMAL_CHARGE 0
			}
		}
	}
  	ens unlock $ehandle A_RADICAL
	return $status
}

proc ens::norm::metalLigandBonds {ehandle} {
 	set status 0
 	set grossCharge [expr [regsub -all { } [ens get $ehandle A_FORMAL_CHARGE] {+}]]
#	XXX
#	set ensdup [ens dup $ehandle]
#	set ensList [ens split $ensdup]
	set ensList [ens split $ehandle]
	foreach ens $ensList {
		array unset metalArray
		array unset metalLigandBondArray
 		foreach metalAtom [::ens atoms $ens metal] {
			set metalArray($metalAtom,coordinationNumber) 0
			array unset ligandArray 
			set metalPseGroup [::atom get $ens $metalAtom A_IUPAC_GROUP]
			set coordinationNumber [::atom neighbors $ens $metalAtom {} count]
			set coordinationAtomLabels [::atom neighbors $ens $metalAtom]
			set metalNeighborLabels [::atom neighbors $ens $metalAtom metal]
			set metalNeighborNumber [::atom neighbors $ens $metalAtom metal count]
			ens purge $ens A_FLAGS
			foreach atom $coordinationAtomLabels {
				atom set $ens $atom A_FLAGS "starred"
			}
			set ddup [ens dup $ens]
			foreach atom [ens atoms $ddup metal] {
				atom delete $ddup $atom
			}
			set ligandList [ens split $ddup]
			# XXX
			ens delete $ddup
 			set ligandLabel 0
			set maxBondOrder 0
			set ligandHashList {}
			set uniqueLigandCount 0
			foreach ligandEns $ligandList {
				if {[ens atoms $ligandEns asteriskatom count] == 0} {
					ens delete $ligandEns
					continue
				}
				incr ligandLabel
				set ligandHydrogenDup [ens dup $ligandEns]
 				ens hadd $ligandHydrogenDup {} {nometals noelements nohighvalence}
				set ligandArray($ligandLabel,ens) $ligandEns
				set ligandArray($ligandLabel,hens) $ligandHydrogenDup
				set ligandArray($ligandLabel,bondLabels) {}
				set ligandArray($ligandLabel,coordinationAtomLabels) {}
				set ligandArray($ligandLabel,coordinationAtomIsPi) {}
				set ligandArray($ligandLabel,isorganic) [ens bonds $ligandArray($ligandLabel,hens) chbond bool]
				lappend ligandHashList [ens get $ligandEns E_HASHSY]
				foreach asteriskatom [ens atoms $ligandEns asteriskatom] {
  					set b [bond get $ens [list $metalAtom $asteriskatom] B_LABEL]
					lappend ligandArray($ligandLabel,bondLabels) $b
 					lappend ligandArray($ligandLabel,bondTypes) [bond get $ehandle $b B_TYPE]
					lappend ligandArray($ligandLabel,coordinationAtomLabels) $asteriskatom
					lappend ligandArray($ligandLabel,coordinationAtomPseGroup) [atom get $ligandEns $asteriskatom A_IUPAC_GROUP]					
					lappend ligandArray($ligandLabel,coordinationAtomIsPi) [atom pis $ligandHydrogenDup $asteriskatom {} bool]
					#lappend ligandArray($ligandLabel,metalAtom) 
					set bondOrder [bond get $ehandle $b B_ORDER]
					lappend ligandArray($ligandLabel,coordinationAtomBondOrder) $bondOrder
					
					
					if {$bondOrder > $maxBondOrder} {
						set maxBondOrder $bondOrder
					}
					incr metalArray($metalAtom,coordinationNumber)
				}
 			}
			set uniqueLigandCount [llength [lsort -unique $ligandHashList]]
			set metalArray($metalAtom,uniqueLigandCount) $uniqueLigandCount
			set metalArray($metalAtom,ligandNumber) $ligandLabel
			set metalArray($metalAtom,maxBondOrder) $maxBondOrder
 			if {$ligandLabel > 0} {
				set metalArray($metalAtom,ligandLabels) [lseq 1 $metalArray($metalAtom,ligandNumber)]
			} else {
				set metalArray($metalAtom,ligandLabels) {}
			}
 			set ligandSize {}
			set hapto 0
			set haptoBondNumber 0
			set haptoLigandNumber 0
 			foreach ligandLabel $metalArray($metalAtom,ligandLabels) {
				# ligand normalization of small single bond ligands
				set lhandle $ligandArray($ligandLabel,ens)
				if {[llength $ligandArray($ligandLabel,coordinationAtomLabels)] == 1} {
					set coordinationAtom $ligandArray($ligandLabel,coordinationAtomLabels)
					set coordinationBondLabel [bond get $ehandle [list $metalAtom $coordinationAtom] B_LABEL]
					set coordinationBondOrder [bond get $ehandle $coordinationBondLabel B_ORDER]
					set coordinationAtomNeighbors [atom neighbors $ehandle $coordinationAtom !hydrogen [list exclude $metalAtom]]
					# carbonyl complexes
					if {[atom filter $ehandle $coordinationAtom carbon] && [llength $coordinationAtomNeighbors] == 1 && $coordinationBondOrder <= 1} {
						set secondAtom $coordinationAtomNeighbors
 						if {[atom filter $ehandle $secondAtom oxygen]} {
							atom hstrip $ehandle $coordinationAtom
							atom hstrip $lhandle $coordinationAtom
							atom hstrip $ehandle $secondAtom
							atom hstrip $lhandle $secondAtom
							atom set $ehandle $secondAtom A_FORMAL_CHARGE +1
							atom set $lhandle $secondAtom A_FORMAL_CHARGE +1
							atom set $ehandle $coordinationAtom A_FORMAL_CHARGE -1
							atom set $lhandle $coordinationAtom A_FORMAL_CHARGE -1
							bond set $ehandle [list $coordinationAtom $secondAtom] B_ORDER 3
							bond set $lhandle [list $coordinationAtom $secondAtom] B_ORDER 3
							set status 1
						}
 					}
					# single nitrogen as ligand
					if {[atom filter $ehandle $coordinationAtom nitrogen] && [lempty $coordinationAtomNeighbors] && $coordinationBondOrder <= 1} {
 						atom hstrip $ehandle $coordinationAtom
						atom hstrip $lhandle $coordinationAtom
						set ncharge [min [max [atom get $ehandle $coordinationAtom A_FORMAL_CHARGE] -1] 1]
						set hydrogensNeeded [expr 3 + $ncharge]
						atom set $ehandle $coordinationAtom A_HYDROGENS_NEEDED $hydrogensNeeded
						atom set $lhandle $coordinationAtom A_HYDROGENS_NEEDED $hydrogensNeeded
						atom hadd $ehandle $coordinationAtom
						atom hadd $lhandle $coordinationAtom
						set status 1
 					}
					# complex water coded as single oxygen atom
					if {[atom filter $ehandle $coordinationAtom oxygen] \
						&& [lempty $coordinationAtomNeighbors] \
						&& $coordinationBondOrder <= 1 \
						&& $metalArray($metalAtom,maxBondOrder) <= 1
					} {
						set hydrogenAtoms [atom neighbors $ehandle $coordinationAtom hydrogen count]
						set noHydrogenAtoms [atom neighbors $ehandle $coordinationAtom {!hydrogen} [list count exclude $metalAtom]]
						if {$noHydrogenAtoms == 0 && $hydrogenAtoms == 0} {
							# only oxygen atoms as ligands:
							#if {$metalArray($metalAtom,uniqueLigandCount) == 1} {
							#	unfinished. moced downwards
							#}
						} elseif {$noHydrogenAtoms == 0 && $hydrogenAtoms != 0} {
							# moved downwards
							#set oxygenCharge [min [max [atom get $ehandle $coordinationAtom A_FORMAL_CHARGE] -1] 1]
							#set oxygenBonds [atom bonds $ehandle $coordinationAtom !hydrogen count]
							#set hydrogensNeeded [expr 2 + $oxygenCharge - $hydrogenAtoms - $oxygenBonds]
							#atom set $ehandle $coordinationAtom A_HYDROGENS_NEEDED $hydrogensNeeded
							#atom set $lhandle $coordinationAtom A_HYDROGENS_NEEDED $hydrogensNeeded
							#atom hadd $ehandle $coordinationAtom
							#atom hadd $lhandle $coordinationAtom
						}	
					}
				}
				foreach atom $ligandArray($ligandLabel,coordinationAtomLabels) isPi $ligandArray($ligandLabel,coordinationAtomIsPi) {
					atom set $ligandArray($ligandLabel,ens) $atom A_FORMAL_CHARGE 0
					if {$isPi} {incr hapto}
				}
				if {$hapto >= 3 && $hapto == [llength $ligandArray($ligandLabel,coordinationAtomLabels)]} {
					incr haptoLigandNumber
					incr haptoBondNumber $hapto
				}
				# some statistics
				set ligandArray($ligandLabel,size) [ens atoms $ligandArray($ligandLabel,ens) {} count]		
 				lappend ligandSize $ligandArray($ligandLabel,size)
			}
 			set ligandMaxSize [lindex [lsort -unique -integer -decreasing $ligandSize] 0]
 			set coordinationNumber $metalArray($metalAtom,coordinationNumber)
			set ligandNumber [llength $metalArray($metalAtom,ligandLabels)]
			set minimalComplexCoordinationNumber [atom::element::get [atom get $ehandle $metalAtom A_SYMBOL] minimalComplexCoordinationNumber]
			foreach ligandLabel $metalArray($metalAtom,ligandLabels) {
				foreach	ligandBond $ligandArray($ligandLabel,bondLabels) \
					bondType $ligandArray($ligandLabel,bondTypes) \
					ligandAtom $ligandArray($ligandLabel,coordinationAtomLabels) \
					ligandAtomPseGroup $ligandArray($ligandLabel,coordinationAtomPseGroup) \
				{
 					set ligandBondArray($ligandBond) "default"
					set metalAtomSymbol [atom get $ehandle $metalAtom A_SYMBOL]
 					set ligandAtomSymbol [atom get $ehandle $ligandAtom A_SYMBOL]
					if {[atom filter $ehandle $ligandAtom metal]} {
						set metalLigandBondArray($ligandBond) "keep"
						continue
					}
					# single atom ligands, only one class of ligands
					if {$ligandMaxSize == 1} {
 						switch $ligandAtomPseGroup {
							1 {
								# hydrides
								if {[atom filter $ehandle $ligandAtom hydrogen]} {
									set metalLigandBondArray($ligandBond) [atom::element::get $metalAtomSymbol hydridCharacter]
									if {$metalLigandBondArray($ligandBond) == "ionic" || $metalLigandBondArray($ligandBond) == "covalent"} {
 										atom set $ehandle $ligandAtom A_HYDROGENS_NEEDED 0
									}
								}
							}
							15 {
								# ammonia complexes; ammonia salts
								if {$coordinationNumber >= $minimalComplexCoordinationNumber} {
									set metalLigandBondArray($ligandBond) "complex"
 								} else {
									set metalLigandBondArray($ligandBond) "ionic"
 								}
							}
							16 {
								# oxides
								set metalLigandBondArray($ligandBond) [atom::element::get $metalAtomSymbol oxidCharacter]
							}
							17 {
								# halogens
								if {$coordinationNumber >= $minimalComplexCoordinationNumber} {
									set metalLigandBondArray($ligandBond) "complex"
								} else {
									set metalLigandBondArray($ligandBond) "ionic"
								}
							}
							18 {
								# nobel gases
								set metalLigandBondArray($ligandBond) "none"
							}
							default {
								# any other PSE groups (mostly e.g. other metals)
								set metalLigandBondArray($ligandBond) "keep"
							}
						}
					} elseif {$ligandMaxSize == 2} {
						if {$metalPseGroup <= 2 } {
							if {$coordinationNumber <= 2} {
								set metalLigandBondArray($ligandBond) "ionic"
							} elseif {$coordinationNumber >= [max $minimalComplexCoordinationNumber 3]} {
								set metalLigandBondArray($ligandBond) "complex"
							} else {
								set metalLigandBondArray($ligandBond) "keep"
							}
						} elseif {$metalPseGroup >= 3 && $metalPseGroup <= 11} {
							if {$coordinationNumber < $minimalComplexCoordinationNumber} {
								set metalLigandBondArray($ligandBond) "ionic"
							} else {
								set metalLigandBondArray($ligandBond) "complex"
							}
						} else {
							set metalLigandBondArray($ligandBond) "keep"
						}
					} else {
						set ligandAtomFreeElectrons [atom get $ehandle $ligandAtom A_FREE_ELECTRONS]
						set ligandAtomLonePairElectrons [atom::element::get $ligandAtomSymbol maxValenceLonePairElectrons]
						set ligandAtomValence [atom bonds $ehandle $ligandAtom complexbond count]
						foreach neighbor [atom neighbors $ehandle $ligandAtom !metal] {
							incr ligandAtomValence [bond get $ehandle [list $ligandAtom $neighbor] B_ORDER]
						}
						set ligandAtomMaxValences [atom::element::get $ligandAtomSymbol maxValence]
						if {[atom filter $ehandle $ligandAtom heteroatom]} {
							set ligandCoordination [expr $coordinationNumber - ($haptoBondNumber - $haptoLigandNumber)]
							if {$ligandCoordination >= $minimalComplexCoordinationNumber} {
								set metalLigandBondArray($ligandBond) "complex"
							} else {
								if {$metalPseGroup <= 2} {
									set metalLigandBondArray($ligandBond) "ionic"
								} elseif {$metalPseGroup >= 3 && $metalPseGroup <= 11} { 
									set maxValence [atom::element::get $metalAtomSymbol maxValence]
									if {$ligandArray($ligandLabel,isorganic)} {
										set maxValence [min 3 $maxValence]
									}
									if {$coordinationNumber >= $maxValence} {	
 										if {$ligandAtomFreeElectrons >= $ligandAtomLonePairElectrons && $ligandAtomMaxValences >= $ligandAtomValence} {
											if {[atom filter $ehandle $metalAtom charged] && [atom filter $ehandle $ligandAtom charged]} {
												set metalLigandBondArray($ligandBond) "complex"
											} else {
												set metalLigandBondArray($ligandBond) "covalent"
											}
										} else {
											set metalLigandBondArray($ligandBond) "complex"
										}
									} else {
										set metalLigandBondArray($ligandBond) "ionic"
									}
								} else {
									# too dangerous to do things here:
									set metalLigandBondArray($ligandBond) "keep"
								}
							}
						} elseif {[atom filter $ehandle $ligandAtom carbon]} {
							if {![atom valcheck $ligandArray($ligandLabel,hens) $ligandAtom]} {
 								set metalLigandBondArray($ligandBond) "complex"
							} else {
								if {$metalPseGroup == 1} {
									if {$coordinationNumber == 1} {
										set metalLigandBondArray($ligandBond) "ionic"
									} else {
										set metalLigandBondArray($ligandBond) "keep"
									}
								} elseif {$metalPseGroup == 2} {
									set metalLigandBondArray($ligandBond) "keep"
								} elseif {$metalPseGroup >= 3 && $metalPseGroup <= 11} {
									if {[llength $ligandArray($ligandLabel,bondLabels)] > 1 && [atom pis $ehandle $ligandAtom {} bool]} {
										set metalLigandBondArray($ligandBond) "complex"
									} else {
 										if {!$ligandArray($ligandLabel,isorganic)} {
											set metalLigandBondArray($ligandBond) "complex"
										} else {
											set metalLigandBondArray($ligandBond) "covalent"
										}
									}
								} else {
									set metalLigandBondArray($ligandBond) "keep"
								}
							}
						} elseif {[atom filter $ehandle $ligandAtom hydrogen]} {
							set metalLigandBondArray($ligandBond) [atom::element::get $metalAtomSymbol hydridCharacter]
						}
					}
					
				}
				ens delete $ligandArray($ligandLabel,ens)
				ens delete $ligandArray($ligandLabel,hens)
  			}
		}
		foreach bond [array names metalLigandBondArray] {
			set newBondType $metalLigandBondArray($bond)
			set bondType [bond get $ehandle $bond B_TYPE]		
  			set metalAtom [bond atoms $ehandle $bond metal]
			set ligandAtom [bond atoms $ehandle $bond !metal]
			# we dont change metal center with multiple bond order center:
			set break 0
			set neighbors [atom neighbors $ehandle $metalAtom !metal]
			foreach neighbor $neighbors {
				if {[bond filter $ehandle [list $metalAtom $neighbor] multiplebond]} {
					set break 1
					break
				}
			}
			if {$break} {break}
			set dup [ens dup $ehandle]
			if {[catch {
				switch $newBondType {
					covalent {
						if {$bondType != "normal"} {
 							::bond create $ehandle [list $metalAtom $ligandAtom] 0
 							::bond create $ehandle [list $metalAtom $ligandAtom] normal
							set staus 1
						}
					}
					complex {
						if {$bondType != "complex"} {
							::bond create $ehandle [list $metalAtom $ligandAtom] complex
							set status 1
						}
						# complex water
						if {[atom filter $ehandle $ligandAtom oxygen]} {
							set hydrogenCount [atom neighbors $ehandle $ligandAtom hydrogen count]
							set nonHydrogenCount [atom neighbors $ehandle $ligandAtom !hydrogen [list count exclude $metalAtom]]
							set oxygenCharge [min [max [atom get $ehandle $ligandAtom A_FORMAL_CHARGE] -1] 1]
							if {$nonHydrogenCount == 0} {
								set hydrogensNeeded [expr 2 + $oxygenCharge - $hydrogenCount]
								atom set $ehandle $ligandAtom A_HYDROGENS_NEEDED $hydrogensNeeded
								atom hadd $ehandle $ligandAtom
							}
						}
					}
					ionic {
						if {$bondType == "normal"} {
							::bond change $ehandle [list $metalAtom $ligandAtom] -1 1
						} elseif {$bondType == "complex"} {
							set metalAtomCharge [::atom get $ehandle $metalAtom A_FORMAL_CHARGE]
							set ligandAtomCharge [::atom get $ehandle $ligandAtom A_FORMAL_CHARGE]
							if {$metalAtomCharge > 0 && $ligandAtomCharge < 0} {
								::bond delete $ehandle [list $metalAtom $ligandAtom]
							} else {
								::bond delete $ehandle [list $metalAtom $ligandAtom]
								::atom set $ehandle $metalAtom A_FORMAL_CHARGE [incr metalAtomCharge +1]
								::atom set $ehandle $ligandAtom A_FORMAL_CHARGE [incr ligandAtomCharge -1]
							}
						} else {
							set metalAtomCharge [::atom get $ehandle $metalAtom A_FORMAL_CHARGE]
							set ligandAtomCharge [::atom get $ehandle $ligandAtom A_FORMAL_CHARGE]
							::bond delete $ehandle [list $metalAtom $ligandAtom]
							::atom set $ehandle $metalAtom A_FORMAL_CHARGE [incr metalAtomCharge +1]
							::atom set $ehandle $ligandAtom A_FORMAL_CHARGE [incr ligandAtomCharge -1]
						}
						set status 1
					}
					none {
						::bond delete $ehandle [list $metalAtom $ligandAtom]
						set status 1
					}
					keep -
					default {
						# do nothing
					}
				}
			}]} {
				ens copy $dup $ehandle
				ens delete $dup
				foreach ens $ensList {
					ens delete $ens
				}
				#ens delete $ensdup
				error "ens::norm::metalLigandBond: bond normalization failed for bond '$bond'"
			} else {
				ens delete $dup
			}
		}
	}
	foreach ens $ensList {
		ens delete $ens
	}
 	return $status
}

proc ens::norm::stereo {ehandle trustBondStereoLabel trustAtomCoordinates crossStereoBondsInChargedResonance crossTautoStereoBonds deleteTautoStereoAtoms deleteStereoAtomsInChargedResonance} {
	set status 0
	array unset stereoAtomArray
	array unset stereoBondArray
 	array unset crossBondArray
	#ens taint $ehandle [list atom bond]
	ens purge $ehandle A_HSPECIAL
	ens taint $ehandle A_HSPECIAL
	#ens need $ehandle {A_LABEL_STEREO B_LABEL_STEREO}
	ens need $ehandle {A_STEREOINFO B_STEREOINFO A_STEREOGENIC B_STEREOGENIC} recalc
 	foreach atom [ens atoms $ehandle astereogenic] {
		set stereoAtomArray($atom) [atom get $ehandle $atom A_STEREOINFO]
	}
	foreach bond [ens bonds $ehandle bstereogenic] {
		set stereoBondArray($bond) [bond get $ehandle $bond B_STEREOINFO]
	}
	#
	#
	#
	if {$crossTautoStereoBonds || $deleteTautoStereoAtoms} {
		set tautomers [ens::tautomer::createSet $ehandle 100]
	}
	if {$crossTautoStereoBonds} {
		#set dup [ens dup $ehandle]
		ens purge $ehandle B_NCICADD_TAUTO_CROSSED
		ens::tautomer::crossPseudoStereoBonds [concat $ehandle $tautomers]
	}
	if {$deleteTautoStereoAtoms} {
		ens purge $ehandle B_NCICADD_TAUTO_CROSSED
		ens::tautomer::deletePseudoStereoAtoms [concat $ehandle $tautomers]
	}
	catch {eval ens delete $tautomers}
	#
	#
	if {$crossStereoBondsInChargedResonance && $deleteStereoAtomsInChargedResonance} {
		set rset [ens::resonance::createSet $ehandle 100]
	}
	if {$crossStereoBondsInChargedResonance} {
		ens purge $ehandle B_NCICADD_RESONANCE_CROSSED
		ens::resonance::crossPseudoStereoBonds [concat $ehandle $rset]
	}
	if {$deleteStereoAtomsInChargedResonance} {
		ens purge $ehandle B_NCICADD_RESONANCE_CROSSED
		ens::resonance::deletePseudoStereoAtoms [concat $ehandle $rset]
	}
	catch {eval ens delete $rset}
	#
	#
	#foreach bond [array names crossBondArray] {
	#	if {$crossBondArray($bond)} {
	#		bond create $ehandle $bond crossed
	#	} 
	#}
	if {$trustAtomCoordinates} {
		ens need $ehandle A_XY
		ens new $ehandle B_LABEL_STEREO
		ens new $ehandle B_CIP_STEREO
		ens new $ehandle B_CISTRANS_STEREO
	}
	ens new $ehandle B_STEREOINFO
	foreach bond [ens bonds $ehandle bstereogenic] {
		# cross out any double bonds which still have no explictely stereo descriptor available yet
		if {[bond nget $ehandle $bond B_STEREOINFO]==0} {
			set crossBondArray($bond) 1
 		} else {
			set crossBondArray($bond) 0
 		}
	}

	foreach bond [array names crossBondArray] {
		if {$crossBondArray($bond)} {
			bond create $ehandle $bond crossed
		} 
	}
	# calculate all stereo descriptors from present state
  	ens need $ehandle B_LABEL_STEREO
	ens new $ehandle B_CIP_STEREO
	ens new $ehandle B_CISTRANS_STEREO
	# test on a duplicate whether recalcualtion of all stereo descriptors succeeds 
	set stereoDup [ens dup $ehandle]
	set stereoRecalcStatusFailed [catch {
		if {$trustAtomCoordinates} {
			ens need $stereoDup {A_LABEL_STEREO B_LABEL_STEREO}
			ens need $stereoDup {A_CIP_STEREO B_CIP_STEREO A_DL_STEREO B_CISTRANS_STEREO A_HASH_STEREO A_STEREOINFO} recalc
		} else {
			ens need $stereoDup A_LABEL_STEREO
			ens need $stereoDup {A_LABEL_STEREO A_CIP_STEREO A_DL_STEREO A_HASH_STEREO A_STEREOINFO} recalc
		}
	}] 
	ens delete $stereoDup
	# do it on the original ensemble
	if {$trustAtomCoordinates} {
		if {!$stereoRecalcStatusFailed} {
			ens need $ehandle {A_LABEL_STEREO B_LABEL_STEREO}
			ens need $ehandle {A_CIP_STEREO B_CIP_STEREO A_DL_STEREO B_CISTRANS_STEREO A_HASH_STEREO A_STEREOINFO} recalc
		} else {
			catch {
				ens need $ehandle {A_LABEL_STEREO B_LABEL_STEREO}
				ens need $ehandle {A_CIP_STEREO B_CIP_STEREO A_DL_STEREO B_CISTRANS_STEREO A_HASH_STEREO A_STEREOINFO}
			}
		}
	} else {
		if {!$stereoRecalcStatusFailed} {
			ens need $ehandle A_LABEL_STEREO 
			ens need $ehandle {A_CIP_STEREO A_DL_STEREO A_HASH_STEREO A_STEREOINFO} recalc
		} else {
			catch {
				ens need $ehandle A_LABEL_STEREO
				ens need $ehandle {A_LABEL_STEREO A_CIP_STEREO A_DL_STEREO A_HASH_STEREO A_STEREOINFO}
			}
		}
		# if bond stereo labels are set not to be trusted kick any of them out
		if {!$trustBondStereoLabel} {
			ens purge $ehandle {B_LABEL_STEREO B_CIP_STEREO B_CISTRANS_STEREO}
			foreach bond [ens bonds $ehandle bstereogenic] {
				bond set $ehandle $bond B_FLAGS crossed
			}
			ens new $ehandle {B_LABEL_STEREO B_CIP_STEREO B_CISTRANS_STEREO}
		}
 	}
	# rest of procedure deals with whether stereo information has been changed on the ensemble
	ens new $ehandle {A_STEREOGENIC A_STEREOINFO}
	ens new $ehandle {B_STEREOGENIC B_STEREOINFO}
	set break 0
	foreach atom [ens atoms $ehandle astereogenic] {
		if {$break} {break}	
		if {[prop compare A_STEREOINFO $stereoAtomArray($atom) [atom get $ehandle $atom A_STEREOINFO]] \
				|| [atom filter $ehandle $atom tautodeletedstereoatom] \
				|| [atom filter $ehandle $atom resonancedeletedstereoatom] \
		} {
			set status 1
			set break 1
			if {$break} {break}
		}
	}
	if {!$break} {
		foreach bond [ens bonds $ehandle bstereogenic] {
			if {$break} {break}
			if {[prop compare B_STEREOINFO $stereoBondArray($bond) [bond get $ehandle $bond B_STEREOINFO]] \
				|| [bond filter $ehandle $bond resonancecrossedbond] \
				|| [bond filter $ehandle $bond tautocrossedbond] \
			} {
				set status 1
				set break 1
				if {$break} {break}
			}
		}
	}
	return $status	
}

proc ens::norm::deleteStereoInfo {ehandle {includeBondFlags 1}} {
 	set status 0
	ens need $ehandle {A_STEREOINFO B_STEREOINFO}
	set stereoInfoPresent [expr [ens atoms $ehandle stereoatom bool] || [ens bonds $ehandle stereobond bool]]
	ens taint $ehandle {A_DL_STEREO A_CIP_STEREO A_LABEL_STEREO B_CISTRANS_STEREO A_HASH_STEREO B_CIP_STEREO B_LABEL_STEREO}
	ens purge $ehandle {A_DL_STEREO A_CIP_STEREO A_LABEL_STEREO B_CISTRANS_STEREO A_HASH_STEREO B_CIP_STEREO B_LABEL_STEREO}
	ens taint $ehandle stereo
	if {$stereoInfoPresent} {
		set status 1
	}
	if {$includeBondFlags} {
		set newBondFlagList {}
		foreach bond [ens bonds $ehandle] {
			set bondFlagList [bond get $ehandle $bond B_FLAGS]
			foreach flag $bondFlagList {
				set newBondFlagList [ldelete $flag lowwedgetip highwedgetip dashed dotted wavy]
				bond set $ehandle $bond B_FLAGS $newBondFlagList
			}
			if {[bond filter $ehandle $bond bstereogenic]} {
				bond create $ehandle $bond crossed
			}
			if {[bond get $ehandle $bond B_FLAGS] != $bondFlagList} {
				set status 1
			}
		}
	}
	return $status
}

proc ens::norm::desalt {ehandle} {
	# proc returns $status=1 in case the structure was manipulated  
	set status 0
	if {[ens atoms $ehandle {} count] < 2} {
		return $status
	}
	# delete single atom ions
	foreach atom [ens::filter::counterIonAtoms $ehandle] {
		::atom delete $ehandle $atom
		set status 1
	}
	# deletion of all terminal metal atoms (salts miscoded with an covalent bond)
	foreach terminalMetalAtom [::ens atoms $ehandle {terminal metal}] {
		if {[atom neighbors $ehandle $terminalMetalAtom metal bool]} {continue}
		::atom delete $ehandle $terminalMetalAtom
		set status 1
	}
	# check for remaining atoms, deletion if they are not classified as metal complex center
	#foreach metalAtom [::ens atoms $ehandle metal] {
	#	if {![atom::test::complexCenter $ehandle $metalAtom] && ![atom::test::organoMetallic $ehandle $metalAtom]} {
	#		::atom delete $ehandle $metalAtom
	#		set status 1
	#	}
	#}
	return $status
}

proc ens::norm::hsaturation {ehandle doHstrip purgeRadicals excludeAtomLabelList excludeAtomFilterList flagList changeList} {
 	set status 0
	if {$doHstrip} {
		::ens hstrip $ehandle
	}
	if {$purgeRadicals} {
		::ens purge $ehandle A_RADICAL
	}
	set filteredAtomList [::ens atoms $ehandle $excludeAtomFilterList]
	set excludeAtomLabelList [lsort -unique [concat $excludeAtomLabelList $filteredAtomList]]
 	if {[llength $excludeAtomLabelList]} {
		foreach atom [::ens atoms $ehandle {} [list exclude $excludeAtomLabelList]] {
			if {[lsearch $excludeAtomLabelList $atom] == -1} {
				if {[::atom hadd $ehandle $atom {} $flagList]} {
					set status 1
				}
			}
		}
	} else {
		set hstatus [::ens hadd $ehandle {} $flagList $changeList]
		if {$hstatus} {set status 1}
	}
	ens need $ehandle A_RADICAL recalc
	return $status
}

proc ens::norm::resonance {ehandle maxens timeout hashcode ignoreExlusiveNitroCharges crossStereoBondsInChargedResonance} {
	set status 0
	if {[::ens bonds $ehandle !hbond count] == 0} {
		return $status
	}
	set chargedAtomList [ens atoms $ehandle [atom::filterlist::get chargedAtoms]]
	if {$ignoreExlusiveNitroCharges && [ens::resonance::chargeIsExclusivelyOnNitroGroups $ehandle $chargedAtomList]} {
		return $status
	}
	set hash1 [ens atoms $ehandle charged]
	ens purge $ehandle B_NCICADD_RESONANCE_CROSSED
	set resonanceStructures [ens::resonance::createSet $ehandle 1000 0]
	if {[llength $resonanceStructures] >= $maxens} {set ::cactvs(setsize_exceeded) 1}
	set crossStatus [ens::resonance::crossPseudoStereoBonds $resonanceStructures]
	set deleteStereoStatus [ens::resonance::deletePseudoStereoAtoms $resonanceStructures]
	set canonicStructure [ens::resonance::canonic $resonanceStructures 1 $hashcode]
	set hash2 [ens atoms $canonicStructure charged]
	if {$hash1 != $hash2 || [ens bonds $canonicStructure resonancecrossedbond bool] || [ens atoms $canonicStructure resonancedeletedstereoatom bool]} {
		set status 1
	}
	ens purge $canonicStructure A_MAPPING
	ens taint $canonicStructure {atoms bonds}
	ens copy $canonicStructure $ehandle
	ens delete $canonicStructure
	return $status
}

proc ens::norm::uncharge {ehandle strictCactvsUncharge hashcode} {
 	set status 0
	set ustatus 0
	set hstatus 0
	set grossCharge [expr [regsub -all { } [ens get $ehandle A_FORMAL_CHARGE] {+}]]
	# oxygen/sulphur radical
	if {$strictCactvsUncharge && [ens atoms $ehandle {!oxygen !sulphur} count] == [ens atoms $ehandle {} count] && [ens bonds $ehandle {} count] == 0 && $grossCharge == 0} {
		foreach atom [ens atoms $ehandle] {
			atom hadd $ehandle $atom
		}
	}
	if {$strictCactvsUncharge && [ens atoms $ehandle halogen count] == [ens atoms $ehandle {} count] && [ens bonds $ehandle {} count] == 0 && $grossCharge == 0} {
		foreach atom [ens atoms $ehandle] {
			set newHalogenAtom [atom create $ehandle [atom get $ehandle $atom A_SYMBOL]]
			bond create $ehandle [list $newHalogenAtom $atom]
			set hstatus 1
		}
	}
	# only single halogen atoms without charge --> they are uncharged es diradicals
	# XXX
	set molList [ens mols $ehandle]
	set splitEnsList [ens split $ehandle]
	#set dup [ens dup $ehandle]
	#set molList [ens mols $dup]
	#set splitEnsList [ens split $dup]
	foreach ens $splitEnsList {
		if {$strictCactvsUncharge} {
			set hash1 [ens get $ens $hashcode] 
			set hash2 0
			::ens purge $ens $hashcode
			::ens need $ens $hashcode
			while {$hash1 != $hash2} {
				set hash2 $hash1
				::ens uncharge $ens
				::ens need $ens $hashcode recalc
				set hash1 [ens get $ens $hashcode]
				set status 1
			}
		} else {
			if {![ens atoms $ens normcharge bool]} {
				set ustatus [uncharge $ens 1 $hashcode]
			} else {
				#pretty unfinished here
				if {$grossCharge != 0} {
					::ens uncharge $ens
					#set ustatus [uncharge $ens 1 $hashcode]
				}
				
			}
		}
	} 
	eval ens merge $splitEnsList
	set mergeHandle [lindex $splitEnsList 0]
	if {$mergeHandle != $ehandle} {
		ens copy $mergeHandle $ehandle
		ens delete $mergeHandle
	}
	return [expr $status || $ustatus || $hstatus]
}

proc ens::norm::tautomer {ehandle {maxens 1000} {timeout 0} {hashcode E_HASHY} {setcount 0} {usekekuleset 0} {restricted 0} {preservecoordinates 0} {crossNonStereoDoubleBonds 1} {deleteNonStereoAtoms 0}} {
	set status 0
	set crossStatus 0
	if {[ens atoms $ehandle !hydrogen count] <= 2} {
		return $status
	}
	set hash1 [ens get $ehandle $hashcode]
	ens purge $ehandle B_NCICADD_TAUTO_CROSSED
	set tautomers [ens::tautomer::createSet $ehandle $maxens $timeout $setcount $usekekuleset 0 $restricted $preservecoordinates]
	if {[llength $tautomers] > $maxens} {set ::cactvs(setsize_exceeded) 1}
	if {$crossNonStereoDoubleBonds} {
		ens::tautomer::crossPseudoStereoBonds $tautomers
	}
	if {$deleteNonStereoAtoms} {
		ens::tautomer::deletePseudoStereoAtoms $tautomers
	}
 	set canonicTautomer [ens::tautomer::canonic $tautomers 1 $hashcode]
	set hash2 [ens get $canonicTautomer $hashcode]
	if {$hash1 != $hash2 || [ens bonds $canonicTautomer tautocrossedbond bool]} {
		set status 1
	}
	ens purge $canonicTautomer E_KEKULESET
	ens purge $canonicTautomer A_MAPPING
	ens taint $canonicTautomer {atoms bonds}
	ens copy $canonicTautomer $ehandle
	ens delete $canonicTautomer
	return $status
}

proc ens::norm::singleMetalAtoms {ehandle} {
 	set status 0
	set isSingleMetalAtom [ens::test::singleMetalAtoms $ehandle]
	if {$isSingleMetalAtom} {
		foreach metal [ens atoms $ehandle metal] {
			::atom set $ehandle $metal A_FORMAL_CHARGE 0
			::atom new $ehandle $metal A_RADICAL
			set status 1
		}
	}
	return $status
}

proc ens::norm::singleHydrogenAtoms {ehandle} {
	set status 0
	set isSingleHydrogenAtom [ens::test::singleHydrogenAtoms $ehandle]
	if {$isSingleHydrogenAtom} {
		foreach hydrogen [ens atoms $ehandle hydrogen] {
			::atom set $ehandle $hydrogen A_FORMAL_CHARGE 0
			::atom new $ehandle $hydrogen A_RADICAL
			#atom hadd $ehandle $hydrogen
			set status 1
		}
	}
	return $status
}

proc ens::norm::singleHalogenAtoms {ehandle} {
 	set status 0
	set grossCharge [expr [regsub -all { } [ens get $ehandle A_FORMAL_CHARGE] {+}]]
	if {[ens atoms $ehandle halogen count] == [ens atoms $ehandle {} count] && [ens bonds $ehandle {} count] == 0 && $grossCharge == 0} {
		set atoms [ens atoms $ehandle]
		foreach atom $atoms {
			set newHalogenAtom [atom create $ehandle [atom get $ehandle $atom A_SYMBOL]]
			bond create $ehandle [list $newHalogenAtom $atom]
			set status 1
		}
	}
	return $status
}

proc ens::norm::grabLargestFragment {ehandle} {
 	set status 0
	set maxSize 0
	set maxHash 0
	if {[ens mols $ehandle] == 1} {return $status}
	set largestFragmentLabel -1
 	foreach molLabel [::ens mols $ehandle] molSize [::ens get $ehandle M_NATOMS] molHash [::ens get $ehandle M_HASHY] {
 		if {$molSize > $maxSize && [prop compare M_HASHY $molHash $maxHash]} {
			#ens delete $dupHandle
			set maxSize $molSize
			set maxHash $molHash
			set largestFragmentLabel $molLabel
 			set status 1
		}
	}
  	if {$status && $largestFragmentLabel != -1 } {
		foreach molLabel [::ens mols $ehandle] {
 			if {$molLabel != $largestFragmentLabel} {
 				mol delete $ehandle $molLabel
			}
  		}
	}
 	return $status
}

proc ens::norm::structure {ehandle operationOrder parameters parameterArgs postTrueCmds postFalseCmds debug} {
 	set globalErrorStatus 0
	set returnString {}
	array set parameterArray $parameters
	array set argListArray $parameterArgs
	array set statusArray [createDefaultParameterArray]
	array set postTrueCmdArray $postTrueCmds
	array set postFalseCmdArray $postFalseCmds
	set normStatusVector {}
	set normErrorVector {}
	set dhandle {}
	if {$debug} {set dhandle [dataset create]}
	foreach operation $operationOrder {
		set normCmd "ens::norm::$operation"
		set operationStatus($operation) 0
		set errorStatus($operation) 0
		set errorMsg($operation) {}
		set time0 [clock clicks -milliseconds]
		set ensList0 [llength [ens list]]
		if {$parameterArray($operation)} {
			set cmdMsg {}
			set cmdArgs $argListArray($operation)
			if {[llength $cmdArgs]} {
				set commandString "$normCmd $ehandle $cmdArgs"
			} else {
				set commandString "$normCmd $ehandle"
			}
			if {![catch {eval $commandString} cmdMsg]} {
				set cmdStatus $cmdMsg
				set postCmd {}
				set postCommandString {}
				if {$cmdStatus && [info exists postTrueCmdArray($operation)]} {
					set postCmd $postTrueCmdArray($operation)
					set postCommandString [list $postCmd $ehandle $parameters $parameterArgs]
				}
				if {!$cmdStatus && [info exists postFalseCmdArray($operation)]} {
					set postCmd $postFalseCmdArray($operation)
					set postCommandString [list $postCmd $ehandle $parameters $parameterArgs]
				}
				if {$postCommandString != ""} {
					set postStatus [catch {eval $postCommandString} postMsg]
				} else {
					set postMsg 0
					set postStatus 0
				}
				if {!$postStatus} {
					set operationStatus($operation) [expr $cmdStatus || $postMsg]
					set errorStatus($operation) 0
				} else {
					set operationStatus($operation) 0
					set errorStatus($operation) 1
					set errorMsg($operation) "error: post command failed: $postMsg"
					set globalErrorStatus 1
				}
			} else {
				set operationStatus($operation) 0
				set errorStatus($operation) 1
				set errorMsg($operation) "error: norm command failed: $cmdMsg"
				set globalErrorStatus 1
			}
			set normStatusVector $operationStatus($operation)$normStatusVector
			set normErrorVector $errorStatus($operation)$normErrorVector
			#puts $::w "\n-- [ens get $ehandle E_NAME] -- $normCmd $::cactvs(version) ------------------"
			#puts $::w [ens pack $ehandle]
			#puts $::w "$ensList0 --> [llength [ens list]]"
			#puts $::w $errorMsg($operation)
			#set w [molfile open xx-$normCmd.cbin w]
			#ens set $ehandle E_COMMENT $normCmd
			#molfile write $w $ehandle
			#molfile close $w 
			if {$debug} {
				set duphandle [ens dup $ehandle]
				ens set $duphandle E_IDENTIFIER_HANDLE $ehandle
				ens set $duphandle E_IDENTIFIER_NORM_CMD $normCmd
				ens set $duphandle E_COMMENT $normCmd
				ens set $duphandle E_IDENTIFIER_NORM_ARG $cmdArgs
				ens set $duphandle E_IDENTIFIER_NORM_PARAMETER $parameterArray($operation)
				ens set $duphandle E_IDENTIFIER_NORM_STATUS $operationStatus($operation)
				ens move $duphandle $dhandle
			}
		} else {
			set normStatusVector "0$normStatusVector"
			set normErrorVector "0$normErrorVector"
		}
		set time1 [clock clicks -milliseconds]
		set timeArray($operation) [expr $time1 - $time0]
	}
	set returnString [list \
		status [array get operationStatus] \
		errorstatus [array get errorStatus] \
		errormsg [array get errorMsg] \
		time [array get timeArray] \
		statusbitset $normStatusVector \
		errorbitset $normErrorVector \
		globalerror $globalErrorStatus \
	]
	if {$debug} {
		ens set $ehandle E_IDENTIFIER_NORM_DATASET $dhandle
		dataset delete $dhandle
		lappend returnString normdataset [ens show $ehandle E_IDENTIFIER_NORM_DATASET]
	}
	#puts $normStatusVector
	#puts $normErrorVector
	#ens set $ehandle E_NCICADD_NORM_STATUS_BITSET $normStatusVector
	#ens set $ehandle E_NCICADD_NORM_ERROR_BITSET $normErrorVector
	return $returnString
}

proc ens::identifier::grabMetadata {ehandle propertyList} {
	set metaString {}
	# grab all metadata
	foreach prop $propertyList {
		set metaString [concat $metaString [ens metadata $ehandle $prop]]
	}
	# merge identical metadata fields
	foreach {metaElement metaData} $metaString {
		if {[info exists metaArray($metaElement)]} {
			set metaArray($metaElement) [concat $metaArray($metaElement) $metaData]
		} else {
			set metaArray($metaElement) $metaData
		}
	}
	# return the array as a list
	return [array get metaArray]
}

proc ens::identifier::getFICTU {ehandle} {
	calc $ehandle FICTu
}

proc ens::identifier::getFICTS {ehandle} {
	calc $ehandle FICTS
}

proc ens::identifier::getFICUU {ehandle} {
	calc $ehandle FICuu
}

proc ens::identifier::getFICUS {ehandle} {
	calc $ehandle FICuS
}

proc ens::identifier::getUUUTU {ehandle} {
	calc $ehandle uuuTu
}

proc ens::identifier::getUUUTS {ehandle} {
	calc $ehandle uuuTS
}

proc ens::identifier::getUUUUU {ehandle} {
	calc $ehandle uuuuu
}

proc ens::identifier::getUUUUS {ehandle} {
	calc $ehandle uuuuS
}


proc ens::identifier::getFICXX {ehandle} {
	calc $ehandle FICxx
}

proc ens::identifier::getUUUXX {ehandle} {
	calc $ehandle uuuxx
}

proc ens::identifier::getNCICADD_PARENT {ehandle} {
	calc $ehandle ncicadd_parent
}

proc ens::identifier::purgeProps {ehandle identifierNames {purgeGeneralProps 0}} {
	switch $identifierNames {
		all {
			set identifierNames [getglobalparam names]
		}
	}
	foreach identifierName $identifierNames {
		set propertyName [getPropName $identifierName]
		set propertyStructureName [getStructurePropName $identifierName]
		catch {ens purge $ehandle $propertyStructureName}
		#The following catch is dirty, has to be removed
		catch {
			ens purge $ehandle E_IDENTIFIER_NORM_DATASET
			ens purge $ehandle E_NCICADD_TEST_STATUS_BITSET
			ens purge $ehandle E_NCICADD_TEST_ERROR_BITSET
			#ens purge $ehandle E_NCICADD_NORM_STATUS_BITSET
			#ens purge $ehandle E_NCICADD_NORM_ERROR_BITSET
		}
	}
	if {$purgeGeneralProps} {
		set propList [getglobalparam generalPurgeProps]
		foreach prop $propList {
			ens purge $ehandle $prop
		}
	}
	return $ehandle
}

proc ens::identifier::getNormExemptionList {ehandle identifierName exemptionListPropName} {
	set returnList {}
	set identifierName [normName $identifierName]
	set identifierPropName [getPropName $identifierName]
	if {[lsearch [ens properties $ehandle] $exemptionListPropName] != -1} { 
		set normExemptionList [ens get $ehandle $exemptionListPropName]
		foreach propExemption $normExemptionList {
			set prop [lindex $propExemption 0]
			set normPropName [normName $prop]
			if {[lsearch $normPropName $identifierPropName] != -1} {
				set operationExemptionList [lrange $propExemption 1 end]
				set returnList [concat $returnList $operationExemptionList]
			}
		}
	}
	return $returnList
}

proc ens::identifier::updateNormParameters {normArray switchStatusArray normExemptions} {	
	proparray::rdelete update
	proparray::rassign update norm $normArray
	proparray::rassign update switches $switchStatusArray
	set normParameters [proparray::rget update norm parameters]
 	set normParameters [ens::norm::createParameterArray $normParameters $normExemptions 0]
	set normBaseParameters [proparray::rget update norm baseparameters]
 	set normBaseParameters [ens::norm::createParameterArray $normBaseParameters $normExemptions 0]
 	proparray::rassign update norm parameters $normParameters
	proparray::rassign update norm baseparameters $normBaseParameters
 	proparray::rassign update switches 
	foreach name [proparray::names -onlychildnames update switches norm parameters] {
		set switchValue [proparray::get update switches norm parameters $name]
		set parameterValue [proparray::get update norm parameters $name]
 		if {[expr $switchValue * $parameterValue] && $switchValue < 0} {
			set parameterValue 0
		} else {
			set parameterValue [expr $parameterValue && 1]
		}
		proparray::assign -forceerrorifnotexists update norm parameters $name $parameterValue
 	}
	return [proparray::rget update norm]
}

proc ens::identifier::testStructure {ehandle testArray postArray debug} {	
 	proparray::rdelete teststructure
	proparray::rassign teststructure test $testArray
	proparray::rassign teststructure post $postArray 
	set order [proparray::get teststructure test order]
 	set testParameters [proparray::rget teststructure test parameters]
	set switches [proparray::rget teststructure post switches]
	set postTrueCmdArray [proparray::rget teststructure post cmds true]
	set postFalseCmdArray [proparray::rget teststructure post cmds false]
	set postTrueCmds {}
	set postFalseCmds {}
	foreach {parameter cmd} $postTrueCmdArray {
 		if {![proparray::get teststructure post parameters $parameter]} {continue}
		if {$cmd == ""} {continue}
 		lappend postTrueCmds $parameter [list ens::identifier::postcmd::test::true::$cmd $switches]
	}
	foreach {parameter cmd} $postFalseCmdArray {
 		if {![proparray::get teststructure post parameters $parameter]} {continue}
		if {$cmd == ""} {continue}
 		lappend postFalseCmds $parameter [list ens::identifier::postcmd::test::false::$cmd $switches]
	}
	array set testReturnArray [ens::test::structure $ehandle $order $testParameters $postTrueCmds $postFalseCmds $debug]
	array set errorMsgArray $testReturnArray(errormsg)
	array set switchStatusArray $testReturnArray(switchstatus)
	proparray::rdelete teststructure switchStatus
	proparray::rassign teststructure switchStatus global $switches
	foreach parameter $order {
		if {![info exists switchStatusArray($parameter)]} {continue}
		proparray::rassign teststructure switchStatus $parameter $switchStatusArray($parameter)
		foreach name [proparray::names -onlychildnames teststructure switchStatus $parameter] {
			set parameterValue [proparray::get teststructure switchStatus $parameter $name]
			if {$parameterValue != 0} {
				proparray::assign teststructure switchStatus global $name $parameterValue
			}
		}		
 	}
	foreach parameter [array names errorMsgArray] {
		set errorMsgArray($parameter) [proparray::sublist $errorMsgArray($parameter)]
	}
	array set returnArray [array get testReturnArray]
	set returnArray(errormsg) [array get errorMsgArray]
	set returnArray(globalswitchstatus) [proparray::rget teststructure switchStatus global]
	unset returnArray(switchstatus)
	return [array get returnArray]
}

proc ens::identifier::normStructure {ehandle normArray postArray debug} {
	proparray::rdelete normstructure
	proparray::rassign normstructure norm $normArray
	proparray::rassign normstructure post $postArray
	set order [proparray::get normstructure norm order]
	set normParameters [proparray::rget normstructure norm parameters]
 	set argList [proparray::rget -nosublists normstructure norm args]	
 	set postTrueCmdArray [proparray::rget normstructure post cmds true]
	set postFalseCmdArray [proparray::rget normstructure post cmds false]
	set postTrueCmds {}
	set postFalseCmds {}
	foreach {parameter cmd} $postTrueCmdArray {
		if {![proparray::get normstructure post parameters $parameter]} {continue}
		if {$cmd == ""} {continue}
		lappend postTrueCmds $parameter "ens::identifier::postcmd::norm::true::$cmd"
	}
	foreach {parameter cmd} $postFalseCmdArray {
		if {![proparray::get normstructure post parameters $parameter]} {continue}
		if {$cmd == ""} {continue}
		lappend postFalseCmds $parameter "ens::identifier::postcmd::norm::false::$cmd"
	}	
  	array set returnArray [ens::norm::structure $ehandle $order $normParameters $argList $postTrueCmds $postFalseCmds $debug]
	array set errorMsgArray $returnArray(errormsg)
	foreach parameter [array names errorMsgArray] {
		set errorMsgArray($parameter) [proparray::sublist $errorMsgArray($parameter)]
	}
	set returnArray(errormsg) [array get errorMsgArray]
	return [array get returnArray]
}

proc ens::identifier::trustBondStereochemistry {identifierName boolean} {
	set identifierName [normName $identifierName]
	set identifierPropName [getPropName $identifierName]
	array set trustatomcoord [prop get $identifierPropName parameters]
	array set norm $trustatomcoord(norm)
	array set args $norm(args)
	set stereo $args(stereo)
	#puts $stereo
	set stereo [lreplace $stereo 2 2 $boolean]
	set args(stereo) $stereo
	set norm(args) [array get args]
	set trustatomcoord(norm) [array get norm]
	prop set $identifierPropName parameters [array get trustatomcoord]
	return $boolean
}

proc ens::identifier::getTestNormBitSets {ehandle identifierName} {
	set propName [getPropName $identifierName]
	array set metadata [ens metadata $ehandle $propName info]
	array set normArray $metadata(norm)
	array set testArray $metadata(test)
	
	# dirty hack
	if {![info exists testArray(errorbitset)]} {set testArray(errorbitset) 0}
	if {![info exists testArray(statusbitset)]} {set testArray(statusbitset) 0}
	if {![info exists normArray(errorbitset)]} {set normArray(errorbitset) 0}
	if {![info exists normArray(statusbitset)]} {set normArray(statusbitset) 0}
	if {![info exists normArray(globalerror)]} {set normArray(globalerror) 0}
	
	set reliable [expr ![regexp "unreliable" [ens metadata $ehandle $propName flags]]]
	return [list $testArray(errorbitset) $testArray(statusbitset) $normArray(errorbitset) $normArray(statusbitset) $normArray(globalerror) $reliable]
} 

proc ens::identifier::calc {ehandle identifierName} {
  	set time0 [clock clicks -milliseconds]
	set status {}
	set testString {}
	set normString {}
	set failed 0
	set unreliable 0
	set identifierName [normName $identifierName]
	set identifierPropName [getPropName $identifierName]
	set identifierString {}
	set ::cactvs(setsize_exceeded) 0
	set ::cactvs(interrupted) 0
	#
	#set ::w [open /home/sitzmann/w.txt w]
	#puts $::w "\n\n-- $identifierName [ens get $ehandle E_NAME] ----\n"
	#cmdtrace on $::w
	#
	proparray::rdelete csbasehash
	proparray::rdelete identifier
	proparray::rdelete metadata
	#
	proparray::rassign identifier parameters [prop get $identifierPropName parameters]
	set debug [proparray::get identifier parameters debug]
	#
	# copying parameter of the identifier to corresponding parameter of the CACTVS base hash
	#
	set csBaseHash [proparray::get identifier parameters csbasehash]
	proparray::rassign csbasehash parameters [prop get $csBaseHash parameters]
	foreach {paramName paramValue} [proparray::rget csbasehash parameters] {
		set paramValue [proparray::get -forceemptystring identifier parameters $paramName]
		prop setparam $csBaseHash $paramName $paramValue
	}
	# needed for structures where stereochemistry is defined only by 3D
	# (withdrawn -seems to cause trouble somewhere else)
	# reactivated but now with catch
	catch {ens need $ehandle A_LABEL_STEREO}
	#
	# creating a copy of $ehandle in $calcStructure for structure manipulations
	# + doing some clean up of properties possibly set by previous calculations
	#
	set testStructure [ens dup $ehandle]
	set calcStructure [ens dup $ehandle]

	purgeProps $calcStructure all 1
	purgeProps $ehandle $identifierName 0
	#
	# testing the structure
	#
	set doTest [proparray::get identifier parameters test exec]
	if {$doTest} {
		set stereoArgs [proparray::get identifier parameters norm args stereo]
		eval ens::norm::stereo $testStructure $stereoArgs
		set testParameterArray [proparray::rget identifier parameters test]
		if {[proparray::get identifier parameters post test exec]} {
			set testPostArray [proparray::rget identifier parameters post test]
		} else {
			set testPostArray {}
		} 
		#cmdtrace on $::w
		#testStructure $ehandle $testParameterArray $testPostArray $debug
		if {![catch {testStructure $testStructure $testParameterArray $testPostArray $debug} testMetadata]} {
			proparray::rassign identifier metadata info test $testMetadata
			if {[proparray::get identifier metadata info test globalerror]} {
				set failed 1
			}
		} else {
			set errorMsg [proparray::sublist "error: $testMetadata"]
			proparray::rassign identifier metadata info test [list status "unknown" errormsg $errorMsg globalerror 1]
			set failed 1
		}
	}
	ens delete $testStructure
	if {[proparray::get identifier metadata info test globalswitchstatus norm exec] == -1} {
		proparray::assign identifier parameters norm exec 0
	}
	set doNorm [proparray::get identifier parameters norm exec]
	if {$doNorm} {	
		#
		# interface for switching on/off certain norm operations by file properties
		#
		set normParameterArray [proparray::rget identifier parameters norm]
		set normExemptionArray [getNormExemptionList $ehandle $identifierName E_IDENTIFIER_NORM_EXEMPTION_LIST]
		set switchStatusArray [proparray::rget identifier metadata info test globalswitchstatus]
		set normParameterArray [updateNormParameters $normParameterArray $switchStatusArray $normExemptionArray]
		if {[proparray::get identifier parameters post norm exec]} {
			set normPostArray [proparray::rget identifier parameters post norm]
		} else {
			set normPostArray {}
		}
		#normStructure $calcStructure $normParameterArray $normPostArray $debug
		if {![catch {normStructure $calcStructure $normParameterArray $normPostArray $debug} normMetadata]} {
			proparray::rassign identifier metadata info norm $normMetadata
			if {[proparray::get identifier metadata info norm globalerror]} {
				set failed 1
			}
		} else {
 			set errorMsg [proparray::sublist "error: $normMetadata"]
			proparray::rassign identifier metadata info norm [list status "unknown" errormsg $errorMsg globalerror 1]
			set failed 1
		}
	} else {
		proparray::rassign identifier metadata info norm status [ens::norm::createDefaultParameterArray]
	}
 	#cmdtrace on $::w
	ens taint $calcStructure [list A_HASH A_HASHS M_HASHY M_HASHSY]
	ens purge $calcStructure [list A_HASH A_HASHS M_HASHY M_HASHSY]
	#ens taint $calcStructure B_LABEL_STEREO
	#ens new $calcStructure B_LABEL_STEREO
	ens taint $calcStructure $csBaseHash
	ens purge $calcStructure $csBaseHash
	ens new $calcStructure $csBaseHash
	set hashcodeVal [ens show $calcStructure $csBaseHash]
	proparray::rassign csbasehash metadata [ens metadata $calcStructure $csBaseHash]
 	if {[proparray::get csbasehash metadata flags] != "none" || $::cactvs(interrupted)} {
		set failed 1
 	}
	if {[proparray::get identifier metadata info test globalswitchstatus unreliable] || $::cactvs(setsize_exceeded)} {
		set unreliable 1
 	}
	if {$unreliable && ([proparray::get identifier parameters forcemagic] || [proparray::get identifier metadata info test globalswitchstatus forcemagic])} {
		set failed 1
 	}
	if {$failed} {
		set hashcodeVal [prop get $identifierPropName magic]
 	}
 	set identifierString [getString $identifierName $hashcodeVal]
	ens set $calcStructure $identifierPropName $identifierString
	ens set $ehandle $identifierPropName $identifierString
	
	proparray::rassign identifier metadata info csbasehash [proparray::rget csbasehash metadata]
	set structurepropname [proparray::get identifier parameters structurepropname]
	ens set $ehandle $structurepropname $calcStructure
 	ens delete $calcStructure
	set time1 [clock clicks -milliseconds]
 	proparray::assign identifier metadata info time [expr $time1 - $time0]
	ens metadata $ehandle $identifierPropName info [proparray::rget identifier metadata info]
	if {$failed || $unreliable} {
		ens metadata $ehandle $identifierPropName flags unreliable
	}
	#flush $::w
	#close $::w
}
