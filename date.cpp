/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/** @brief Lua date library wrapper implementation @file */

extern "C"
{
#include "lauxlib.h"
#include "lua.h"

int luaopen_date(lua_State *lua);
}

#include <chrono>
#include <exception>
#include <locale>
#include <sstream>

#include "date.h"
#include "tz.h"

using local_ns = date::local_time<std::chrono::nanoseconds>;
using sys_ns   = date::sys_time<std::chrono::nanoseconds>;


static int get_int(lua_State *lua, int idx, const char *key)
{
  lua_getfield(lua, idx, key);
  int i = static_cast<int>(lua_tointeger(lua, -1));
  lua_pop(lua, 1);
  return i;
}


static double get_double(lua_State *lua, int idx, const char *key)
{
  lua_getfield(lua, idx, key);
  double d = lua_tonumber(lua, -1);
  lua_pop(lua, 1);
  return d;
}


static int date_time(lua_State *lua)
{
  int tz_idx = 2;
  int t = lua_type(lua, 1);
  switch (t) {
  case LUA_TSTRING:
    luaL_checktype(lua, 2, LUA_TSTRING);
    tz_idx = 3;
    break;
  case LUA_TTABLE:
  case LUA_TNONE:
    break;
  default:
    return luaL_typerror(lua, 1, "string, table, none");
  }
  int tz_type = lua_type(lua, tz_idx);
  if (tz_type != LUA_TNONE && tz_type != LUA_TNIL && tz_type != LUA_TSTRING) {
    return luaL_typerror(lua, tz_idx, "none, nil, string");
  }
  const char *tzn = luaL_optstring(lua, tz_idx, "UTC");

  bool err = false;
  try {
    using namespace std::chrono;
    auto tz  = date::locate_zone(tzn);
    auto loc = std::locale(luaL_optstring(lua, tz_idx + 1, "C"));
    date::zoned_time<nanoseconds> zt;
    switch (t) {
    case LUA_TSTRING:
      {
        std::istringstream iss{lua_tostring(lua, 1)};
        iss.imbue(loc);
        local_ns lt;
        iss >> date::parse(lua_tostring(lua, 2), lt);
        if (bool(iss)) {
          zt = date::make_zoned(tz, lt);
        } else {
          lua_pushstring(lua, "parse failed");
          err = true;
        }
      }
      break;
    case LUA_TTABLE:
      {
        int y = get_int(lua, 1, "year");
        int m = get_int(lua, 1, "month");
        int d = get_int(lua, 1, "day");
        auto ymd = date::year(y) / m / d;
        if (!ymd.ok()) {
          ymd = date::sys_days{ymd};
        }

        int h = get_int(lua, 1, "hour");
        int M = get_int(lua, 1, "min");
        int s = get_int(lua, 1, "sec");
        double sf = get_double(lua, 1, "sec_frac");
        long int ns = static_cast<long int>(sf * 1e9);
        auto tp = date::local_days(ymd) + hours(h) + minutes(M) + seconds(s) + nanoseconds(ns);
        zt = date::make_zoned(tz, tp);
      }
      break;
    case LUA_TNONE:
      zt = date::make_zoned(tz, high_resolution_clock::now());
      break;
    }
    if (!err) {
      lua_pushnumber(lua, duration_cast<nanoseconds>(zt.get_sys_time().time_since_epoch()).count());
    }
  } catch (std::exception &e) {
    lua_pushstring(lua, e.what());
    err = true;
  } catch (...) {
    lua_pushstring(lua, "unknown zoned_time creation error");
    err = true;
  }
  return err ? lua_error(lua) : 1;
}


static int date_format(lua_State *lua)
{
  double d = luaL_checknumber(lua, 1);
  const char *fmt = luaL_checkstring(lua, 2);
  const char *tzn = luaL_optstring(lua, 3, "UTC");
  const char *ln = luaL_optstring(lua, 4, "C");

  bool err = false;
  try {
    auto tz  = date::locate_zone(tzn);
    auto loc = std::locale(ln);
    long int ns = static_cast<long int>(d);
    auto zt = date::make_zoned(tz, sys_ns(std::chrono::nanoseconds(ns)));
    std::ostringstream oss;
    oss << date::format(loc, fmt, zt);
    lua_pushstring(lua, oss.str().c_str());
  } catch (std::exception &e) {
    lua_pushstring(lua, e.what());
    err = true;
  } catch (...) {
    lua_pushstring(lua, "unknown format error");
    err = true;
  }
  return err ? lua_error(lua) : 1;
}


static int date_floor(lua_State *lua)
{
  using namespace date;
  using namespace std::chrono;
  static const char *options[] = { "day", "hour", "minute", "second", NULL };

  double d = luaL_checknumber(lua, 1);
  int unit = luaL_checkoption(lua, 2, "day", options);
  const char *tzn = luaL_optstring(lua, 3, "UTC");

  bool err = false;
  try {
    auto tz  = date::locate_zone(tzn);
    long int ns = static_cast<long int>(d);
    auto zt = date::make_zoned(tz, sys_ns(std::chrono::nanoseconds(ns)));
    switch (unit) {
    case 0:
      zt = floor<days>(zt.get_local_time());
      break;
    case 1:
      zt = floor<hours>(zt.get_local_time());
      break;
    case 2:
      zt = floor<minutes>(zt.get_local_time());
      break;
    case 3:
      zt = floor<seconds>(zt.get_local_time());
      break;
    }
    long int i = zt.get_sys_time().time_since_epoch().count();
    lua_pushnumber(lua, static_cast<double>(i));
  } catch (std::exception &e) {
    lua_pushstring(lua, e.what());
    err = true;
  } catch (...) {
    lua_pushstring(lua, "unknown format error");
    err = true;
  }
  return err ? lua_error(lua) : 1;
}

