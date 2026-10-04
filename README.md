# RGBDS arrays

A [RGBDS](https://rgbds.gbdev.io) macro pack that provides array-like functionality.

The latest version is **1.1**.

## Usage

Download [`arrays.inc`](arrays.inc), `INCLUDE` it in your project, and then you can use the macros.
See [`examples.asm`](examples.asm) for demonstrations of how each macro is used.

## Credits

Inspired by
ISSOtm's [`structs.inc`](https://codeberg.org/ISSOtm/rgbds-structs)
and [`debugfile.inc`](https://codeberg.org/ISSOtm/debugfile.inc),
Evie's [`regex.inc`](https://github.com/eievui5/regex.inc), and
GBDev's [`hardware.inc`](https://github.com/gbdev/hardware.inc).

## Macros

If <code><i>arr</i></code> is defined as an array, then its length is <code><i>arr</i>#len</code>,
and its items are <code><i>arr</i>{<i>idx</i>}</code> for <code><i>idx</i></code> from <code><i>arr</i>#base</code> (0 by default) to <code><i>arr</i>#base + <i>arr</i>#len - 1</code>.

The values <code><i>arr</i>#len</code> and <code><i>arr</i>#base</code> are `equ` constants; so is <code><i>arr</i>#equ</code>, which determines whether `arr`'s items are `equ` constants or `=` variables. If the items are variables, they can be freely reassigned.

You can manually change all of those values, but keep them consistent, or else the array macros may break if they assume preconditions that are now false. For example, if you change the value of <code><i>arr</i>#len</code> or <code><i>arr</i>#base</code>, ensure that items are defined for all the expected indexes from <code><i>arr</i>#base</code> to <code><i>arr</i>#base + <i>arr</i>#len - 1</code>.

### <code>check_arrays_inc_min_version <i>&lt;major&gt;</i>[.<i>&lt;minor&gt;</i>]</code>

Check whether this library version meets a minimum required one.

### <code>use_array_base <i>&lt;base&gt;</i></code>

Set the base index for subsequent arrays.
Typically 0 or 1, but higher non-negative bases are also technically valid.

### `use_constant_arrays`

Set subsequent arrays to have constant items (immutable, `equ`).

### `use_variable_arrays`

Set subsequent arrays to have variable items (mutable, `=`).

### <code>def_array <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Defines a new array, initializing it with zero or more values.

Redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to this array.

### <code>array_assert_equal <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Checks whether an array's contents have exactly the specified values.

### <code>def_array_fill <i>&lt;name&gt;</i>, <i>&lt;length&gt;</i> [, <i>&lt;value&gt;</i> = 0]</code>

Defines a new array, initializing it to be filled with N of the same value,
or with N zeros if the value is unspecified.

Redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to this array.

### <code>def_array_range <i>&lt;name&gt;</i> [, <i>&lt;start&gt;</i> = 0], <i>&lt;stop&gt;</i> [, <i>&lt;step&gt;</i> = 1]</code>

Defines a new array, initializing it to be an arithmetic sequence.

- <code>def_array_range <i>&lt;name&gt;</i>, <i>&lt;stop&gt;</i></code>
  gives the half-open interval [0, <i>&lt;stop&gt;</i>).
- <code>def_array_range <i>&lt;name&gt;</i>, <i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i></code>
  gives the half-open interval [<i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i>).
- <code>def_array_range <i>&lt;name&gt;</i>, <i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i>, <i>&lt;step&gt;</i></code>
  gives the half-open interval [<i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i>), skipping by <i>&lt;step&gt;</i>.

Redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to this array.

### <code>def_array_copy <i>&lt;name&gt;</i>, <i>&lt;other&gt;</i></code>

Defines a new array as a copy of another array.

Redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to this array.

### <code>def_array_concat <i>&lt;name&gt;</i>, <i>&lt;...others&gt;</i></code>

Defines a new array as a concatenation of other arrays.

Redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to this array.

### <code>def_array_slice <i>&lt;name&gt;</i>, <i>&lt;other&gt;</i>, <i>&lt;start index&gt;</i> [, <i>&lt;end pos&gt;</i>]</code>

Defines a new array as a slice of another array starting at an index,
and ending before a subsequent position if one is specified.

Redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to this array.

### <code>array_purge <i>&lt;name&gt;</i></code>

Purges an array and all its items.

### <code>array_clear <i>&lt;name&gt;</i></code>

Removes all items from an array, resetting its length to 0.

### <code>array_pad <i>&lt;name&gt;</i>, <i>&lt;length&gt;</i> [, <i>&lt;value&gt;</i> = 0]</code>

Pads the end of an array up to a minimum length with a given value,
or with 0 if the value is unspecified.

### <code>array_lpad <i>&lt;name&gt;</i>, <i>&lt;length&gt;</i> [, <i>&lt;value&gt;</i> = 0]</code>

Pads the beginning of an array up to a minimum length with a given value,
or with 0 if the value is unspecified.

### <code>array_print <i>&lt;name&gt;</i></code>

Prints the items of an array, comma-separated between brackets.

### <code>array_println <i>&lt;name&gt;</i></code>

Prints the items of an array, comma-separated between brackets,
followed by a newline.

### <code>array_get <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i></code>

Gets the value of an item in an array.

### <code>array_set <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i>, <i>&lt;value&gt;</i></code>

Sets the value of an item in an array.

### <code>array_delete <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i></code>

Deletes an item from an array.

### <code>array_insert <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i>, <i>&lt;...values&gt;</i></code>

Inserts zero or more values into an array at a given position.

### <code>array_append <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Appends zero or more values to the end of an array.

### <code>array_prepend <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Prepends zero or more values to the beginning of an array.

### <code>array_pop <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Pops the value from the end of a nonempty array.

### <code>array_shift <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Shifts the value from the beginning of a nonempty array.

### <code>array_extend <i>&lt;name&gt;</i>, <i>&lt;...others&gt;</i></code>

Extends an array by concatenating other arrays.

### <code>array_slice <i>&lt;name&gt;</i>, <i>&lt;start index&gt;</i> [, <i>&lt;end pos&gt;</i>]</code>

Redefines an array to be a slice of itself starting at an index,
and ending before a subsequent position if one is specified.

### <code>array_contains <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Checks whether a value exists in an array,
setting the result to 1 if it does or 0 if it does not.

### <code>array_find <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Find the first index of a value in an array,
or base&nbsp;−&nbsp;1 if the value is not in the array.

### <code>array_rfind <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Find the last index of a value in an array,
or base&nbsp;−&nbsp;1 if the value is not in the array.

### <code>array_count <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Count the occurrences of a value in an array.

### <code>array_replace <i>&lt;name&gt;</i>, <i>&lt;old&gt;</i>, <i>&lt;new&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Replace the first N occurrences of one value in an array with another,
or replace all of them if N is unspecified.

### <code>array_rreplace <i>&lt;name&gt;</i>, <i>&lt;old&gt;</i>, <i>&lt;new&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Replace the last N occurrences of one value in an array with another,
or replace all of them if N is unspecified.

### <code>array_remove <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Remove the first N occurrences of a value in an array,
or remove all of them if N is unspecified.

### <code>array_rremove <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Remove the last N occurrences of a value in an array,
or remove all of them if N is unspecified.

### <code>array_reverse <i>&lt;name&gt;</i></code>

Reverses an array.

### <code>array_rotate <i>&lt;name&gt;</i>, <i>&lt;amount&gt;</i></code>

Rotates an array right by a positive amount,
or left by a negative amount.

### <code>array_sort <i>&lt;name&gt;</i></code>

Sorts an array in order from least to greatest.
Uses an 𝒪(<i>n</i> log <i>n</i>) in-place merge sort algorithm.

### <code>array_rsort <i>&lt;name&gt;</i></code>

Sorts an array in order from greatest to least.
Uses an 𝒪(<i>n</i> log <i>n</i>) in-place merge sort algorithm.

### <code>array_is_sorted <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether an array is sorted from least to greatest,
setting the result to 1 if it is or 0 if it is not.

### <code>array_is_rsorted <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether an array is sorted from greatest to least,
setting the result to 1 if it is or 0 if it is not.

### <code>array_reseed <i>&lt;seed&gt;</i></code>

Reseed the xorshift32 PRNG used in randomized array macros
(`array_shuffle` and `array_pick`).

### <code>array_shuffle <i>&lt;name&gt;</i></code>

Randomly shuffle an array.
Uses the 𝒪(<i>n</i>) Fisher-Yates aka Knuth algorithm.

### <code>array_pick <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Randomly pick an item from a nonempty array.

### <code>array_dedup <i>&lt;name&gt;</i></code>

Deduplicates an array by reducing runs of the same value to one item.

### <code>array_unique <i>&lt;name&gt;</i></code>

Removes all duplicate items in an array,
leaving only one item per unique value.

### <code>array_are_all_equal <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether all the values in an array are equal,
setting the result to 1 if they are or 0 if they are not.

### <code>array_are_all_unique <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether all the values in an array are unique,
setting the result to 1 if they are or 0 if they are not.

### <code>array_min <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the minimum value in a nonempty array.

### <code>array_max <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the maximum value in a nonempty array.

### <code>array_argmin <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the index of a minimum value in a nonempty array.

### <code>array_argmax <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the index of a maximum value in a nonempty array.

### <code>array_sum <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the sum of values in an array,
or 0 if the array is empty.

### <code>array_product <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the product of values in an array,
or 1 if the array is empty.

### <code>array_mean <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the mean (average) of values in a nonempty array.
