; SPDX-License-Identifier: MIT

if !def(ARRAYS_INC)
def ARRAYS_INC equ 1

; The current version of this library is 1.2.
def ARRAYS_VERSION equs "1.2"

; Check whether this library version meets a minimum required one.
MACRO? check_arrays_inc_min_version ; <major>[.<minor>]
	pusho Q16
		if strfind("\1", ".") != -1
			def __min_ver equs "\1"
		else
			def __min_ver equs "\1.0"
		endc
		if {ARRAYS_VERSION} < {__min_ver}
			fail "arrays.inc version {ARRAYS_VERSION} is incompatible with minimum required version {__min_ver}"
		endc
	popo
	purge __min_ver
ENDM

; The base index for arrays.
; 0 by default, but 1 would match how RGBASM strings and macro arguments are indexed.
; Only modify this using `use_array_base`.
def _arrays_base = 0

; Set the base index for subsequent arrays.
; Typically 0 or 1, but higher non-negative bases are also technically valid.
MACRO? use_array_base ; <base>
	def _arrays_base = \1
	__check_non_negative_for_array _arrays_base, "Array base", use_array_base
ENDM

; Whether array items are constants (if 1) or variables (if 0).
; Array items are variable by default.
; Only modify this using `use_constant_arrays` or `use_variable_arrays`.
def _arrays_are_constant = 0

; Set subsequent arrays to have constant items (immutable, `equ`).
MACRO? use_constant_arrays
	def _arrays_are_constant = 1
ENDM

; Set subsequent arrays to have variable items (mutable, `=`).
MACRO? use_variable_arrays
	def _arrays_are_constant = 0
ENDM

; Causes assembly to fail if the specified value is negative.
; Meant for internal use.
MACRO? __check_non_negative_for_array ; <value> [, <value context>], <macro context>
	if (\1) < 0
		if _NARG == 3
			fail strfmt("\3: %s must not be negative: %d", \2, \1)
		else
			fail strfmt("\2: \1 must not be negative: %d", \1)
		endc
	endc
ENDM

