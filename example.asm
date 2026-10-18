; SPDX-License-Identifier: MIT

INCLUDE "arrays.inc"

; check_arrays_inc_min_version <major>[.<minor>]
; Check whether this library version meets a minimum required one.
check_arrays_inc_min_version 1
check_arrays_inc_min_version 1.4

; Verify the expected default configuration.
static_assert _arrays_base == 0 && _arrays_are_constant == 0

; use_array_base <base>
; Set the base index for subsequently defined arrays.
; Typically 0 or 1, but higher non-negative bases are also technically valid.
use_array_base 42
static_assert _arrays_base == 42

; use_variable_arrays
; Set subsequently defined arrays to have variable items (mutable, `=`).
use_variable_arrays
static_assert !_arrays_are_constant

; use_constant_arrays
; Set subsequently defined arrays to have constant items (immutable, `equ`).
use_constant_arrays
static_assert _arrays_are_constant == 1

; use_string_arrays
; Set subsequently defined arrays to have string items (immutable, `equs`).
; String arrays are not compatible with functions that require numeric items
; (`def_array_range`, `array_product`, and `array_mean`),
; but are uniquely compatible with functions that require string items
; (`array_join`).
use_string_arrays
static_assert _arrays_are_constant == 2


; ==============================================================================
; Variable arrays, with base index 0 (the default configuration)
; ==============================================================================
use_array_base 0
use_variable_arrays

; def_array <name>, <...values>
; Defines a new array, initializing it with zero or more values.
; Redefines `def_array_item <...values>` to append values to this array.

; array_assert_equal <name>, <...values>
; Asserts that an array's contents have exactly the specified values.

def_array empty
array_assert_equal empty,
static_assert empty#len == 0

def_array primes, 1, 3, 5, 7, 11, 13, 17, 19
array_assert_equal primes, 1, 3, 5, 7, 11, 13, 17, 19
static_assert primes#len == 8
static_assert primes$0 == 1
static_assert primes$7 == 19
def primes$0 = 2 ; Since arrays are variable.
static_assert primes$0 == 2

def_array odds
def_array_item 1
def_array_item 3
def_array_item 5
def_array_item 7
def_array_item 9
array_assert_equal odds, 1, 3, 5, 7, 9
static_assert odds#len == 5
static_assert odds$0 == 1
static_assert odds$4 == 9

; def_array_fill <name>, <length> [, <value> = 0/""]
; Defines a new array, initializing it to be filled with N of the same value,
; or with N zeros (or empty strings for string arrays) if the value is unspecified.
; Redefines `def_array_item <...values>` to append values to this array.

def_array_fill zeros, 4
array_assert_equal zeros, 0, 0, 0, 0

def_array_fill fives, 10, 5
array_assert_equal fives, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

; def_array_range <name> [, <start> = 0], <stop> [, <step> = 1]
; Defines a new array, initializing it to be an arithmetic sequence.
; - `def_array_range <name>, <stop>`
;   gives the half-open interval [0, <stop>).
; - `def_array_range <name>, <start>, <stop>`
;   gives the half-open interval [<start>, <stop>).
; - `def_array_range <name>, <start>, <stop>, <step>`
;   gives the half-open interval [<start>, <stop>), skipping by <step>.
; Redefines `def_array_item <...values>` to append values to this array.
; Not compatible with string arrays.

def_array_range naturals, 10
array_assert_equal naturals, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9

def_array_range positives, 1, 10
array_assert_equal positives, 1, 2, 3, 4, 5, 6, 7, 8, 9

def_array_range countdown, 10, -1, -1
array_assert_equal countdown, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0
static_assert countdown#len == 11
static_assert countdown$0 == 10
static_assert countdown$A == 0

def_array_range empty_range, 5, 5 ; This should print a warning.
static_assert empty_range#len == 0

def_array_range backwards, 1, 5, -1 ; This should print a warning.
static_assert backwards#len == 0

; def_array_copy <name>, <other>
; Defines a new array as a copy of another array.
; Redefines `def_array_item <...values>` to append values to this array.
def_array_copy copied, primes
array_assert_equal copied, 2, 3, 5, 7, 11, 13, 17, 19
static_assert copied#len == primes#len
static_assert copied$0 == primes$0
static_assert copied$5 == primes$5

; def_array_concat <name>, <...others>
; Defines a new array as a concatenation of other arrays.
; Redefines `def_array_item <...values>` to append values to this array.
def_array_concat concatenated, primes, positives
array_assert_equal concatenated, 2, 3, 5, 7, 11, 13, 17, 19, 1, 2, 3, 4, 5, 6, 7, 8, 9
static_assert concatenated#len == primes#len + positives#len
def_array_concat concatenated_none,
array_assert_equal concatenated_none,
static_assert concatenated_none#len == 0

; def_array_slice <name>, <other>, <start pos> [, <end pos>]
; Defines a new array as a slice of another array starting at a position,
; and ending before a subsequent position if one is specified.
; Redefines `def_array_item <...values>` to append values to this array.
def_array_slice sliced_primes, primes, 3
array_assert_equal sliced_primes, 7, 11, 13, 17, 19
def_array_slice sliced_concatenated, concatenated, 4, 12
array_assert_equal sliced_concatenated, 11, 13, 17, 19, 1, 2, 3, 4
def_array_slice sliced_empty, naturals, 9, 9
array_assert_equal sliced_empty,
def_array_slice sliced_end, naturals, naturals#base + naturals#len
array_assert_equal sliced_end,