static int date_get(lua_State *lua)
{
  using namespace date;
  using namespace std::chrono;
  static const char *options[] = { "year", "month", "day", "hour", "min", "sec", "sec_frac", "wday", NULL };

  double d = luaL_checknumber(lua, 1);
  int comp = -1;
  int t = lua_type(lua, 2);
  switch (t) {
  case LUA_TTABLE:
    break;
  case LUA_TSTRING:
    comp = luaL_checkoption(lua, 2, NULL, options);
    break;
  default:
    return luaL_typerror(lua, 2, "table, string");
  }
  const char *tzn = luaL_optstring(lua, 3, "UTC");

  bool err = false;
  try {
    auto tz  = date::locate_zone(tzn);
    long int ns = static_cast<long int>(d);
    auto zt = date::make_zoned(tz, sys_ns(std::chrono::nanoseconds(ns)));
    auto date = floor<days>(zt.get_local_time());
    switch (comp) {
    case 0:
      {
        auto ymd = year_month_day(date);
        lua_pushnumber(lua, static_cast<lua_Number>(int(ymd.year())));
      }
      break;
    case 1:
      {
        auto ymd = year_month_day(date);
        lua_pushnumber(lua, static_cast<lua_Number>(unsigned(ymd.month())));
      }
      break;
    case 2:
      {
        auto ymd = year_month_day(date);
        lua_pushnumber(lua, static_cast<lua_Number>(unsigned(ymd.day())));
      }
      break;
    case 3:
      {
        auto tod = make_time(zt.get_local_time() - date);
        lua_pushnumber(lua, static_cast<lua_Number>(tod.hours().count()));
      }
      break;
    case 4:
      {
        auto tod = make_time(zt.get_local_time() - date);
        lua_pushnumber(lua, static_cast<lua_Number>(tod.minutes().count()));
      }
      break;
    case 5:
      {
        auto tod = make_time(zt.get_local_time() - date);
        lua_pushnumber(lua, static_cast<lua_Number>(tod.seconds().count()));
      }
      break;
    case 6:
      {
        long int i = zt.get_sys_time().time_since_epoch().count();
        zt = floor<seconds>(zt.get_local_time());
        i -= zt.get_sys_time().time_since_epoch().count();
        lua_pushnumber(lua, static_cast<lua_Number>(i) / 1e9);
      }
      break;
    case 7:
      {
        lua_Number tmp = static_cast<lua_Number>(unsigned(year_month_weekday(date).weekday_indexed().weekday()) + 1);
        lua_pushnumber(lua, tmp);
      }
      break;
    default:
      {
        lua_pushvalue(lua, 2);
        auto ymd = year_month_day(date);
        lua_Number tmp = static_cast<lua_Number>(unsigned(year_month_weekday(date).weekday_indexed().weekday()) + 1);
        lua_pushnumber(lua, tmp);
        lua_setfield(lua, -2, "wday");

        lua_pushnumber(lua, static_cast<lua_Number>(int(ymd.year())));
        lua_setfield(lua, -2, "year");
        tmp = static_cast<lua_Number>(unsigned(ymd.month()));
        lua_pushnumber(lua, tmp);
        lua_setfield(lua, -2, "month");
        tmp = static_cast<lua_Number>(unsigned(ymd.day()));
        lua_pushnumber(lua, tmp);
        lua_setfield(lua, -2, "day");

        auto tod = make_time(zt.get_local_time() - date);
        lua_pushnumber(lua, static_cast<lua_Number>(tod.hours().count()));
        lua_setfield(lua, -2, "hour");
        lua_pushnumber(lua, static_cast<lua_Number>(tod.minutes().count()));
        lua_setfield(lua, -2, "min");
        lua_pushnumber(lua, static_cast<lua_Number>(tod.seconds().count()));
        lua_setfield(lua, -2, "sec");

        long int i = zt.get_sys_time().time_since_epoch().count();
        zt = floor<seconds>(zt.get_local_time());
        i -= zt.get_sys_time().time_since_epoch().count();
        lua_pushnumber(lua, static_cast<lua_Number>(i) / 1e9);
        lua_setfield(lua, -2, "sec_frac");
      }
      break;
    }
  } catch (std::exception &e) {
    lua_pushstring(lua, e.what());
    err = true;
  } catch (...) {
    lua_pushstring(lua, "unknown format error");
    err = true;
  }
  return err ? lua_error(lua) : 1;
}


static const struct luaL_reg date_f[] =
{
  { "floor", date_floor },
  { "format", date_format },
  { "get", date_get },
  { "time", date_time },
  { NULL, NULL }
};



#if __GNUC__ >= 4
__attribute__((visibility("default")))
#endif
int luaopen_date(lua_State *lua)
{
  luaL_register(lua, "date", date_f);
  char *tzdata = getenv("IANA_TZDATA");
  if (tzdata) {
    date::set_install(tzdata);
  }
  return 1;
}
