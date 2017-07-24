# Lua Date Module

## Overview
Lua wrapper for the [date/tz](https://github.com/HowardHinnant/date)
extensions based on chrono.

[Full Documentation](http://trink.github.io/lua_date)

## Installation

### Prerequisites
* C compiler (GCC 5.0+)
* CMake (3.3+) - http://cmake.org/cmake/resources/software.html
* Git - http://git-scm.com/download

#### Optional (used for documentation)
* gitbook (2.3) - https://www.gitbook.com/

### CMake Build Instructions

    git clone --recursive https://github.com/trink/lua_date.git
    cd lua_date
    git submodule init
    git submodule update
    mkdir release
    cd release

    # UNIX
    cmake -DCMAKE_BUILD_TYPE=Release -DCPACK_GENERATOR=[TGZ|RPM|DEB] ..
    make
    ctest
    make packages

    #install packages

### Configuration
The default path for the IANA time zone files is `/usr/share/iana/tzdata`. To
specify a different location set the `IANA_TZDATA` environment variable to the
correct path.

## Example Usage

```lua
require "date"

local t = date.time("2017-07-16 17:00:00.123456", "%Y-%m-%d %H:%M:%S", "America/Los_Angeles")
-- t == 1.500249600123456e+18
```

## Module

### Functions

#### floor

```lua
local ft = date.floor(t, "day", "America/Los_Angeles")
-- ft == 1.5001884e+18
```

Returns the number of nanoseconds since the Unix epoch rounded down the nearest
unit.

*Arguments*
- time (number) Nanoseconds since the Unix epoch
- tz (string/none/nil) Time zone name defaults to UTC
- unit (none/nil/string) "day|hour|minute|second" (default: "day")

*Return*
- time_ns (number) Nanoseconds

#### format

```lua
local s = date.format(t, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
-- s == "2017-07-16 17:00:00.123456000 PDT"
```

Returns the data/time strftime formatted string.

*Arguments*
- time (number) Nanoseconds since the Unix epoch
- format (string) strftime specification
- tz (string/none/nil) Time zone name defaults to UTC
- locale (string/none/nil) Time zone name defaults to C

*Return*
- date (string) Human readable date/time

#### get

```lua
local h = date.get(t, "hour", "America/Los_Angeles")
-- h == 17
```

Returns the specified component of the time.

*Arguments*
- time (number) Nanoseconds since the Unix epoch
- component (string/table) "year|month|day|hour|min|sec|sec_frac|wday"
  - specifying a table returns all components in the table
- tz (string/none/nil) Time zone name defaults to UTC

*Return*
- value (number/table) The returned table is compatible with the time() function

#### time
```lua
require "date"
local t  = date.time("2017-07-16 17:00:00.123456", "%Y-%m-%d %H:%M:%S", "America/Los_Angeles")
local t1 = date.time({year = 2017, month = 07, day = 16, hour = 0, min = 0, sec = 0, sec_frac = 0.123456})
local t2 = date.time() -- current time
```

Returns the number of nanoseconds since the Unix epoch.

*Arguments*
- date (string/table/none)
    - `string` Human readable time string
    - `table` Fields: year, month, day, hour, min, sec, sec_frac
    - `none` Returns the current time
- format (string) Conditional strftime specification when the provided `time`
parameter is a string type
- tz (string/none/nil) Time zone name defaults to UTC
- locale (string/none/nil) Time zone name defaults to C

*Return*
- time_ns (number) Nanoseconds