; array_purge <...names>
; Purges an array and all its items.
array_purge copied
static_assert !def(copied#len)
static_assert !def(copied$0)
static_assert !def(copied$5)

pushs "array_db/dw/dl", ROM0 ; Only necessary for testing `array_db/dw/dl`.

; array_db <name>
; Declares a `db` byte for each item of an array.
: array_db empty
static_assert @ - :- == empty#len
: array_db primes
static_assert @ - :- == primes#len

; array_dw <name>
; Declares a `dw` word for each item of an array.
: array_dw empty
static_assert @ - :- == empty#len * 2
: array_dw primes
static_assert @ - :- == primes#len * 2

; array_dl <name>
; Declares a `dl` long for each item of an array.
: array_dl empty
static_assert @ - :- == empty#len * 4
: array_dl primes
static_assert @ - :- == primes#len * 4

pops

; array_clear <name>
; Removes all items from an array, resetting its length to 0.
array_clear odds
array_assert_equal odds, ; Empty.
static_assert odds#len == 0
static_assert !def(odds$0)

; array_pad <name>, <length> [, <value> = 0/""]
; Pads the end of an array up to a minimum length with a given value,
; or with zeros (or empty strings for string arrays) if the value is unspecified.
array_pad primes, 5
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19 ; Unchanged.
array_pad primes, 9
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 0
array_pad primes, 12, 257
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257

; array_lpad <name>, <length> [, <value> = 0/""]
; Pads the beginning of an array up to a minimum length with a given value,
; or with zeros (or empty strings for string arrays) if the value is unspecified.
array_lpad primes, 10
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257 ; Unchanged.
array_lpad primes, 14
array_assert_equal primes, 0, 0, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257
array_lpad primes, 16, 1
array_assert_equal primes, 1, 1, 0, 0, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257

; array_print <name>
; Prints the items of an array, comma-separated between brackets.
print "Countdown: T-minus "
array_print countdown
println "... liftoff!"

; array_println <name>
; Prints the items of an array, comma-separated between brackets,
; followed by a newline.
print "Empty: "
array_println empty

; array_get <result>, <name>, <index>
; Gets the value of an item in an array.
array_get prime_11, primes, 11
static_assert prime_11 == primes$B

; array_set <name>, <index>, <value>
; Sets the value of an item in an array.
array_set primes, 12, 23
array_set primes, 13, 29
array_set primes, 14, 31
array_set primes, 15, 37
array_assert_equal primes, 1, 1, 0, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37

; array_delete <name>, <index>
; Deletes an item from an array.
array_delete primes, 2
array_assert_equal primes, 1, 1, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_delete primes, 1
array_assert_equal primes, 1, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_delete primes, 0
array_assert_equal primes, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_delete primes, 0
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37

; array_insert <name>, <index>, <...values>
; Inserts zero or more values into an array at a given position.
array_insert odds, 0, 3
array_assert_equal odds, 3
array_insert odds, 0, 1
array_assert_equal odds, 1, 3
array_insert odds, 2, 5, 7
array_assert_equal odds, 1, 3, 5, 7
array_insert odds, 2,
array_assert_equal odds, 1, 3, 5, 7 ; Unchanged.

; array_append <name>, <...values>
; Appends zero or more values to the end of an array.
; Also known as `array_push`.
array_append odds, 9
array_assert_equal odds, 1, 3, 5, 7, 9
array_push odds,
array_assert_equal odds, 1, 3, 5, 7, 9 ; Unchanged.

; array_prepend <name>, <...values>
; Prepends zero or more values to the beginning of an array.
; Also known as `array_unshift`.
array_prepend odds, -1
array_assert_equal odds, -1, 1, 3, 5, 7, 9
array_unshift odds,
array_assert_equal odds, -1, 1, 3, 5, 7, 9 ; Unchanged.

; array_pop <result>, <name>
; Pops the value from the end of a nonempty array.
def_array_range evens, 2, 13, 2
array_assert_equal evens, 2, 4, 6, 8, 10, 12
array_pop element, evens
static_assert element == 12
array_assert_equal evens, 2, 4, 6, 8, 10
array_pop element, evens
static_assert element == 10
array_assert_equal evens, 2, 4, 6, 8

; array_shift <result>, <name>
; Shifts the value from the beginning of a nonempty array.
array_assert_equal evens, 2, 4, 6, 8
array_shift element, evens
static_assert element == 2
array_assert_equal evens, 4, 6, 8
array_shift element, evens
static_assert element == 4
array_assert_equal evens, 6, 8

; array_extend <name>, <...others>
; Extends an array by concatenating other arrays.
array_extend odds, empty, empty, empty
array_assert_equal odds, -1, 1, 3, 5, 7, 9 ; Unchanged.
array_extend primes,
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37 ; Unchanged.
array_extend primes, zeros
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 0, 0, 0, 0
static_assert primes#len == 12 + zeros#len
static_assert primes$C == zeros$0
static_assert primes$D == zeros$1
static_assert primes$E == zeros$2
static_assert primes$F == zeros$3

; array_slice <name>, <start pos> [, <end pos>]
; Slices an array to start at a specified position,
; and end before a subsequent position if one is specified.
array_slice odds, 2
array_assert_equal odds, 3, 5, 7, 9
array_slice odds, odds#base, odds#base + odds#len
array_assert_equal odds, 3, 5, 7, 9 ; Unchanged.
array_slice primes, 0, 12
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_slice empty, 0
array_assert_equal empty, ; Unchanged.

; array_contains <result>, <name>, <value>
; Checks whether a value exists in an array,
; setting the result to 1 if it does or 0 if it does not.
array_contains result, empty, 42
static_assert result == 0
array_contains result, primes, 37
static_assert result == 1
array_contains result, primes, 57
static_assert result == 0

; array_find <result>, <name>, <value>
; Find the first index of a value in an array,
; or base - 1 if the value is not in the array.
array_find index, empty, 42
static_assert index == empty#base - 1
array_find index, fives, 5
static_assert index == 0
array_find index, primes, 37
static_assert index == 11

; array_rfind <result>, <name>, <value>
; Find the last index of a value in an array,
; or base - 1 if the value is not in the array.
array_rfind index, empty, 42
static_assert index == empty#base - 1
array_rfind index, fives, 5
static_assert index == 9
array_rfind index, primes, 37
static_assert index == 11

; array_count <result>, <name>, <value>
; Count the occurrences of a value in an array.
array_count result, empty, 42
static_assert result == 0
array_count result, fives, 5
static_assert result == 10
array_count result, primes, 37
static_assert result == 1

; array_replace <name>, <old>, <new> [, <limit>]
; Replace the first N occurrences of one value in an array with another,
; or replace all of them if N is unspecified.
def_array replacing, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert replacing#len == 14
array_replace replacing, 4, 5
array_assert_equal replacing, 1, 1, 2, 2, 3, 3, 5, 5, 3, 3, 2, 2, 1, 1
array_replace replacing, 2, 6, 3
array_assert_equal replacing, 1, 1, 6, 6, 3, 3, 5, 5, 3, 3, 6, 2, 1, 1
array_replace replacing, 9, 1
array_assert_equal replacing, 1, 1, 6, 6, 3, 3, 5, 5, 3, 3, 6, 2, 1, 1 ; Unchanged.
array_replace replacing, 3, 42, 0
array_assert_equal replacing, 1, 1, 6, 6, 3, 3, 5, 5, 3, 3, 6, 2, 1, 1 ; Unchanged.
array_replace empty, 42, 99
array_assert_equal empty, ; Unchanged.

; array_rreplace <name>, <old>, <new> [, <limit>]
; Replace the last N occurrences of one value in an array with another,
; or replace all of them if N is unspecified.
def_array rreplacing, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert rreplacing#len == 14
array_rreplace rreplacing, 4, 5
array_assert_equal rreplacing, 1, 1, 2, 2, 3, 3, 5, 5, 3, 3, 2, 2, 1, 1
array_rreplace rreplacing, 2, 6, 3
array_assert_equal rreplacing, 1, 1, 2, 6, 3, 3, 5, 5, 3, 3, 6, 6, 1, 1
array_rreplace rreplacing, 9, 1
array_assert_equal rreplacing, 1, 1, 2, 6, 3, 3, 5, 5, 3, 3, 6, 6, 1, 1 ; Unchanged.
array_rreplace rreplacing, 3, 42, 0
array_assert_equal rreplacing, 1, 1, 2, 6, 3, 3, 5, 5, 3, 3, 6, 6, 1, 1 ; Unchanged.
array_rreplace empty, 42, 99
array_assert_equal empty, ; Unchanged.

; array_remove <name>, <value> [, <limit>]
; Remove the first N occurrences of a value in an array,
; or remove all of them if N is unspecified.
def_array removing, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert removing#len == 14
array_remove removing, 4
array_assert_equal removing, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 1, 1
array_contains result, removing, 4
static_assert result == 0
array_remove removing, 2, 3
array_assert_equal removing, 1, 1, 3, 3, 3, 3, 2, 1, 1
array_remove removing, 9
array_assert_equal removing, 1, 1, 3, 3, 3, 3, 2, 1, 1 ; Unchanged.
array_remove removing, 3, 0
array_assert_equal removing, 1, 1, 3, 3, 3, 3, 2, 1, 1 ; Unchanged.
array_remove empty, 42
array_assert_equal empty, ; Unchanged.

; array_rremove <name>, <value> [, <limit>]
; Remove the last N occurrences of a value in an array,
; or remove all of them if N is unspecified.
def_array rremoving, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert rremoving#len == 14
array_rremove rremoving, 4
array_assert_equal rremoving, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 1, 1
array_contains result, rremoving, 4
static_assert result == 0
array_rremove rremoving, 2, 3
array_assert_equal rremoving, 1, 1, 2, 3, 3, 3, 3, 1, 1
array_rremove rremoving, 9
array_assert_equal rremoving, 1, 1, 2, 3, 3, 3, 3, 1, 1 ; Unchanged.
array_rremove rremoving, 3, 0
array_assert_equal rremoving, 1, 1, 2, 3, 3, 3, 3, 1, 1 ; Unchanged.
array_rremove empty, 42
array_assert_equal empty, ; Unchanged.

; array_reverse <name>
; Reverses an array.
array_reverse primes
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_reverse empty
array_assert_equal empty, ; Unchanged.

; array_rotate <name>, <amount>
; Rotates an array right by a positive amount,
; or left by a negative amount.
def_array rotating, 1, 2, 3, 4, 5
array_rotate rotating, 0
array_assert_equal rotating, 1, 2, 3, 4, 5 ; Unchanged.
array_rotate rotating, 1
array_assert_equal rotating, 5, 1, 2, 3, 4
array_rotate rotating, -1
array_assert_equal rotating, 1, 2, 3, 4, 5
array_rotate rotating, 2
array_assert_equal rotating, 4, 5, 1, 2, 3
array_rotate rotating, -2
array_assert_equal rotating, 1, 2, 3, 4, 5
array_rotate primes, 3
array_assert_equal primes, 5, 3, 2, 37, 31, 29, 23, 19, 17, 13, 11, 7
array_rotate primes, -3
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_rotate primes, 4
array_assert_equal primes, 7, 5, 3, 2, 37, 31, 29, 23, 19, 17, 13, 11
array_rotate primes, -4
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_rotate empty, 1
array_assert_equal empty, ; Unchanged.
array_rotate empty, -1
array_assert_equal empty, ; Unchanged.

; array_sort <name>
; Sorts an array in order from least to greatest.
; Uses an O(n log n) in-place merge sort algorithm.
array_sort primes
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_sort empty
array_assert_equal empty, ; Unchanged.

; array_rsort <name>
; Sorts an array in order from greatest to least.
; Uses an O(n log n) in-place merge sort algorithm.
array_rsort primes
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_rsort empty
array_assert_equal empty, ; Unchanged.

; array_is_sorted <result>, <name>
; Checks whether an array is sorted from least to greatest,
; setting the result to 1 if it is or 0 if it is not.
array_is_sorted result, empty
static_assert result == 1
array_is_sorted result, primes
static_assert result == 0
array_sort primes
array_is_sorted result, primes
static_assert result == 1

; array_is_rsorted <result>, <name>
; Checks whether an array is sorted from greatest to least,
; setting the result to 1 if it is or 0 if it is not.
array_is_rsorted result, empty
static_assert result == 1
array_is_rsorted result, primes
static_assert result == 0
array_rsort primes
array_is_rsorted result, primes
static_assert result == 1

; array_is_equal <result>, <name>, <...values>
; Checks whether an array's contents have exactly the specified values,
; setting the result to 1 if it does or 0 if it does not.
array_is_equal result, empty,
static_assert result == 1
array_is_equal result, empty, 42
static_assert result == 0
array_is_equal result, primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
static_assert result == 1
array_is_equal result, primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3
static_assert result == 0

; array_reseed <seed>
; Reseed the xorshift32 PRNG used in randomized array macros
; (`array_shuffle` and `array_pick`).
; The seed cannot be zero, since that would only generate more zeros.
array_reseed $deadbeef

; array_shuffle <name>
; Randomly shuffle an array.
; Uses the O(n) Fisher-Yates aka Knuth algorithm.
array_shuffle primes
array_assert_equal primes, 13, 2, 3, 29, 11, 5, 7, 37, 31, 19, 17, 23
array_shuffle empty
array_assert_equal empty, ; Unchanged.

; array_pick <result>, <name>
; Randomly pick an item from a nonempty array.
array_pick element, primes
static_assert element == primes$8
def_array single, 23
array_pick element, single
static_assert element == 23

; array_dedup <name>
; Deduplicates an array by reducing runs of the same value to one item.
def_array deduplicating, 1, 1, 2, 3, 3, 3, 2, 2, 1, 4, 4, 4, 4, 3, 2, 1, 1
array_dedup deduplicating
array_assert_equal deduplicating, 1, 2, 3, 2, 1, 4, 3, 2, 1
array_dedup single
array_assert_equal single, 23 ; Unchanged.
array_dedup empty
array_assert_equal empty, ; Unchanged.

; array_unique <name>
; Removes all duplicate items in an array,
; leaving only one item per unique value.
array_unique deduplicating
array_assert_equal deduplicating, 1, 2, 3, 4
array_unique single
array_assert_equal single, 23 ; Unchanged.
array_unique empty
array_assert_equal empty, ; Unchanged.

; array_are_all_equal <result>, <name>
; Checks whether all the values in an array are equal,
; setting the result to 1 if they are or 0 if they are not.
array_are_all_equal result, fives
static_assert result == 1
array_are_all_equal result, primes
static_assert result == 0
array_are_all_equal result, single
static_assert result == 1
array_are_all_equal result, empty
static_assert result == 1

; array_are_all_unique <result>, <name>
; Checks whether all the values in an array are unique,
; setting the result to 1 if they are or 0 if they are not.
array_are_all_unique result, fives
static_assert result == 0
array_are_all_unique result, primes
static_assert result == 1
array_are_all_unique result, single
static_assert result == 1
array_are_all_unique result, empty
static_assert result == 1

; array_min <result>, <name>
; Find the minimum value in a nonempty array.
array_min element, fives
static_assert element == 5
array_min element, primes
static_assert element == 2
array_min element, single
static_assert element == 23

; array_max <result>, <name>
; Find the maximum value in a nonempty array.
array_max element, fives
static_assert element == 5
array_max element, primes
static_assert element == 37
array_max element, single
static_assert element == 23

; array_argmin <result>, <name>
; Find the index of a minimum value in a nonempty array.
array_argmin result, fives
static_assert result == 0
array_argmin result, primes
static_assert result == 1
array_argmin result, single
static_assert result == 0

; array_argmax <result>, <name>
; Find the index of a maximum value in a nonempty array.
array_argmax result, fives
static_assert result == 0
array_argmax result, primes
static_assert result == 7
array_argmax result, single
static_assert result == 0

; array_sum <result>, <name>
; Take the sum of values in an array,
; or 0 if the array is empty.
; Not compatible with string arrays.
array_sum result, fives
static_assert result == 50
array_sum result, primes
static_assert result == 197
array_sum result, single
static_assert result == 23
array_sum result, empty
static_assert result == 0

; array_product <result>, <name>
; Take the product of values in an array,
; or 1 if the array is empty.
array_product result, odds
static_assert result == 945
array_product result, single
static_assert result == 23
array_product result, empty
static_assert result == 1

; array_mean <result>, <name>
; Take the mean (average) of values in a nonempty array.
; Not compatible with string arrays.
array_mean result, fives
static_assert result == 5
array_mean result, primes
static_assert result == 16
array_mean result, single
static_assert result == 23

; Clean up previously defined arrays for the next tests.
array_purge backwards, concatenated, concatenated_none, countdown, \
            deduplicating, empty, empty_range, evens, fives, naturals, odds, \
            positives, primes, removing, replacing, rotating, rremoving, \
            rreplacing, single, sliced_concatenated, sliced_empty, sliced_end, \
            sliced_primes, zeros
purge result, index, element, prime_11


; ==============================================================================
; Constant arrays, with base index 1
; ==============================================================================
use_array_base 1
use_constant_arrays

def_array empty
array_assert_equal empty,
static_assert empty#len == 0

def_array primes, 2, 3, 5, 7, 11, 13, 17, 19
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19
static_assert primes#len == 8
static_assert primes$1 == 2
static_assert primes$8 == 19

def_array odds
def_array_item 1
def_array_item 3
def_array_item 5
def_array_item 7
def_array_item 9
array_assert_equal odds, 1, 3, 5, 7, 9
static_assert odds#len == 5
static_assert odds$1 == 1
static_assert odds$5 == 9

def_array_fill zeros, 4
array_assert_equal zeros, 0, 0, 0, 0

def_array_fill fives, 10, 5
array_assert_equal fives, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

def_array_range naturals, 10
array_assert_equal naturals, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9

def_array_range positives, 1, 10
array_assert_equal positives, 1, 2, 3, 4, 5, 6, 7, 8, 9

def_array_range countdown, 10, -1, -1
array_assert_equal countdown, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0
static_assert countdown#len == 11
static_assert countdown$1 == 10
static_assert countdown$B == 0

def_array_range empty_range, 5, 5 ; This should print a warning.
static_assert empty_range#len == 0

def_array_range backwards, 1, 5, -1 ; This should print a warning.
static_assert backwards#len == 0

def_array_copy copied, primes
array_assert_equal copied, 2, 3, 5, 7, 11, 13, 17, 19
static_assert copied#len == primes#len
static_assert copied$1 == primes$1
static_assert copied$6 == primes$6

def_array_concat concatenated, primes, positives
array_assert_equal concatenated, 2, 3, 5, 7, 11, 13, 17, 19, 1, 2, 3, 4, 5, 6, 7, 8, 9
static_assert concatenated#len == primes#len + positives#len
def_array_concat concatenated_none,
array_assert_equal concatenated_none,
static_assert concatenated_none#len == 0

def_array_slice sliced_primes, primes, 4
array_assert_equal sliced_primes, 7, 11, 13, 17, 19
def_array_slice sliced_concatenated, concatenated, 5, 13
array_assert_equal sliced_concatenated, 11, 13, 17, 19, 1, 2, 3, 4
def_array_slice sliced_empty, naturals, 10, 10
array_assert_equal sliced_empty,
def_array_slice sliced_end, naturals, naturals#base + naturals#len
array_assert_equal sliced_end,

array_purge copied
static_assert !def(copied#len)
static_assert !def(copied$1)
static_assert !def(copied$6)

pushs "array_db/dw/dl constant", ROM0 ; Only necessary for testing `array_db/dw/dl`.

: array_db empty
static_assert @ - :- == empty#len
: array_db primes
static_assert @ - :- == primes#len

: array_dw empty
static_assert @ - :- == empty#len * 2
: array_dw primes
static_assert @ - :- == primes#len * 2

: array_dl empty
static_assert @ - :- == empty#len * 4
: array_dl primes
static_assert @ - :- == primes#len * 4

pops

array_clear odds
array_assert_equal odds, ; Empty.
static_assert odds#len == 0
static_assert !def(odds$1)

array_pad primes, 5
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19 ; Unchanged.
array_pad primes, 9
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 0
array_pad primes, 12, 257
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257

array_lpad primes, 10
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257 ; Unchanged.
array_lpad primes, 14
array_assert_equal primes, 0, 0, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257
array_lpad primes, 16, 1
array_assert_equal primes, 1, 1, 0, 0, 2, 3, 5, 7, 11, 13, 17, 19, 0, 257, 257, 257

print "Countdown: T-minus "
array_print countdown
println "... liftoff!"

print "Empty: "
array_println empty

array_get prime_12, primes, 12
static_assert prime_12 == primes$C

array_set primes, 13, 23
array_set primes, 14, 29
array_set primes, 15, 31
array_set primes, 16, 37
array_assert_equal primes, 1, 1, 0, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37

array_delete primes, 3
array_assert_equal primes, 1, 1, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_delete primes, 2
array_assert_equal primes, 1, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_delete primes, 1
array_assert_equal primes, 0, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_delete primes, 1
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37

array_insert odds, 1, 3
array_assert_equal odds, 3
array_insert odds, 1, 1
array_assert_equal odds, 1, 3
array_insert odds, 3, 5, 7
array_assert_equal odds, 1, 3, 5, 7
array_insert odds, 3,
array_assert_equal odds, 1, 3, 5, 7 ; Unchanged.

array_push odds, 9
array_assert_equal odds, 1, 3, 5, 7, 9
array_append odds,
array_assert_equal odds, 1, 3, 5, 7, 9 ; Unchanged.

array_unshift odds, -1
array_assert_equal odds, -1, 1, 3, 5, 7, 9
array_prepend odds,
array_assert_equal odds, -1, 1, 3, 5, 7, 9 ; Unchanged.

def_array_range evens, 2, 13, 2
array_assert_equal evens, 2, 4, 6, 8, 10, 12
array_pop element, evens
static_assert element == 12
array_assert_equal evens, 2, 4, 6, 8, 10
array_pop element, evens
static_assert element == 10
array_assert_equal evens, 2, 4, 6, 8

array_assert_equal evens, 2, 4, 6, 8
array_shift element, evens
static_assert element == 2
array_assert_equal evens, 4, 6, 8
array_shift element, evens
static_assert element == 4
array_assert_equal evens, 6, 8

array_extend odds, empty, empty, empty
array_assert_equal odds, -1, 1, 3, 5, 7, 9 ; Unchanged.
array_extend primes,
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37 ; Unchanged.
array_extend primes, zeros
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 0, 0, 0, 0
static_assert primes#len == 12 + zeros#len
static_assert primes$D == zeros$1
static_assert primes$E == zeros$2
static_assert primes$F == zeros$3
static_assert primes$10 == zeros$4

array_slice odds, 3
array_assert_equal odds, 3, 5, 7, 9
array_slice odds, odds#base, odds#base + odds#len
array_assert_equal odds, 3, 5, 7, 9 ; Unchanged.
array_slice primes, 1, 13
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_slice empty, 1
array_assert_equal empty, ; Unchanged.

array_contains result, empty, 42
static_assert result == 0
array_contains result, primes, 37
static_assert result == 1
array_contains result, primes, 57
static_assert result == 0

array_find index, empty, 42
static_assert index == empty#base - 1
array_find index, fives, 5
static_assert index == 1
array_find index, primes, 37
static_assert index == 12

array_rfind index, empty, 42
static_assert index == empty#base - 1
array_rfind index, fives, 5
static_assert index == 10
array_rfind index, primes, 37
static_assert index == 12

array_count result, empty, 42
static_assert result == 0
array_count result, fives, 5
static_assert result == 10
array_count result, primes, 37
static_assert result == 1

def_array replacing, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert replacing#len == 14
array_replace replacing, 4, 5
array_assert_equal replacing, 1, 1, 2, 2, 3, 3, 5, 5, 3, 3, 2, 2, 1, 1
array_replace replacing, 2, 6, 3
array_assert_equal replacing, 1, 1, 6, 6, 3, 3, 5, 5, 3, 3, 6, 2, 1, 1
array_replace replacing, 9, 1
array_assert_equal replacing, 1, 1, 6, 6, 3, 3, 5, 5, 3, 3, 6, 2, 1, 1 ; Unchanged.
array_replace replacing, 3, 42, 0
array_assert_equal replacing, 1, 1, 6, 6, 3, 3, 5, 5, 3, 3, 6, 2, 1, 1 ; Unchanged.
array_replace empty, 42, 99
array_assert_equal empty, ; Unchanged.

def_array rreplacing, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert rreplacing#len == 14
array_rreplace rreplacing, 4, 5
array_assert_equal rreplacing, 1, 1, 2, 2, 3, 3, 5, 5, 3, 3, 2, 2, 1, 1
array_rreplace rreplacing, 2, 6, 3
array_assert_equal rreplacing, 1, 1, 2, 6, 3, 3, 5, 5, 3, 3, 6, 6, 1, 1
array_rreplace rreplacing, 9, 1
array_assert_equal rreplacing, 1, 1, 2, 6, 3, 3, 5, 5, 3, 3, 6, 6, 1, 1 ; Unchanged.
array_rreplace rreplacing, 3, 42, 0
array_assert_equal rreplacing, 1, 1, 2, 6, 3, 3, 5, 5, 3, 3, 6, 6, 1, 1 ; Unchanged.
array_rreplace empty, 42, 99
array_assert_equal empty, ; Unchanged.

def_array removing, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert removing#len == 14
array_remove removing, 4
array_assert_equal removing, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 1, 1
array_contains result, removing, 4
static_assert result == 0
array_remove removing, 2, 3
array_assert_equal removing, 1, 1, 3, 3, 3, 3, 2, 1, 1
array_remove removing, 9
array_assert_equal removing, 1, 1, 3, 3, 3, 3, 2, 1, 1 ; Unchanged.
array_remove removing, 3, 0
array_assert_equal removing, 1, 1, 3, 3, 3, 3, 2, 1, 1 ; Unchanged.
array_remove empty, 42
array_assert_equal empty, ; Unchanged.

def_array rremoving, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1
static_assert rremoving#len == 14
array_rremove rremoving, 4
array_assert_equal rremoving, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 1, 1
array_contains result, rremoving, 4
static_assert result == 0
array_rremove rremoving, 2, 3
array_assert_equal rremoving, 1, 1, 2, 3, 3, 3, 3, 1, 1
array_rremove rremoving, 9
array_assert_equal rremoving, 1, 1, 2, 3, 3, 3, 3, 1, 1 ; Unchanged.
array_rremove rremoving, 3, 0
array_assert_equal rremoving, 1, 1, 2, 3, 3, 3, 3, 1, 1 ; Unchanged.
array_rremove empty, 42
array_assert_equal empty, ; Unchanged.

array_reverse primes
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_reverse empty
array_assert_equal empty, ; Unchanged.

def_array rotating, 1, 2, 3, 4, 5
array_rotate rotating, 0
array_assert_equal rotating, 1, 2, 3, 4, 5 ; Unchanged.
array_rotate rotating, 1
array_assert_equal rotating, 5, 1, 2, 3, 4
array_rotate rotating, -1
array_assert_equal rotating, 1, 2, 3, 4, 5
array_rotate rotating, 2
array_assert_equal rotating, 4, 5, 1, 2, 3
array_rotate rotating, -2
array_assert_equal rotating, 1, 2, 3, 4, 5
array_rotate primes, 3
array_assert_equal primes, 5, 3, 2, 37, 31, 29, 23, 19, 17, 13, 11, 7
array_rotate primes, -3
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_rotate primes, 4
array_assert_equal primes, 7, 5, 3, 2, 37, 31, 29, 23, 19, 17, 13, 11
array_rotate primes, -4
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_rotate empty, 1
array_assert_equal empty, ; Unchanged.
array_rotate empty, -1
array_assert_equal empty, ; Unchanged.

array_sort primes
array_assert_equal primes, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
array_sort empty
array_assert_equal empty, ; Unchanged.

array_rsort primes
array_assert_equal primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
array_rsort empty
array_assert_equal empty, ; Unchanged.

array_is_sorted result, empty
static_assert result == 1
array_is_sorted result, primes
static_assert result == 0
array_sort primes
array_is_sorted result, primes
static_assert result == 1

array_is_rsorted result, empty
static_assert result == 1
array_is_rsorted result, primes
static_assert result == 0
array_rsort primes
array_is_rsorted result, primes
static_assert result == 1

array_is_equal result, empty,
static_assert result == 1
array_is_equal result, empty, 42
static_assert result == 0
array_is_equal result, primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3, 2
static_assert result == 1
array_is_equal result, primes, 37, 31, 29, 23, 19, 17, 13, 11, 7, 5, 3
static_assert result == 0

array_reseed $deadbeef

array_shuffle primes
array_assert_equal primes, 13, 2, 3, 29, 11, 5, 7, 37, 31, 19, 17, 23
array_shuffle empty
array_assert_equal empty, ; Unchanged.

array_pick element, primes
static_assert element == primes$9
def_array single, 23
array_pick element, single
static_assert element == 23

def_array deduplicating, 1, 1, 2, 3, 3, 3, 2, 2, 1, 4, 4, 4, 4, 3, 2, 1, 1
array_dedup deduplicating
array_assert_equal deduplicating, 1, 2, 3, 2, 1, 4, 3, 2, 1
array_dedup single
array_assert_equal single, 23 ; Unchanged.
array_dedup empty
array_assert_equal empty, ; Unchanged.

array_unique deduplicating
array_assert_equal deduplicating, 1, 2, 3, 4
array_unique single
array_assert_equal single, 23 ; Unchanged.
array_unique empty
array_assert_equal empty, ; Unchanged.

array_are_all_equal result, fives
static_assert result == 1
array_are_all_equal result, primes
static_assert result == 0
array_are_all_equal result, single
static_assert result == 1
array_are_all_equal result, empty
static_assert result == 1

array_are_all_unique result, fives
static_assert result == 0
array_are_all_unique result, primes
static_assert result == 1
array_are_all_unique result, single
static_assert result == 1
array_are_all_unique result, empty
static_assert result == 1

array_min element, fives
static_assert element == 5
array_min element, primes
static_assert element == 2
array_min element, single
static_assert element == 23

array_max element, fives
static_assert element == 5
array_max element, primes
static_assert element == 37
array_max element, single
static_assert element == 23

array_argmin result, fives
static_assert result == 1
array_argmin result, primes
static_assert result == 2
array_argmin result, single
static_assert result == 1

array_argmax result, fives
static_assert result == 1
array_argmax result, primes
static_assert result == 8
array_argmax result, single
static_assert result == 1

array_sum result, fives
static_assert result == 50
array_sum result, primes
static_assert result == 197
array_sum result, single
static_assert result == 23
array_sum result, empty
static_assert result == 0

array_product result, odds
static_assert result == 945
array_product result, single
static_assert result == 23
array_product result, empty
static_assert result == 1

array_mean result, fives
static_assert result == 5
array_mean result, primes
static_assert result == 16
array_mean result, single
static_assert result == 23

; Clean up previously defined arrays for the next tests.
array_purge backwards, concatenated, concatenated_none, countdown, \
            deduplicating, empty, empty_range, evens, fives, naturals, odds, \
            positives, primes, removing, replacing, rotating, rremoving, \
            rreplacing, single, sliced_concatenated, sliced_empty, sliced_end, \
            sliced_primes, zeros
purge result, index, element, prime_12


; ==============================================================================
; String arrays, with base index 2
; ==============================================================================
use_array_base 2
use_string_arrays

def_array empty
array_assert_equal empty,
static_assert empty#len == 0

def_array primes, "2", "3", "5", "7", "11", "13", "17", "19"
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19"
static_assert primes#len == 8
static_assert #primes$2 === "2"
static_assert #primes$9 === "19"

def_array odds
def_array_item "1"
def_array_item "3"
def_array_item "5"
def_array_item "7"
def_array_item "9"
array_assert_equal odds, "1", "3", "5", "7", "9"
static_assert odds#len == 5
static_assert #odds$2 === "1"
static_assert #odds$6 === "9"

def_array_fill zerolens, 4
array_assert_equal zerolens, "", "", "", ""

def_array_fill fives, 10, "5"
array_assert_equal fives, "5", "5", "5", "5", "5", "5", "5", "5", "5", "5"

def_array naturals, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
def_array positives, "1", "2", "3", "4", "5", "6", "7", "8", "9"
def_array countdown, "10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "0"

def_array_copy copied, primes
array_assert_equal copied, "2", "3", "5", "7", "11", "13", "17", "19"
static_assert copied#len == primes#len
static_assert #copied$2 === #primes$2
static_assert #copied$7 === #primes$7

def_array_concat concatenated, primes, positives
array_assert_equal concatenated, "2", "3", "5", "7", "11", "13", "17", "19", "1", "2", "3", "4", "5", "6", "7", "8", "9"
static_assert concatenated#len == primes#len + positives#len
def_array_concat concatenated_none,
array_assert_equal concatenated_none,
static_assert concatenated_none#len == 0

def_array_slice sliced_primes, primes, 5
array_assert_equal sliced_primes, "7", "11", "13", "17", "19"
def_array_slice sliced_concatenated, concatenated, 6, 14
array_assert_equal sliced_concatenated, "11", "13", "17", "19", "1", "2", "3", "4"
def_array_slice sliced_empty, naturals, 11, 11
array_assert_equal sliced_empty,
def_array_slice sliced_end, naturals, naturals#base + naturals#len
array_assert_equal sliced_end,

array_purge copied
static_assert !def(copied#len)
static_assert !def(copied$2)
static_assert !def(copied$7)

pushs "array_db/dw/dl string", ROM0 ; Only necessary for testing `array_db/dw/dl`.

: array_db empty
static_assert @ - :- == 0
: array_db primes
static_assert @ - :- == 12 ; Sum of `STRLEN` of each item of `primes`.

: array_dw empty
static_assert @ - :- == 0
: array_dw primes
static_assert @ - :- == 12 * 2

: array_dl empty
static_assert @ - :- == 0
: array_dl primes
static_assert @ - :- == 12 * 4

pops

array_clear odds
array_assert_equal odds, ; Empty.
static_assert odds#len == 0
static_assert !def(odds$2)

array_pad primes, 5
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19" ; Unchanged.
array_pad primes, 9
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", ""
array_pad primes, 12, "257"
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", "", "257", "257", "257"

array_lpad primes, 10
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", "", "257", "257", "257" ; Unchanged.
array_lpad primes, 14
array_assert_equal primes, "", "", "2", "3", "5", "7", "11", "13", "17", "19", "", "257", "257", "257"
array_lpad primes, 16, "1"
array_assert_equal primes, "1", "1", "", "", "2", "3", "5", "7", "11", "13", "17", "19", "", "257", "257", "257"

print "Countdown: T-minus "
array_print countdown
println "... liftoff!"

print "Empty: "
array_println empty

array_get prime_13, primes, 13
static_assert #prime_13 === #primes$D

array_set primes, 14, "23"
array_set primes, 15, "29"
array_set primes, 16, "31"
array_set primes, 17, "37"
array_assert_equal primes, "1", "1", "", "", "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37"

array_delete primes, 4
array_assert_equal primes, "1", "1", "", "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37"
array_delete primes, 3
array_assert_equal primes, "1", "", "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37"
array_delete primes, 2
array_assert_equal primes, "", "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37"
array_delete primes, 2
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37"

array_insert odds, 2, "3"
array_assert_equal odds, "3"
array_insert odds, 2, "1"
array_assert_equal odds, "1", "3"
array_insert odds, 4, "5", "7"
array_assert_equal odds, "1", "3", "5", "7"
array_insert odds, 4,
array_assert_equal odds, "1", "3", "5", "7" ; Unchanged.

array_append odds, "9"
array_assert_equal odds, "1", "3", "5", "7", "9"
array_push odds,
array_assert_equal odds, "1", "3", "5", "7", "9" ; Unchanged.

array_prepend odds, "-1"
array_assert_equal odds, "-1", "1", "3", "5", "7", "9"
array_unshift odds,
array_assert_equal odds, "-1", "1", "3", "5", "7", "9" ; Unchanged.

def_array evens, "2", "4", "6", "8", "10", "12"
array_pop element, evens
static_assert #element === "12"
array_assert_equal evens, "2", "4", "6", "8", "10"
array_pop element, evens
static_assert #element === "10"
array_assert_equal evens, "2", "4", "6", "8"

array_assert_equal evens, "2", "4", "6", "8"
array_shift element, evens
static_assert #element === "2"
array_assert_equal evens, "4", "6", "8"
array_shift element, evens
static_assert #element === "4"
array_assert_equal evens, "6", "8"

array_extend odds, empty, empty, empty
array_assert_equal odds, "-1", "1", "3", "5", "7", "9" ; Unchanged.
array_extend primes,
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37" ; Unchanged.
array_extend primes, zerolens
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37", "", "", "", ""
static_assert primes#len == 12 + zerolens#len
static_assert #primes$E === #zerolens$2
static_assert #primes$F === #zerolens$3
static_assert #primes$10 === #zerolens$4
static_assert #primes$11 === #zerolens$5

array_slice odds, 4
array_assert_equal odds, "3", "5", "7", "9"
array_slice odds, odds#base, odds#base + odds#len
array_assert_equal odds, "3", "5", "7", "9" ; Unchanged.
array_slice primes, 2, 14
array_assert_equal primes, "2", "3", "5", "7", "11", "13", "17", "19", "23", "29", "31", "37"
array_slice empty, 2
array_assert_equal empty, ; Unchanged.

array_contains result, empty, "42"
static_assert result == 0
array_contains result, primes, "37"
static_assert result == 1
array_contains result, primes, "57"
static_assert result == 0

array_find index, empty, "42"
static_assert index == empty#base - 1
array_find index, fives, "5"
static_assert index == 2
array_find index, primes, "37"
static_assert index == 13

array_rfind index, empty, "42"
static_assert index == empty#base - 1
array_rfind index, fives, "5"
static_assert index == 11
array_rfind index, primes, "37"
static_assert index == 13

array_count result, empty, "42"
static_assert result == 0
array_count result, fives, "5"
static_assert result == 10
array_count result, primes, "37"
static_assert result == 1

def_array replacing, "1", "1", "2", "2", "3", "3", "4", "4", "3", "3", "2", "2", "1", "1"
static_assert replacing#len == 14
array_replace replacing, "4", "5"
array_assert_equal replacing, "1", "1", "2", "2", "3", "3", "5", "5", "3", "3", "2", "2", "1", "1"
array_replace replacing, "2", "6", 3
array_assert_equal replacing, "1", "1", "6", "6", "3", "3", "5", "5", "3", "3", "6", "2", "1", "1"
array_replace replacing, "9", "1"
array_assert_equal replacing, "1", "1", "6", "6", "3", "3", "5", "5", "3", "3", "6", "2", "1", "1" ; Unchanged.
array_replace replacing, "3", "42", 0
array_assert_equal replacing, "1", "1", "6", "6", "3", "3", "5", "5", "3", "3", "6", "2", "1", "1" ; Unchanged.
array_replace empty, "42", "99"
array_assert_equal empty, ; Unchanged.

def_array rreplacing, "1", "1", "2", "2", "3", "3", "4", "4", "3", "3", "2", "2", "1", "1"
static_assert rreplacing#len == 14
array_rreplace rreplacing, "4", "5"
array_assert_equal rreplacing, "1", "1", "2", "2", "3", "3", "5", "5", "3", "3", "2", "2", "1", "1"
array_rreplace rreplacing, "2", "6", 3
array_assert_equal rreplacing, "1", "1", "2", "6", "3", "3", "5", "5", "3", "3", "6", "6", "1", "1"
array_rreplace rreplacing, "9", "1"
array_assert_equal rreplacing, "1", "1", "2", "6", "3", "3", "5", "5", "3", "3", "6", "6", "1", "1" ; Unchanged.
array_rreplace rreplacing, "3", "42", 0
array_assert_equal rreplacing, "1", "1", "2", "6", "3", "3", "5", "5", "3", "3", "6", "6", "1", "1" ; Unchanged.
array_rreplace empty, "42", "99"
array_assert_equal empty, ; Unchanged.

def_array removing, "1", "1", "2", "2", "3", "3", "4", "4", "3", "3", "2", "2", "1", "1"
static_assert removing#len == 14
array_remove removing, "4"
array_assert_equal removing, "1", "1", "2", "2", "3", "3", "3", "3", "2", "2", "1", "1"
array_contains result, removing, "4"
static_assert result == 0
array_remove removing, "2", 3
array_assert_equal removing, "1", "1", "3", "3", "3", "3", "2", "1", "1"
array_remove removing, "9"
array_assert_equal removing, "1", "1", "3", "3", "3", "3", "2", "1", "1" ; Unchanged.
array_remove removing, "3", 0
array_assert_equal removing, "1", "1", "3", "3", "3", "3", "2", "1", "1" ; Unchanged.
array_remove empty, "42"
array_assert_equal empty, ; Unchanged.

def_array rremoving, "1", "1", "2", "2", "3", "3", "4", "4", "3", "3", "2", "2", "1", "1"
static_assert rremoving#len == 14
array_rremove rremoving, "4"
array_assert_equal rremoving, "1", "1", "2", "2", "3", "3", "3", "3", "2", "2", "1", "1"
array_contains result, rremoving, "4"
static_assert result == 0
array_rremove rremoving, "2", 3
array_assert_equal rremoving, "1", "1", "2", "3", "3", "3", "3", "1", "1"
array_rremove rremoving, "9"
array_assert_equal rremoving, "1", "1", "2", "3", "3", "3", "3", "1", "1" ; Unchanged.
array_rremove rremoving, "3", 0
array_assert_equal rremoving, "1", "1", "2", "3", "3", "3", "3", "1", "1" ; Unchanged.
array_rremove empty, "42"
array_assert_equal empty, ; Unchanged.

array_reverse primes
array_assert_equal primes, "37", "31", "29", "23", "19", "17", "13", "11", "7", "5", "3", "2"
array_reverse empty
array_assert_equal empty, ; Unchanged.

def_array rotating, "1", "2", "3", "4", "5"
array_rotate rotating, 0
array_assert_equal rotating, "1", "2", "3", "4", "5" ; Unchanged.
array_rotate rotating, 1
array_assert_equal rotating, "5", "1", "2", "3", "4"
array_rotate rotating, -1
array_assert_equal rotating, "1", "2", "3", "4", "5"
array_rotate rotating, 2
array_assert_equal rotating, "4", "5", "1", "2", "3"
array_rotate rotating, -2
array_assert_equal rotating, "1", "2", "3", "4", "5"
array_rotate primes, 3
array_assert_equal primes, "5", "3", "2", "37", "31", "29", "23", "19", "17", "13", "11", "7"
array_rotate primes, -3
array_assert_equal primes, "37", "31", "29", "23", "19", "17", "13", "11", "7", "5", "3", "2"
array_rotate primes, 4
array_assert_equal primes, "7", "5", "3", "2", "37", "31", "29", "23", "19", "17", "13", "11"
array_rotate primes, -4
array_assert_equal primes, "37", "31", "29", "23", "19", "17", "13", "11", "7", "5", "3", "2"
array_rotate empty, 1
array_assert_equal empty, ; Unchanged.
array_rotate empty, -1
array_assert_equal empty, ; Unchanged.

array_sort primes
array_assert_equal primes, "11", "13", "17", "19", "2", "23", "29", "3", "31", "37", "5", "7"
array_sort empty
array_assert_equal empty, ; Unchanged.

array_rsort primes
array_assert_equal primes, "7", "5", "37", "31", "3", "29", "23", "2", "19", "17", "13", "11"
array_rsort empty
array_assert_equal empty, ; Unchanged.

array_is_sorted result, empty
static_assert result == 1
array_is_sorted result, primes
static_assert result == 0
array_sort primes
array_is_sorted result, primes
static_assert result == 1

array_is_rsorted result, empty
static_assert result == 1
array_is_rsorted result, primes
static_assert result == 0
array_rsort primes
array_is_rsorted result, primes
static_assert result == 1

array_is_equal result, empty,
static_assert result == 1
array_is_equal result, empty, "42"
static_assert result == 0
array_is_equal result, primes, "7", "5", "37", "31", "3", "29", "23", "2", "19", "17", "13", "11"
static_assert result == 1
array_is_equal result, primes, "7", "5", "37", "31", "3", "29", "23", "2", "19", "17", "13"
static_assert result == 0

array_reseed $deadbeef

array_shuffle primes
array_assert_equal primes, "23", "11", "13", "37", "2", "17", "19", "7", "5", "3", "29", "31"
array_shuffle empty
array_assert_equal empty, ; Unchanged.

array_pick element, primes
static_assert #element === #primes$A
def_array single, "23"
array_pick element, single
static_assert #element === "23"

def_array deduplicating, "1", "1", "2", "3", "3", "3", "2", "2", "1", "4", "4", "4", "4", "3", "2", "1", "1"
array_dedup deduplicating
array_assert_equal deduplicating, "1", "2", "3", "2", "1", "4", "3", "2", "1"
array_dedup single
array_assert_equal single, "23" ; Unchanged.
array_dedup empty
array_assert_equal empty, ; Unchanged.

array_unique deduplicating
array_assert_equal deduplicating, "1", "2", "3", "4"
array_unique single
array_assert_equal single, "23" ; Unchanged.
array_unique empty
array_assert_equal empty, ; Unchanged.

array_are_all_equal result, fives
static_assert result == 1
array_are_all_equal result, primes
static_assert result == 0
array_are_all_equal result, single
static_assert result == 1
array_are_all_equal result, empty
static_assert result == 1

array_are_all_unique result, fives
static_assert result == 0
array_are_all_unique result, primes
static_assert result == 1
array_are_all_unique result, single
static_assert result == 1
array_are_all_unique result, empty
static_assert result == 1

array_min element, fives
static_assert #element === "5"
array_min element, primes
static_assert #element === "11"
array_min element, single
static_assert #element === "23"

array_max element, fives
static_assert #element === "5"
array_max element, primes
static_assert #element === "7"
array_max element, single
static_assert #element === "23"

array_argmin result, fives
static_assert result == 2
array_argmin result, primes
static_assert result == 3
array_argmin result, single
static_assert result == 2

array_argmax result, fives
static_assert result == 2
array_argmax result, primes
static_assert result == 9
array_argmax result, single
static_assert result == 2

; array_join <result>, <name> [, <sep> = ""]
; Concatenate the string values in an array,
; interspersed with a separator if one is specified.
; Not compatible with numeric arrays.
array_join joined, fives
static_assert #joined === "5555555555"
array_join joined, primes, "-"
static_assert #joined === "23-11-13-37-2-17-19-7-5-3-29-31"
array_join joined, single, "+"
static_assert #joined === "23"
array_join joined, empty, "..."
static_assert #joined === ""

; Clean up previously defined arrays for the next tests.
array_purge concatenated, concatenated_none, countdown, deduplicating, empty, \
            evens, fives, naturals, odds, positives, primes, removing, \
            replacing, rotating, rremoving, rreplacing, single, \
            sliced_concatenated, sliced_empty, sliced_end, sliced_primes, \
            zerolens
purge result, index, element, joined, prime_13
