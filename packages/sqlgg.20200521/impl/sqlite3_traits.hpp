/*
  Sqlite3 C++ traits for sqlgg
  by ygrek
  2014-06-08

  This is free and unencumbered software released into the public domain.

  Anyone is free to copy, modify, publish, use, compile, sell, or
  distribute this software, either in source code form or as a compiled
  binary, for any purpose, commercial or non-commercial, and by any
  means.

  For more information, please refer to <http://unlicense.org/>
*/

#include <sqlite3.h>
#if defined(_UNICODE)
#define TCHAR wchar_t
#define SQLGG_STR(x) L##x
#else
#define TCHAR char
#define SQLGG_STR(x) x
#endif
#include <assert.h>
#include <stdio.h>
#include <string>

struct sqlite3_traits
{
  typedef int Int;
  typedef std::basic_string<TCHAR> Text;
  typedef Text Any;

  typedef sqlite3_stmt* row;
  typedef sqlite3* connection;

  static void get_column_Int(row r, int index, Int& val)
  {
     val = sqlite3_column_int(r, index);
  }

  static void get_column_Text(row r, int index, Text& val)
  {
  #if defined(_UNICODE) || defined(UNICODE)
     val = (const TCHAR*)sqlite3_column_text16(r, index);
  #else
     val = (const TCHAR*)sqlite3_column_text(r, index);
  #endif
  }

  static void set_param(row r, const Text& val, int index)
  {
  #if defined(_UNICODE) || defined(UNICODE)
      int nResult = sqlite3_bind_text16(r, index + 1, val.c_str(), -1, SQLITE_TRANSIENT);
  #else
      int nResult = sqlite3_bind_text(r, index + 1, val.c_str(), -1, SQLITE_TRANSIENT);
  #endif
      assert(SQLITE_OK == nResult);
  }

  static void set_param(row r, const Int& val, int index)
  {
      int nResult = sqlite3_bind_int(r, index + 1, val);
      assert(SQLITE_OK == nResult);
  }

  class statement
  {
  private:
    row stmt;
    connection db;
    TCHAR const* sql;

  public:
    statement(connection db, TCHAR const* sql) : db(db), sql(sql)
    {
      stmt = NULL;
    }

    void finish()
    {
      if (NULL != stmt)
      {
        sqlite3_finalize(stmt);
        stmt = NULL;
      }
    }

    virtual ~statement()
    {
      finish();
    }

    bool prepare()
    {
      if (NULL != stmt)
      {
        return true; // already prepared
      }

      int nResult;
      TCHAR const* pszTail;
#if defined(_UNICODE) || defined(UNICODE)
      nResult = sqlite3_prepare16(db, sql, -1, &stmt, (void const**)&pszTail);
#else
      nResult = sqlite3_prepare(db, sql, -1, &stmt, &pszTail);
#endif

      if (SQLITE_OK != nResult)
      {
#if defined(SQLGG_DEBUG)
        printf("sqlite3_prepare error (%u):%s\n%s\n",nResult,sqlite3_errmsg(db),sql);
#endif
        assert(false);
        return false;
      }

      return true;
    }

    template<class T, class Binder, class Params>
    bool select(T result, Binder binder, Params params)
    {
      prepare();

      if (NULL == stmt)
      {
        assert(false);
        return false;
      }

      sqlite3_reset(stmt);
      sqlite3_clear_bindings(stmt);

      params.set_params(stmt);

      while (SQLITE_ROW == sqlite3_step(stmt)) // iterate all objects
      {
          binder.get(stmt,result);
      }

      return true;
    }

    template<class Params>
    int execute(Params params)
    {
      int nResult;

      prepare();

      if (NULL == stmt)
      {
        assert(false);
        return false;
      }

      sqlite3_reset(stmt);
      sqlite3_clear_bindings(stmt);

      params.set_params(stmt);

      //Execute the command
      nResult = sqlite3_step(stmt);
      assert(SQLITE_DONE == nResult);

      return nResult;
    }

  }; // statement

  struct no_params
  {
    void set_params(row) {}
  };

}; // sqlite3_traits