; Causes assembly to fail if the specified array is not defined.
; Meant for internal use.
MACRO? __check_array_defined ; <name>, <macro context>
	if !def(\1#base) || !def(\1#len) || !def(\1#equ)
		fail "\2: Array \1 is not defined"
	endc
	__check_non_negative_for_array \1#base, \2
	__check_non_negative_for_array \1#len, \2
ENDM

; Causes assembly to fail if the specified array is already defined.
; Meant for internal use.
MACRO? __check_array_undefined ; <name>, <macro context>
	if def(\1#base) || def(\1#len) || def(\1#equ)
		fail "\2: Array \1 is already defined"
	endc
ENDM

; Causes assembly to fail if the specified array is empty.
; Meant for internal use.
MACRO? __check_array_nonempty ; <name>, <macro context>
	if !def(\1#base) || !def(\1#len) || !def(\1#equ)
		fail "\2: Array \1 is not defined"
	endc
	if \1#len == 0
		fail "\2: Array \1 is empty"
	endc
ENDM

; Causes assembly to fail if the specified array index is out of bounds.
; Meant for internal use.
MACRO? __check_array_index ; <name>, <index>, <macro context>
	if !(\1#base <= (\2) && (\2) < \1#base + \1#len)
		fail strfmt("\3: Invalid index for array \1: %d", \2)
	endc
ENDM

; Causes assembly to fail if the specified array position is out of bounds.
; (A position must be a valid index within the array, or an index 1 past the end of the array.)
; Meant for internal use.
MACRO? __check_array_pos ; <name>, <pos>, <macro context>
	if !(\1#base <= (\2) && (\2) <= \1#base + \1#len)
		fail strfmt("\3: Invalid position for array \1: %d", \2)
	endc
ENDM

; Initializes an array's metadata, though not its items.
; Meant for internal use.
MACRO? __init_array ; <name>, <length>, <macro context>
	__check_array_undefined \1, \3
	__check_non_negative_for_array \2, "Length", \3
	def \1#base equ _arrays_base
	def \1#len equ \2
	if _arrays_are_constant
		def \1#equ equs "equ"
	else
		def \1#equ equs "="
	endc
	redef def_array_item equs "array_append \1,"
ENDM

; Checks whether an array's contents have exactly the specified values.
MACRO? array_assert_equal ; <name>, <...values>
	__check_array_defined \1, array_assert_equal
	if \1#len != _NARG - 1
		fail strfmt("array_assert_equal: \1#len is %d, not %d", \1#len, _NARG - 1)
	endc
	def __start = \1#base - 2
	for? __argi, 2, _NARG + 1
		def __idx = __start + __argi
		if \1{__idx} != (\<__argi>)
			fail strfmt("array_assert_equal: \1{__idx} is %d, not %d", \1{__idx}, \<__argi>)
		endc
	endr
	def __idx = \1#base + \1#len
	if def(\1{__idx})
		warn strfmt("array_assert_equal: \1{__idx} is unexpectedly defined")
	endc
	purge __start, __argi, __idx
ENDM

; Defines a new array, initializing it with zero or more values.
; Redefines `def_array_item <...values>` to append values to this array.
MACRO? def_array ; <name>, <...values>
	__init_array \1, {_NARG} - 1, def_array
	def __start = \1#base - 2
	for? __argi, 2, _NARG + 1
		def __idx = __start + __argi
		redef \1{__idx} {\1#equ} \<__argi>
	endr
	purge __start, __argi
	if def(__idx)
		purge __idx
	endc
ENDM

; Defines a new array, initializing it to be filled with N of the same value,
; or with N zeros if the value is unspecified.
; Redefines `def_array_item <...values>` to append values to this array.
MACRO? def_array_fill ; <name>, <length> [, <value> = 0]
	__init_array \1, \2, def_array_fill
	if _NARG == 3
		def __val = \3
	else
		def __val = 0
	endc
	for? __idx, \1#base, \1#base + \1#len
		redef \1{__idx} {\1#equ} __val
	endr
	purge __val, __idx
ENDM

; Defines a new array, initializing it to be an arithmetic sequence.
; - `def_array_range <name>, <stop>`
;   gives the half-open interval [0, <stop>).
; - `def_array_range <name>, <start>, <stop>`
;   gives the half-open interval [<start>, <stop>).
; - `def_array_range <name>, <start>, <stop>, <step>`
;   gives the half-open interval [<start>, <stop>), skipping by <step>.
; Redefines `def_array_item <...values>` to append values to this array.
MACRO? def_array_range ; <name> [, <start> = 0], <stop> [, <step> = 1]
	if _NARG == 4
		def __start = \2
		def __stop = \3
		def __step = \4
	elif _NARG == 3
		def __start = \2
		def __stop = \3
		def __step = 1
	else
		def __start = 0
		def __stop = \2
		def __step = 1
	endc
	if __step == 0
		fail "def_array_range: Step must not be zero"
	endc
	if __step > 0 && __start < __stop
		def __len = (__stop - __start - 1) / __step + 1
	elif __step < 0 && __stop < __start
		def __len = (__start - __stop - 1) / -__step + 1
	else
		warn "def_array_range: \1 goes backwards from {d:__start} to {d:__stop} by {d:__step}"
		def __len = 0
	endc
	__init_array \1, __len, def_array_range
	def __val = __start
	for? __idx, \1#base, \1#base + \1#len
		redef \1{__idx} {\1#equ} __val
		def __val += __step
	endr
	purge __start, __stop, __step, __len, __val, __idx
ENDM

; Defines a new array as a copy of another array.
; Redefines `def_array_item <...values>` to append values to this array.
MACRO? def_array_copy ; <name>, <other>
	__check_array_defined \2, def_array_copy
	__init_array \1, \2#len, def_array_copy
	for? __idx, \2#base, \2#base + \2#len
		def __new = __idx + \1#base - \2#base
		redef \1{__new} {\1#equ} \2{__idx}
	endr
	purge __idx
	if def (__new)
		purge __new
	endc
ENDM

; Defines a new array as a concatenation of other arrays.
; Redefines `def_array_item <...values>` to append values to this array.
MACRO? def_array_concat ; <name>, <...others>
	def __len = 0
	for? __arr, 2, _NARG + 1
		__check_array_defined \<__arr>, def_array_concat
		def __len += \<__arr>#len
	endr
	__init_array \1, __len, def_array_concat
	def __num = \1#base
	for? __arr, 2, _NARG + 1
		for? __idx, \<__arr>#base, \<__arr>#base + \<__arr>#len
			def __new = __idx + __num - \<__arr>#base
			redef \1{__new} {\1#equ} \<__arr>{__idx}
		endr
		def __num += \<__arr>#len
	endr
	purge __len, __arr, __num
	if def(__idx)
		purge __idx
	endc
	if def(__new)
		purge __new
	endc
ENDM

; Defines a new array as a slice of another array starting at an index,
; and ending before a subsequent position if one is specified.
; Redefines `def_array_item <...values>` to append values to this array.
MACRO? def_array_slice ; <name>, <other>, <start index> [, <end pos>]
	__check_array_defined \2, def_array_slice
	def __start = \3
	__check_array_index \2, __start, def_array_slice
	if _NARG == 4
		def __end = \4
		__check_array_pos \2, __end, def_array_slice
	else
		def __end = \2#base + \2#len
	endc
	if __start > __end
		fail "def_array_slice: Invalid slice for array \2: [{d:__start}, {d:__end})"
	endc
	__init_array \1, __end - __start, def_array_slice
	for? __idx, __start, __end
		def __new = __idx + \2#base - __start
		redef \1{__new} {\1#equ} \2{__idx}
	endr
	purge __start, __end, __idx
	if def(__new)
		purge __new
	endc
ENDM

; Purges an array and all its items.
MACRO? array_purge ; <name>
	__check_array_defined \1, array_purge
	for? __idx, \1#base, \1#base + \1#len
		purge \1{__idx}
	endr
	purge \1#base, \1#len, \1#equ, __idx
ENDM

; Removes all items from an array, resetting its length to 0.
MACRO? array_clear ; <name>
	__check_array_defined \1, array_clear
	for? __idx, \1#base, \1#base + \1#len
		purge \1{__idx}
	endr
	redef \1#len equ 0
	purge __idx
ENDM

; Pads the end of an array up to a minimum length with a given value,
; or with 0 if the value is unspecified.
MACRO? array_pad ; <name>, <length> [, <value> = 0]
	__check_array_defined \1, array_pad
	def __len = \2
	if __len > \1#len
		if _NARG == 3
			def __val = \3
		else
			def __val = 0
		endc
		for? __idx, \1#base + \1#len, \1#base + __len
			redef \1{__idx} {\1#equ} __val
		endr
		redef \1#len equ __len
	endc
	purge __len
	if def (__val)
		purge __val, __idx
	endc
ENDM

; Pads the beginning of an array up to a minimum length with a given value,
; or with 0 if the value is unspecified.
MACRO? array_lpad ; <name>, <length> [, <value> = 0]
	__check_array_defined \1, array_lpad
	def __len = \2
	if __len > \1#len
		if _NARG == 3
			def __val = \3
		else
			def __val = 0
		endc
		def __off = __len - \1#len
		for? __idx, \1#base + \1#len - 1, \1#base - 1, -1
			def __new = __idx + __off
			redef \1{__new} {\1#equ} \1{__idx}
		endr
		for? __idx, \1#base, \1#base + __off
			redef \1{__idx} {\1#equ} __val
		endr
		redef \1#len equ __len
	endc
	purge __len
	if def (__val)
		purge __val, __off, __idx
		if def(__new)
			purge __new
		endc
	endc
ENDM

; Prints the items of an array, comma-separated between brackets.
MACRO? array_print ; <name>
	__check_array_defined \1, array_print
	print "["
	for? __idx, \1#base, \1#base + \1#len
		if __idx > \1#base
			print ", "
		endc
		print \1{__idx}
	endr
	print "]"
	purge __idx
ENDM

; Prints the items of an array, comma-separated between brackets,
; followed by a newline.
MACRO? array_println ; <name>
	__check_array_defined \1, array_println
	array_print \1
	println
ENDM

; Gets the value of an item in an array.
MACRO? array_get ; <result>, <name>, <index>
	__check_array_defined \2, array_get
	def __idx = \3
	__check_array_index \2, __idx, array_get
	def \1 = \2{__idx}
	purge __idx
ENDM

; Sets the value of an item in an array.
MACRO? array_set ; <name>, <index>, <value>
	__check_array_defined \1, array_set
	def __idx = \2
	__check_array_index \1, __idx, array_set
	redef \1{__idx} {\1#equ} \3
	purge __idx
ENDM

; Deletes an item from an array.
MACRO? array_delete ; <name>, <index>
	__check_array_defined \1, array_delete
	def __del = \2
	__check_array_index \1, __del, array_delete
	for? __new, __del, \1#base + \1#len - 1
		def __idx = __new + 1
		redef \1{__new} {\1#equ} \1{__idx}
	endr
	purge \1{__new}
	redef \1#len equ \1#len - 1
	purge __del, __new
	if def(__idx)
		purge __idx
	endc
ENDM

; Inserts zero or more values into an array at a given position.
MACRO? array_insert ; <name>, <index>, <...values>
	__check_array_defined \1, array_insert
	def __ins = \2
	__check_array_pos \1, __ins, array_insert
	for? __idx, \1#base + \1#len - 1, __ins - 1, -1
		def __new = __idx + _NARG - 2
		redef \1{__new} {\1#equ} \1{__idx}
	endr
	for? __argi, 3, _NARG + 1
		def __new = __ins + __argi - 3
		redef \1{__new} {\1#equ} \<__argi>
	endr
	redef \1#len equ \1#len + _NARG - 2
	purge __ins, __idx, __argi
	if def(__new)
		purge __new
	endc
ENDM

; Appends zero or more values to the end of an array.
MACRO? array_append ; <name>, <...values>
	__check_array_defined \1, array_append
	def __start = \1#base + \1#len
	for? __argi, 2, _NARG + 1
		def __idx = __start + __argi - 2
		redef \1{__idx} {\1#equ} \<__argi>
	endr
	redef \1#len equ \1#len + _NARG - 1
	purge __start, __argi
	if def(__idx)
		purge __idx
	endc
ENDM

; Prepends zero or more values to the beginning of an array.
MACRO? array_prepend ; <name>, <...values>
	__check_array_defined \1, array_prepend
	for? __idx, \1#base + \1#len - 1, \1#base - 1, -1
		def __new = __idx + _NARG - 1
		redef \1{__new} {\1#equ} \1{__idx}
	endr
	for? __argi, 2, _NARG + 1
		def __new = \1#base + __argi - 2
		redef \1{__new} {\1#equ} \<__argi>
	endr
	redef \1#len equ \1#len + _NARG - 1
	purge __idx, __argi
	if def(__new)
		purge __new
	endc
ENDM

; Pops the value from the end of a nonempty array.
MACRO? array_pop ; <result>, <name>
	__check_array_nonempty \2, array_pop
	def __idx = \2#base + \2#len - 1
	def \1 = \2{__idx}
	redef \2#len equ \2#len - 1
	purge \2{__idx}, __idx
ENDM

; Shifts the value from the beginning of a nonempty array.
MACRO? array_shift ; <result>, <name>
	__check_array_nonempty \2, array_shift
	def \1 = \2{\2#base}
	for? __idx, \2#base, \2#base + \2#len - 1
		def __old = __idx + 1
		redef \2{__idx} {\2#equ} \2{__old}
	endr
	redef \2#len equ \2#len - 1
	purge \2{__idx}, __idx
	if def(__old)
		purge __old
	endc
ENDM

; Extends an array by concatenating other arrays.
MACRO? array_extend ; <name>, <...others>
	__check_array_defined \1, array_extend
	for? __arr, 2, _NARG + 1
		__check_array_defined \<__arr>, array_extend
		for? __idx, \<__arr>#base, \<__arr>#base + \<__arr>#len
			def __new = __idx + \1#base + \1#len - \<__arr>#base
			redef \1{__new} {\1#equ} \<__arr>{__idx}
		endr
		redef \1#len equ \1#len + \<__arr>#len
	endr
	purge __arr
	if def(__idx)
		purge __idx
	endc
	if def(__new)
		purge __new
	endc
ENDM

; Redefines an array to be a slice of itself starting at an index,
; and ending before a subsequent position if one is specified.
MACRO? array_slice ; <name>, <start index> [, <end pos>]
	__check_array_defined \1, array_slice
	def __start = \2
	__check_array_index \1, __start, array_slice
	if _NARG == 3
		def __end = \3
		__check_array_pos \1, __end, array_slice
	else
		def __end = \1#base + \1#len
	endc
	if __start > __end
		fail "array_slice: Invalid slice for array \1: [{d:__start}, {d:__end})"
	endc
	for? __idx, __start, __end
		def __new = __idx + \1#base - __start
		redef \1{__new} {\1#equ} \1{__idx}
	endr
	for? __idx, __end + \1#base - __start, \1#base + \1#len
		purge \1{__idx}
	endr
	redef \1#len equ __end - __start
	purge __start, __end, __idx
	if def(__new)
		purge __new
	endc
ENDM

; Checks whether a value exists in an array,
; setting the result to 1 if it does or 0 if it does not.
MACRO? array_contains ; <result>, <name>, <value>
	__check_array_defined \2, array_find
	def \1 = 0
	def __val = \3
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} == __val
			def \1 = 1
			break
		endc
	endr
	purge __val, __idx
ENDM

; Find the first index of a value in an array,
; or base - 1 if the value is not in the array.
MACRO? array_find ; <result>, <name>, <value>
	__check_array_defined \2, array_find
	def \1 = \2#base - 1
	def __val = \3
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} == __val
			def \1 = __idx
			break
		endc
	endr
	purge __val, __idx
ENDM

; Find the last index of a value in an array,
; or base - 1 if the value is not in the array.
MACRO? array_rfind ; <result>, <name>, <value>
	__check_array_defined \2, array_rfind
	def \1 = \2#base - 1
	def __val = \3
	for? __idx, \2#base + \2#len - 1, \2#base - 1, -1
		if \2{__idx} == __val
			def \1 = __idx
			break
		endc
	endr
	purge __val, __idx
ENDM

; Count the occurrences of a value in an array.
MACRO? array_count ; <result>, <name>, <value>
	__check_array_defined \2, array_count
	def \1 = 0
	def __val = \3
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} == __val
			def \1 += 1
		endc
	endr
	purge __val, __idx
ENDM

; Replace the first N occurrences of one value in an array with another,
; or replace all of them if N is unspecified.
MACRO? array_replace ; <name>, <old>, <new> [, <limit>]
	__check_array_defined \1, array_replace
	def __old = \2
	def __new = \3
	if _NARG == 4
		def __limit = \4
		__check_non_negative_for_array __limit, "Limit", array_replace
	else
		def __limit = \1#len
	endc
	def __num = 0
	for? __idx, \1#base, \1#base + \1#len
		if \1{__idx} == __old && __num < __limit
			redef \1{__idx} {\1#equ} __new
			def __num += 1
			if __num == __limit
				break
			endc
		endc
	endr
	purge __old, __new, __limit, __num, __idx
ENDM

; Replace the last N occurrences of one value in an array with another,
; or replace all of them if N is unspecified.
MACRO? array_rreplace ; <name>, <old>, <new> [, <limit>]
	__check_array_defined \1, array_rreplace
	def __old = \2
	def __new = \3
	if _NARG == 4
		def __limit = \4
		__check_non_negative_for_array __limit, "Limit", array_rreplace
	else
		def __limit = \1#len
	endc
	def __num = 0
	for? __idx, \1#base + \1#len - 1, \1#base - 1, -1
		if \1{__idx} == __old && __num < __limit
			redef \1{__idx} {\1#equ} __new
			def __num += 1
			if __num == __limit
				break
			endc
		endc
	endr
	purge __old, __new, __limit, __num, __idx
ENDM

; Remove the first N occurrences of a value in an array,
; or remove all of them if N is unspecified.
MACRO? array_remove ; <name>, <value> [, <limit>]
	__check_array_defined \1, array_remove
	def __val = \2
	if _NARG == 3
		def __limit = \3
		__check_non_negative_for_array __limit, "Limit", array_remove
	else
		def __limit = \1#len
	endc
	def __num = 0
	for? __idx, \1#base, \1#base + \1#len
		if \1{__idx} == __val && __num < __limit
			def __num += 1
		elif __num > 0
			def __new = __idx - __num
			redef \1{__new} {\1#equ} \1{__idx}
		endc
	endr
	for? __idx, \1#base + \1#len - __num, \1#base + \1#len
		purge \1{__idx}
	endr
	redef \1#len equ \1#len - __num
	purge __val, __limit, __num, __idx
	if def(__new)
		purge __new
	endc
ENDM

; Remove the last N occurrences of a value in an array,
; or remove all of them if N is unspecified.
MACRO? array_rremove ; <name>, <value> [, <limit>]
	__check_array_defined \1, array_rremove
	def __val = \2
	if _NARG == 3
		def __limit = \3
		__check_non_negative_for_array __limit, "Limit", array_rremove
	else
		def __limit = \1#len
	endc
	def __num = 0
	for? __idx, \1#base + \1#len - 1, \1#base - 1, -1
		if \1{__idx} == __val && __num < __limit
			for? __new, __idx, \1#base + \1#len - 1
				def __del = __new + 1
				redef \1{__new} {\1#equ} \1{__del}
			endr
			purge \1{__new}
			redef \1#len equ \1#len - 1
			def __num += 1
			if __num == __limit
				break
			endc
		endc
	endr
	purge __val, __limit, __num, __idx
	if def(__new)
		purge __new
	endc
	if def(__del)
		purge __del
	endc
ENDM

; Reverses an array.
MACRO? array_reverse ; <name>
	__check_array_defined \1, array_reverse
	for? __off, \1#len / 2
		def __i = \1#base + __off
		def __j = \1#base + \1#len - __off - 1
		def __tmp = \1{__i}
		redef \1{__i} {\1#equ} \1{__j}
		redef \1{__j} {\1#equ} __tmp
	endr
	purge __off
	if def(__i)
		purge __i, __j, __tmp
	endc
ENDM

; Reverses a slice of an array.
; Meant for internal use in `array_rotate`.
MACRO? _reverse_array_slice ; <name>, <start>, <end>
	def __start = \2
	def __end = \3
	rept? (__end - __start + 1) / 2
		def __tmp = \1{__start}
		redef \1{__start} {\1#equ} \1{__end}
		redef \1{__end} {\1#equ} __tmp
		def __start += 1
		def __end -= 1
	endr
	purge __start, __end
	if def(__tmp)
		purge __tmp
	endc
ENDM

; Rotates an array right by a positive amount,
; or left by a negative amount.
MACRO? array_rotate ; <name>, <amount>
	__check_array_defined \1, array_rotate
	if \1#len > 0
		def __num = \2
		if __num > 0
			def __k = __num % \1#len
			_reverse_array_slice \1, \1#base, \1#base + \1#len - 1
			_reverse_array_slice \1, \1#base, \1#base + __k - 1
			_reverse_array_slice \1, \1#base + __k, \1#base + \1#len - 1
		elif __num < 0
			def __num = -__num
			def __k = __num % \1#len
			_reverse_array_slice \1, \1#base, \1#base + __k - 1
			_reverse_array_slice \1, \1#base + __k, \1#base + \1#len - 1
			_reverse_array_slice \1, \1#base, \1#base + \1#len - 1
		endc
		purge __num
		if def(__k)
			purge __k
		endc
	endc
ENDM

; Sorts an array by a comparison operator.
; Uses a bottom-up merge sort algorithm.
; Meant for internal use.
MACRO? __sort_array ; <name>, <operator>, <macro context>
	__check_array_defined \1, \3
	def __cap = \1#base + \1#len
	def __max = 0
	for? __p, 1, 32
		if \1#len >= 1 << __p
			def __max += 1
		endc
	endr
	for? __p, __max
		def __w = 2 ** __p
		for? __i, \1#base, __cap, 2 * __w
			if __i + __w >= __cap
				break
			endc
			def __l1 = __i
			def __r1 = __l1 + __w - 1
			def __l2 = __r1 + 1
			def __r2 = __l2 + __w - 1
			if __r2 >= __cap
				def __r2 = __cap - 1
			endc
			for? __t, \1#len
				if __l1 > __r1 || __l2 > __r2
					break
				endc
				if \1{__l1} \2 \1{__l2}
					def __tmp{u:__t} = \1{__l1}
					def __l1 += 1
				else
					def __tmp{u:__t} = \1{__l2}
					def __l2 += 1
				endc
			endr
			for? __j, __l1, __r1 + 1
				def __tmp{u:__t} = \1{__j}
				def __t += 1
			endr
			for? __j, __l2, __r2 + 1
				def __tmp{u:__t} = \1{__j}
				def __t += 1
			endr
			for? __j, __t
				def __k = __i + __j
				redef \1{__k} {\1#equ} __tmp{u:__j}
				purge __tmp{u:__j}
			endr
		endr
	endr
	purge __cap, __p, __max
	if def(__w)
		purge __w, __i
		if def(__l1)
			purge __l1, __r1, __l2, __r2, __t, __j, __k
		endc
	endc
ENDM

; Sorts an array in order from least to greatest.
; Uses an O(n log n) in-place merge sort algorithm.
MACRO? array_sort ; <name>
	__sort_array \1, <=, array_sort
ENDM

; Sorts an array in order from greatest to least.
; Uses an O(n log n) in-place merge sort algorithm.
MACRO? array_rsort ; <name>
	__sort_array \1, >=, array_rsort
ENDM

; Checks whether an array is sorted from least to greatest,
; setting the result to 1 if it is or 0 if it is not.
MACRO? array_is_sorted ; <result>, <name>
	__check_array_defined \2, array_is_sorted
	def \1 = 1
	if \2#len > 1
		def __prev = \2{\2#base}
		for? __idx, \2#base + 1, \2#base + \2#len
			if \2{__idx} < __prev
				def \1 = 0
				break
			endc
			def __prev = \2{__idx}
		endr
	endc
	if def(__prev)
		purge __prev, __idx
	endc
ENDM

; Checks whether an array is sorted from greatest to least,
; setting the result to 1 if it is or 0 if it is not.
MACRO? array_is_rsorted ; <result>, <name>
	__check_array_defined \2, array_is_rsorted
	def \1 = 1
	if \2#len > 1
		def __prev = \2{\2#base}
		for? __idx, \2#base + 1, \2#base + \2#len
			if \2{__idx} > __prev
				def \1 = 0
				break
			endc
			def __prev = \2{__idx}
		endr
	endc
	if def(__prev)
		purge __prev, __idx
	endc
ENDM

; The pseudorandom number generator (PRNG) state
; for shuffling and picking from arrays.
; Only modify this using `array_reseed`.
def _arrays_prng = ((((__UTC_SECOND__ * 60 + __UTC_MINUTE__) * 60 + __UTC_HOUR__) * 24 + \
                     __UTC_DAY__ - 1) * 31 + __UTC_MONTH__ - 1) * 12 + __UTC_YEAR__ % 100

; Reseed the xorshift32 PRNG used in randomized array macros
; (array_shuffle and array_pick).
MACRO? array_reseed ; <seed>
	def _arrays_prng = \1
ENDM

; Generate the next PRNG value.
; Uses an xorshift32 algorithm.
; Meant for internal use.
MACRO? __next_array_prng
	def _arrays_prng ^= _arrays_prng << 13
	def _arrays_prng ^= _arrays_prng >>> 17
	def _arrays_prng ^= _arrays_prng << 5
ENDM

; Randomly shuffle an array.
; Uses the O(n) Fisher-Yates aka Knuth algorithm.
MACRO? array_shuffle ; <name>
	__check_array_defined \1, array_shuffle
	if \1#len > 0
		for? __i, \1#len - 1, 0, -1
			__next_array_prng
			def __j = \1#base + _arrays_prng % (__i + 1)
			def __i += \1#base
			def __tmp = \1{__i}
			redef \1{__i} {\1#equ} \1{__j}
			redef \1{__j} {\1#equ} __tmp
		endr
		purge __i
		if def(__j)
			purge __j, __tmp
		endc
	endc
ENDM

; Randomly pick an item from a nonempty array.
MACRO? array_pick ; <result>, <name>
	__check_array_nonempty \2, array_pick
	__next_array_prng
	def __idx = \2#base + _arrays_prng % \2#len
	def \1 = \2{__idx}
	purge __idx
ENDM

; Deduplicates an array by reducing runs of the same value to one item.
MACRO? array_dedup ; <name>
	__check_array_defined \1, array_dedup
	if \1#len > 1
		def __num = 0
		for? __idx, \1#base + 1, \1#base + \1#len
			def __old = __idx - __num - 1
			if \1{__idx} == \1{__old}
				def __num += 1
			elif __num > 0
				def __new = __idx - __num
				redef \1{__new} {\1#equ} \1{__idx}
			endc
		endr
		for? __idx, \1#base + \1#len - __num, \1#base + \1#len
			purge \1{__idx}
		endr
		redef \1#len equ \1#len - __num
		purge __num, __idx
		if def(__old)
			purge __old
			if def(__new)
				purge __new
			endc
		endc
	endc
ENDM

; Removes all duplicate items in an array,
; leaving only one item per unique value.
MACRO? array_unique ; <name>
	__check_array_defined \1, array_unique
	if \1#len > 1
		def __num = 0
		for? __idx, \1#base + 1, \1#base + \1#len
			def __dup = 0
			for? __pre, \1#base, __idx
				if \1{__pre} == \1{__idx}
					def __dup = 1
					break
				endc
			endr
			if __dup
				def __num += 1
			elif __num > 0
				def __new = __idx - __num
				redef \1{__new} {\1#equ} \1{__idx}
			endc
		endr
		for? __idx, \1#base + \1#len - __num, \1#base + \1#len
			purge \1{__idx}
		endr
		redef \1#len equ \1#len - __num
		purge __num, __idx
		if def(__dup)
			purge __dup, __pre
		endc
		if def(__new)
			purge __new
		endc
	endc
ENDM

; Checks whether all the values in an array are equal,
; setting the result to 1 if they are or 0 if they are not.
MACRO? array_are_all_equal ; <result>, <name>
	__check_array_defined \2, array_are_all_equal
	def \1 = 1
	if \2#len > 1
		def __val = \2{\2#base}
		for? __idx, \2#base + 1, \2#base + \2#len
			if \2{__idx} != __val
				def \1 = 0
				break
			endc
		endr
	endc
	if def (__val)
		purge __val, __idx
	endc
ENDM

; Checks whether all the values in an array are unique,
; setting the result to 1 if they are or 0 if they are not.
MACRO? array_are_all_unique ; <result>, <name>
	__check_array_defined \2, array_are_all_unique
	def \1 = 1
	if \2#len > 1
		for? __i, \2#base, \2#base + \2#len
			for? __j, __i + 1, \2#base + \2#len
				if \2{__i} == \2{__j}
					def \1 = 0
					break
				endc
			endr
			if !\1
				break
			endc
		endr
	endc
	if def(__i)
		purge __i, __j
	endc
ENDM

; Find the minimum value in a nonempty array.
MACRO? array_min ; <result>, <name>
	__check_array_nonempty \2, array_min
	def \1 = \2{\2#base}
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} < \1
			def \1 = \2{__idx}
		endc
	endr
	if def(__idx)
		purge __idx
	endc
ENDM

; Find the maximum value in a nonempty array.
MACRO? array_max ; <result>, <name>
	__check_array_nonempty \2, array_max
	def \1 = \2{\2#base}
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} > \1
			def \1 = \2{__idx}
		endc
	endr
	if def(__idx)
		purge __idx
	endc
ENDM

; Find the index of a minimum value in a nonempty array.
MACRO? array_argmin ; <result>, <name>
	__check_array_nonempty \2, array_argmin
	def \1 = \2#base
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} < \2{\1}
			def \1 = __idx
		endc
	endr
	if def(__idx)
		purge __idx
	endc
ENDM

; Find the index of a maximum value in a nonempty array.
MACRO? array_argmax ; <result>, <name>
	__check_array_nonempty \2, array_argmax
	def \1 = \2#base
	for? __idx, \2#base, \2#base + \2#len
		if \2{__idx} > \2{\1}
			def \1 = __idx
		endc
	endr
	if def(__idx)
		purge __idx
	endc
ENDM

; Find the sum of values in an array,
; or 0 if the array is empty.
MACRO? array_sum ; <result>, <name>
	__check_array_defined \2, array_sum
	def \1 = 0
	for? __idx, \2#base, \2#base + \2#len
		def \1 += \2{__idx}
	endr
	if def(__idx)
		purge __idx
	endc
ENDM

; Find the product of values in an array,
; or 1 if the array is empty.
MACRO? array_product ; <result>, <name>
	__check_array_defined \2, array_product
	def \1 = 1
	for? __idx, \2#base, \2#base + \2#len
		def \1 *= \2{__idx}
	endr
	if def(__idx)
		purge __idx
	endc
ENDM

; Find the mean (average) of values in a nonempty array.
MACRO? array_mean ; <result>, <name>
	__check_array_nonempty \2, array_mean
	def \1 = 0
	for? __idx, \2#base, \2#base + \2#len
		def \1 += \2{__idx}
	endr
	def \1 /= \2#len
	if def(__idx)
		purge __idx
	endc
ENDM

endc ; ARRAYS_INC
