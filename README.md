# modify-file

Basic Vala CSV database demo - Nothing fancy here.

## Setup

For this program to work, you need to at least two files in the directory
that you run the program in:

**hits.csv**

```csv
url,hits
$insert_string_here,$insert_number_here
$insert_string_here,$insert_number_here
```
Underneath "url,hits", each line should be a string followed by a comma (,) and
a number.

**pending-hits.csv**

```csv
$insert_string_here
$insert_string_here
$insert_string_here
```
Each line needs to be a string.

## Installation

In the root of the project run these commands in your terminal:

```bash
meson build -D prefix=/usr
ninja build -C install
```

Now you can run the program with this command:

```bash
modify-file
```
