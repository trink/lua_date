-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

require "date"
require "string"


local errors = {
    {function() date.time(true) end               , "test.lua:10: bad argument #1 to 'time' (string, table, none expected, got boolean)"},
}

for i, v in ipairs(errors) do
    local ok, err = pcall(v[1])
    if ok or err ~= v[2]then
        error(tostring(i) .. " " .. tostring(err))
    end
end

local now = date.time()
local now1 = date.time()
assert(now1 >= now)
print(date.format(now, "%Y-%m-%d %H:%M:%S %Z"))
print(date.format(now, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles"))

local t = date.time("2017-07-16 17:00:00.123456", "%Y-%m-%d %H:%M:%S", "America/Los_Angeles")
assert(1.500249600123456e+18 == t, tostring(t))
local s = date.format(t, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-07-16 17:00:00.123456000 PDT" == s, s)
s = date.format(t, "%Y-%m-%d %H:%M:%S %Z")
assert("2017-07-17 00:00:00.123456000 UTC" == s, s)
s = date.format(t, "%c", "America/Los_Angeles", "en_US.utf8")
assert(s:match("^Sun 16 Jul 2017 05:00:00 PM"), s) -- %c doesn't set the TZ correctly
s = date.format(t, "%c", "Europe/Paris", "fr_FR.utf8")
assert(s:match("^lun. 17 juil. 2017 02:00:00"), s)
-- sadly the format cannot round trip
local t2 = date.time("lun. 17 juil. 2017 02:00:00 CEST", "%a %d %b %Y %H:%M:%S %Z", "Europe/Paris", "fr_FR")
s = date.format(t2, "%Y-%m-%d %H:%M:%S %Z")
assert("2017-07-17 00:00:00.000000000 UTC" == s, s)

local t1 = date.time({year = 2017, month = 7, day = 16, hour = 17, min = 0, sec = 0, sec_frac = 0.123456}, "America/Los_Angeles")
assert(t == t1)

local t3 = date.time("2017-07-16 17:16:15.14", "%Y-%m-%d %H:%M:%S", "America/Los_Angeles")
local t4 = date.floor(t3, "day", "America/Los_Angeles")
assert(1.5001884e+18 == t4, tostring(t4))
t4 = date.floor(t3)
assert(1.5002496e+18 == t4, tostring(t4))
t4 = date.floor(t3, "hour")
assert(1.5002496e+18 == t4, tostring(t4))
t4 = date.floor(t3, "minute")
assert(1.50025056e+18 == t4, tostring(t4))
t4 = date.floor(t3, "second")
assert(1.500250575e+18 == t4, tostring(t4))

local tm = date.get(t3, {}, "America/Los_Angeles")
assert(tm.year == 2017, tostring(tm.year))
assert(tm.month == 7, tostring(tm.month))
assert(tm.day == 16, tostring(tm.day))
assert(tm.hour == 17, tostring(tm.hour))
assert(tm.min == 16, tostring(tm.min))
assert(tm.sec == 15, tostring(tm.sec))
assert(tm.sec == 15, tostring(tm.sec))
assert(tm.sec_frac == 0.14, tostring(tm.sec_frac))
assert(tm.wday == 1, tostring(tm.wday))

local wday = date.get(t3, "wday")
assert(wday == 2, tostring(wday))

-- test wrapping
local tbl = {year = 2017, month = 8, day = 31, hour = 23, min = 59, sec = 59, sec_frac = 0.9}
local t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-08-31 23:59:59.900000000 PDT" == s, s)

tbl = {year = 2017, month = 9, day = 31, hour = 23, min = 59, sec = 59, sec_frac = 0.9}
t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-10-01 23:59:59.900000000 PDT" == s, s)

tbl = {year = 2017, month = 8, day = 32, hour = 23, min = 59, sec = 59, sec_frac = 0.9}
t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-09-01 23:59:59.900000000 PDT" == s, s)

tbl = {year = 2017, month = 8, day = 31, hour = 24, min = 59, sec = 59, sec_frac = 0.9}
t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-09-01 00:59:59.900000000 PDT" == s, s)

tbl = {year = 2017, month = 8, day = 31, hour = 23, min = 60, sec = 59, sec_frac = 0.9}
t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-09-01 00:00:59.900000000 PDT" == s, s)

tbl = {year = 2017, month = 8, day = 31, hour = 23, min = 59, sec = 59, sec_frac = 1}
t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-09-01 00:00:00.000000000 PDT" == s, s)

tbl = {year = 2017, month = 8, day = 31, hour = -1, min = 0, sec = 0}
t5 = date.time(tbl, "America/Los_Angeles")
s = date.format(t5, "%Y-%m-%d %H:%M:%S %Z", "America/Los_Angeles")
assert("2017-08-30 23:00:00.000000000 PDT" == s, s)

tbl = {year = 2017, month = 3, day = 12}
local pre = date.time(tbl, "America/Los_Angeles")
tbl.day = tbl.day + 1
local post = date.time(tbl, "America/Los_Angeles")
assert(post - pre == 82800000000000, tostring(post - pre)) -- change to PDT

tbl = {year = 2017, month = 11, day = 5}
pre = date.time(tbl, "America/Los_Angeles")
tbl.day = tbl.day + 1
post = date.time(tbl, "America/Los_Angeles")
assert(post - pre == 90000000000000, tostring(post - pre)) -- change to PST
