# RGBDS arrays

A [RGBDS](https://rgbds.gbdev.io) macro pack that provides array-like functionality.

The latest version is **1.4**.

## Usage

Download [`arrays.inc`](arrays.inc), `INCLUDE` it in your project, and then you can use the macros.
See "[Macros](#macros)" below for documentation of each macro, or [`example.asm`](example.asm) for demonstrations of how they're used.

Arrays are really just groups of associated numeric and string symbols. If <code><i>arr</i></code> is an array, that means all these constants are defined:

- <b><code><i>arr</i>#len</code>:</b> An `equ` constant for the array's length.
- <b><code><i>arr</i>#base</code>:</b> An `equ` constant for the array's base index (it's 0 by default).
- <b><code><i>arr</i>{<i>idx</i>}</code>:</b> The array's items, for <code><i>idx</i></code> from <code><i>arr</i>#base</code> to <code><i>arr</i>#base + <i>arr</i>#len - 1</code>.
- <b><code><i>arr</i>#equ</code>:</b> An internal `equs` constant for whether the array's items are `=` variables, `equ` constants, or `equs` strings (they're `=` variables by default).
- <b><code><i>arr</i>#cmp</code>:</b> An internal `equs` constant for conveniently comparing the array's items, whether they're numeric (with `==` and `!=`) or strings (with `===` and `!==`).

If an array's items are `=` variables, they can be freely `def`ined to different values; for example; `def arr$3 = 42`, or `def arr{idx} = 42` when `idx == 3`. If they're `equ` or `equs` constants, they can still be `redef`ined. But you should probably leave the other symbols alone, and only modify them via the `arrays.inc` macros. (Or if you do modify them yourself, be careful to keep them all consistent.)

You're likely to leave the arrays' base index as its default 0, or set it once for all arrays with `use_array_base`. So the only constant in the above list that you really need to use is <code><i>arr</i>#len</code>. For example, if your array `stats` is 0-indexed and has `=` variable items, here's how to multiply each item by 2:

```asm
for idx, stats#len
    def stats{idx} *= 2
endr
```

(Remember, `{braces}` *interpolate* their contents, and numeric symbols expand to `$`-prefixed uppercase hexadecimal. So `stats{idx}` will count `stats$0`, `stats$1`, ...`stats$9`, `stats$A`, `stats$B`, etc.)

Or if your array `names` is 1-indexed and has `equs` string items, here's how to make each item uppercase:

```asm
for idx, 1, names#len + 1
    redef names{idx} equs strupr(#names{idx})
endr
```

(Remember, in RGBDS v0.x and v1.x, the names of string constants *expand* to their contents, so you have to prefix them with `#` to make them *raw identifiers* which don't expand like that.)

## Macros

There are dozens of potentially-useful macros, so they're broken into categories:

1. **[Configuration](#1-configuration):**
   [`check_arrays_inc_min_version`](#check_arrays_inc_min_version-majorminor),
   [`use_array_base`](#use_array_base-base),
   [`use_variable_arrays`](#use_variable_arrays),
   [`use_constant_arrays`](#use_constant_arrays),
   [`use_string_arrays`](#use_string_arrays)
2. **[Definition](#2-definition):**
   [`def_array`](#def_array-name-values),
   [`def_array_fill`](#def_array_fill-name-length--value--0),
   [`def_array_range`](#def_array_range-name--start--0-stop--step--1),
   [`def_array_copy`](#def_array_copy-name-other),
   [`def_array_concat`](#def_array_concat-name-others),
   [`def_array_slice`](#def_array_slice-name-other-start-pos--end-pos),
   [`array_purge`](#array_purge-names)
3. **[Output](#3-output):**
   [`array_db`](#array_db-name),
   [`array_dw`](#array_dw-name),
   [`array_dl`](#array_dl-name),
   [`array_print`](#array_print-name),
   [`array_println`](#array_println-name)
4. **[Accessing](#4-accessing):**
   [`array_get`](#array_get-result-name-index),
   [`array_set`](#array_set-name-index-value),
   [`array_contains`](#array_contains-result-name-value),
   [`array_find`](#array_find-result-name-value),
   [`array_rfind`](#array_rfind-result-name-value),
   [`array_count`](#array_count-result-name-value)
5. **[Resizing](#5-resizing):**
   [`array_insert`](#array_insert-name-index-values),
   [`array_delete`](#array_delete-name-index),
   [`array_append`](#array_append-name-values),
   [`array_prepend`](#array_prepend-name-values),
   [`array_pop`](#array_pop-result-name),
   [`array_shift`](#array_shift-result-name),
   [`array_extend`](#array_extend-name-others),
   [`array_slice`](#array_slice-name-start-pos--end-pos),
   [`array_clear`](#array_clear-name),
   [`array_pad`](#array_pad-name-length--value--0),
   [`array_lpad`](#array_lpad-name-length--value--0)
6. **[Editing](#6-editing):**
   [`array_replace`](#array_replace-name-old-new--limit),
   [`array_rreplace`](#array_rreplace-name-old-new--limit),
   [`array_remove`](#array_remove-name-value--limit),
   [`array_rremove`](#array_rremove-name-value--limit),
   [`array_dedup`](#array_dedup-name),
   [`array_unique`](#array_unique-name)
7. **[Ordering](#7-ordering):**
   [`array_reverse`](#array_reverse-name),
   [`array_rotate`](#array_rotate-name-amount),
   [`array_sort`](#array_sort-name),
   [`array_rsort`](#array_rsort-name)
8. **[Randomness](#8-randomness):**
   [`array_reseed`](#array_reseed-seed),
   [`array_shuffle`](#array_shuffle-name),
   [`array_pick`](#array_pick-result-name)
9. **[Predicates](#9-predicates):**
   [`array_assert_equal`](#array_assert_equal-name-values),
   [`array_is_sorted`](#array_is_sorted-result-name),
   [`array_is_rsorted`](#array_is_rsorted-result-name),
   [`array_is_equal`](#array_is_equal-result-name-values),
   [`array_are_all_equal`](#array_are_all_equal-result-name),
   [`array_are_all_unique`](#array_are_all_unique-result-name)
10. **[Aggregates](#10-aggregates):**
   [`array_min`](#array_min-result-name),
   [`array_max`](#array_max-result-name),
   [`array_argmin`](#array_argmin-result-name),
   [`array_argmax`](#array_argmax-result-name),
   [`array_sum`](#array_sum-result-name),
   [`array_product`](#array_product-result-name),
   [`array_mean`](#array_mean-result-name),
   [`array_join`](#array_join-result-name--sep--)

### 1. Configuration

#### <code>check_arrays_inc_min_version <i>&lt;major&gt;</i>[.<i>&lt;minor&gt;</i>]</code>

Check whether this library version meets a minimum required one.

#### <code>use_array_base <i>&lt;base&gt;</i></code>

Set the base index for subsequently defined arrays.
Typically 0 or 1, but higher non-negative bases are also technically valid.

#### `use_variable_arrays`

Set subsequently defined arrays to have variable items (mutable, `=`).

#### `use_constant_arrays`

Set subsequently defined arrays to have constant items (immutable, `equ`).

#### `use_string_arrays`

Set subsequently defined arrays to have string items (immutable, `equs`).
String arrays are not compatible with functions that require numeric items
(`def_array_range`, `array_product`, and `array_mean`),
but are uniquely compatible with functions that require string items
(`array_join`).

### 2. Definition

Each of these `def_array*` macros redefines <b><code>def_array_item <i>&lt;...values&gt;</i></code></b> to append values to its array. So for example, you can define an array all at once:

```asm
def_array squares, 1, 4, 9, 16
```

Or one item at a time:

```asm
def_array squares
def_array_item 1
def_array_item 4
def_array_item 9
def_array_item 16
```

#### <code>def_array <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Defines a new array, initializing it with zero or more values.

#### <code>def_array_fill <i>&lt;name&gt;</i>, <i>&lt;length&gt;</i> [, <i>&lt;value&gt;</i> = 0/""]</code>

Defines a new array, initializing it to be filled with N of the same value,
or with N zeros (or empty strings for string arrays) if the value is unspecified.

#### <code>def_array_range <i>&lt;name&gt;</i> [, <i>&lt;start&gt;</i> = 0], <i>&lt;stop&gt;</i> [, <i>&lt;step&gt;</i> = 1]</code>

Defines a new array, initializing it to be an arithmetic sequence.

- <b><code>def_array_range <i>&lt;name&gt;</i>, <i>&lt;stop&gt;</i></code></b>
  gives the half-open interval [0, <i>&lt;stop&gt;</i>).
- <b><code>def_array_range <i>&lt;name&gt;</i>, <i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i></code></b>
  gives the half-open interval [<i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i>).
- <b><code>def_array_range <i>&lt;name&gt;</i>, <i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i>, <i>&lt;step&gt;</i></code></b>
  gives the half-open interval [<i>&lt;start&gt;</i>, <i>&lt;stop&gt;</i>), skipping by <i>&lt;step&gt;</i>.

#### <code>def_array_copy <i>&lt;name&gt;</i>, <i>&lt;other&gt;</i></code>

Defines a new array as a copy of another array.

#### <code>def_array_concat <i>&lt;name&gt;</i>, <i>&lt;...others&gt;</i></code>

Defines a new array as a concatenation of other arrays.

#### <code>def_array_slice <i>&lt;name&gt;</i>, <i>&lt;other&gt;</i>, <i>&lt;start pos&gt;</i> [, <i>&lt;end pos&gt;</i>]</code>

Defines a new array as a slice of another array starting at a position,
and ending before a subsequent position if one is specified.

#### <code>array_purge <i>&lt;...names&gt;</i></code>

Purges an array and all its items.

### 3. Output

#### <code>array_db <i>&lt;name&gt;</i></code>

Declares a `db` byte for each item of an array.

#### <code>array_dw <i>&lt;name&gt;</i></code>

Declares a `dw` word for each item of an array.

#### <code>array_dl <i>&lt;name&gt;</i></code>

Declares a `dl` long for each item of an array.

#### <code>array_print <i>&lt;name&gt;</i></code>

Prints the items of an array, comma-separated between brackets.

#### <code>array_println <i>&lt;name&gt;</i></code>

Prints the items of an array, comma-separated between brackets,
followed by a newline.

### 4. Accessing

#### <code>array_get <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i></code>

Gets the value of an item in an array.

#### <code>array_set <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i>, <i>&lt;value&gt;</i></code>

Sets the value of an item in an array.

#### <code>array_contains <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Checks whether a value exists in an array,
setting the result to 1 if it does or 0 if it does not.

#### <code>array_find <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Find the first index of a value in an array,
or base&nbsp;−&nbsp;1 if the value is not in the array.

#### <code>array_rfind <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Find the last index of a value in an array,
or base&nbsp;−&nbsp;1 if the value is not in the array.

#### <code>array_count <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i></code>

Count the occurrences of a value in an array.

### 5. Resizing

#### <code>array_insert <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i>, <i>&lt;...values&gt;</i></code>

Inserts zero or more values into an array at a given position.

#### <code>array_delete <i>&lt;name&gt;</i>, <i>&lt;index&gt;</i></code>

Deletes an item from an array.

#### <code>array_append <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Appends zero or more values to the end of an array.

#### <code>array_prepend <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Prepends zero or more values to the beginning of an array.

#### <code>array_pop <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Pops the value from the end of a nonempty array.

#### <code>array_shift <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Shifts the value from the beginning of a nonempty array.

#### <code>array_extend <i>&lt;name&gt;</i>, <i>&lt;...others&gt;</i></code>

Extends an array by concatenating other arrays.

#### <code>array_slice <i>&lt;name&gt;</i>, <i>&lt;start pos&gt;</i> [, <i>&lt;end pos&gt;</i>]</code>

Redefines an array to be a slice of itself starting at a position,
and ending before a subsequent position if one is specified.

#### <code>array_clear <i>&lt;name&gt;</i></code>

Removes all items from an array, resetting its length to 0.

#### <code>array_pad <i>&lt;name&gt;</i>, <i>&lt;length&gt;</i> [, <i>&lt;value&gt;</i> = 0/""]</code>

Pads the end of an array up to a minimum length with a given value,
or with zeros (or empty strings for string arrays) if the value is unspecified.

#### <code>array_lpad <i>&lt;name&gt;</i>, <i>&lt;length&gt;</i> [, <i>&lt;value&gt;</i> = 0/""]</code>

Pads the beginning of an array up to a minimum length with a given value,
or with zeros (or empty strings for string arrays) if the value is unspecified.

### 6. Editing

#### <code>array_replace <i>&lt;name&gt;</i>, <i>&lt;old&gt;</i>, <i>&lt;new&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Replace the first N occurrences of one value in an array with another,
or replace all of them if N is unspecified.

#### <code>array_rreplace <i>&lt;name&gt;</i>, <i>&lt;old&gt;</i>, <i>&lt;new&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Replace the last N occurrences of one value in an array with another,
or replace all of them if N is unspecified.

#### <code>array_remove <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Remove the first N occurrences of a value in an array,
or remove all of them if N is unspecified.

#### <code>array_rremove <i>&lt;name&gt;</i>, <i>&lt;value&gt;</i> [, <i>&lt;limit&gt;</i>]</code>

Remove the last N occurrences of a value in an array,
or remove all of them if N is unspecified.

#### <code>array_dedup <i>&lt;name&gt;</i></code>

Deduplicates an array by reducing runs of the same value to one item.

#### <code>array_unique <i>&lt;name&gt;</i></code>

Removes all duplicate items in an array,
leaving only one item per unique value.

### 7. Ordering

#### <code>array_reverse <i>&lt;name&gt;</i></code>

Reverses an array.

#### <code>array_rotate <i>&lt;name&gt;</i>, <i>&lt;amount&gt;</i></code>

Rotates an array right by a positive amount,
or left by a negative amount.

#### <code>array_sort <i>&lt;name&gt;</i></code>

Sorts an array in order from least to greatest.
Uses an 𝒪(<i>n</i> log <i>n</i>) in-place merge sort algorithm.

#### <code>array_rsort <i>&lt;name&gt;</i></code>

Sorts an array in order from greatest to least.
Uses an 𝒪(<i>n</i> log <i>n</i>) in-place merge sort algorithm.

### 8. Randomness

#### <code>array_reseed <i>&lt;seed&gt;</i></code>

Reseed the xorshift32 PRNG used in randomized array macros
(`array_shuffle` and `array_pick`).
The seed cannot be zero, since that would only generate more zeros.

#### <code>array_shuffle <i>&lt;name&gt;</i></code>

Randomly shuffle an array.
Uses the 𝒪(<i>n</i>) Fisher-Yates aka Knuth algorithm.

#### <code>array_pick <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Randomly pick an item from a nonempty array.

### 9. Predicates

#### <code>array_assert_equal <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Asserts that an array's contents have exactly the specified values.

#### <code>array_is_sorted <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether an array is sorted from least to greatest,
setting the result to 1 if it is or 0 if it is not.

#### <code>array_is_rsorted <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether an array is sorted from greatest to least,
setting the result to 1 if it is or 0 if it is not.

#### <code>array_is_equal <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i>, <i>&lt;...values&gt;</i></code>

Checks whether an array's contents have exactly the specified values,
setting the result to 1 if it does or 0 if it does not.

#### <code>array_are_all_equal <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether all the values in an array are equal,
setting the result to 1 if they are or 0 if they are not.

#### <code>array_are_all_unique <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Checks whether all the values in an array are unique,
setting the result to 1 if they are or 0 if they are not.

### 10. Aggregates

#### <code>array_min <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the minimum value in a nonempty array.

#### <code>array_max <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the maximum value in a nonempty array.

#### <code>array_argmin <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the index of a minimum value in a nonempty array.

#### <code>array_argmax <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Find the index of a maximum value in a nonempty array.

#### <code>array_sum <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Take the sum of values in an array,
or 0 if the array is empty.
Not compatible with string arrays.

#### <code>array_product <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Take the product of values in an array,
or 1 if the array is empty.
Not compatible with string arrays.

#### <code>array_mean <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i></code>

Take the mean (average) of values in a nonempty array.
Not compatible with string arrays.

#### <code>array_join <i>&lt;result&gt;</i>, <i>&lt;name&gt;</i> [, <i>&lt;sep&gt;</i> = ""]</code>

Concatenate the string values in an array,
interspersed with a separator if one is specified.
Not compatible with numeric arrays.

## Credits

Inspired by
ISSOtm's [`structs.inc`](https://codeberg.org/ISSOtm/rgbds-structs)
and [`debugfile.inc`](https://codeberg.org/ISSOtm/debugfile.inc),
Evie's [`regex.inc`](https://github.com/eievui5/regex.inc), and
GBDev's [`hardware.inc`](https://github.com/gbdev/hardware.inc).
