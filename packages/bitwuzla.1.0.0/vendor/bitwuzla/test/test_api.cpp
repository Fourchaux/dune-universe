/***
 * Bitwuzla: Satisfiability Modulo Theories (SMT) solver.
 *
 * This file is part of Bitwuzla.
 *
 * Copyright (C) 2007-2021 by the authors listed in the AUTHORS file.
 *
 * See COPYING for more information on using this software.
 */

#include "test.h"

class TestApi : public TestBitwuzla
{
 protected:
  void SetUp() override
  {
    TestBitwuzla::SetUp();

    d_bv_sort1  = bitwuzla_mk_bv_sort(d_bzla, 1);
    d_bv_sort8  = bitwuzla_mk_bv_sort(d_bzla, 8);
    d_bv_sort23 = bitwuzla_mk_bv_sort(d_bzla, 23);
    d_bv_sort32 = bitwuzla_mk_bv_sort(d_bzla, 32);

    d_fp_sort16 = bitwuzla_mk_fp_sort(d_bzla, 5, 11);
    d_fp_sort32 = bitwuzla_mk_fp_sort(d_bzla, 8, 24);
    d_rm_sort   = bitwuzla_mk_rm_sort(d_bzla);

    d_arr_sort_bvfp = bitwuzla_mk_array_sort(d_bzla, d_bv_sort8, d_fp_sort16);
    d_arr_sort_fpbv = bitwuzla_mk_array_sort(d_bzla, d_fp_sort16, d_bv_sort8);
    d_arr_sort_bv   = bitwuzla_mk_array_sort(d_bzla, d_bv_sort32, d_bv_sort8);

    d_fun_domain_sort = {d_bv_sort8, d_fp_sort16, d_bv_sort32};
    d_fun_sort        = bitwuzla_mk_fun_sort(
        d_bzla, d_fun_domain_sort.size(), d_fun_domain_sort.data(), d_bv_sort8);
    d_fun_sort_fp = bitwuzla_mk_fun_sort(d_bzla,
                                         d_fun_domain_sort.size(),
                                         d_fun_domain_sort.data(),
                                         d_fp_sort16);
    d_true        = bitwuzla_mk_true(d_bzla);
    d_bv_one1     = bitwuzla_mk_bv_one(d_bzla, d_bv_sort1);
    d_bv_ones23   = bitwuzla_mk_bv_ones(d_bzla, d_bv_sort23);
    d_bv_mins8    = bitwuzla_mk_bv_min_signed(d_bzla, d_bv_sort8);
    d_bv_maxs8    = bitwuzla_mk_bv_max_signed(d_bzla, d_bv_sort8);
    d_bv_zero8    = bitwuzla_mk_bv_zero(d_bzla, d_bv_sort8);
    d_fp_pzero32  = bitwuzla_mk_fp_pos_zero(d_bzla, d_fp_sort32);
    d_fp_nzero32  = bitwuzla_mk_fp_neg_zero(d_bzla, d_fp_sort32);
    d_fp_pinf32   = bitwuzla_mk_fp_pos_inf(d_bzla, d_fp_sort32);
    d_fp_ninf32   = bitwuzla_mk_fp_neg_inf(d_bzla, d_fp_sort32);
    d_fp_nan32    = bitwuzla_mk_fp_nan(d_bzla, d_fp_sort32);

    d_bv_const1  = bitwuzla_mk_const(d_bzla, d_bv_sort1, "bv_const1");
    d_bv_const8  = bitwuzla_mk_const(d_bzla, d_bv_sort8, "bv_const8");
    d_fp_const16 = bitwuzla_mk_const(d_bzla, d_fp_sort16, "fp_const16");
    d_rm_const   = bitwuzla_mk_const(d_bzla, d_rm_sort, "rm_const");

    d_fun        = bitwuzla_mk_const(d_bzla, d_fun_sort, "fun");
    d_fun_fp     = bitwuzla_mk_const(d_bzla, d_fun_sort_fp, "fun_fp");
    d_array_fpbv = bitwuzla_mk_const(d_bzla, d_arr_sort_fpbv, "array_fpbv");
    d_array      = bitwuzla_mk_const(d_bzla, d_arr_sort_bv, "array");
    d_store      = bitwuzla_mk_term3(d_bzla,
                                BITWUZLA_KIND_ARRAY_STORE,
                                d_array,
                                bitwuzla_mk_const(d_bzla, d_bv_sort32, "store"),
                                d_bv_zero8);

    d_var1      = bitwuzla_mk_var(d_bzla, d_bv_sort8, "var1");
    d_var2      = bitwuzla_mk_var(d_bzla, d_bv_sort8, "var2");
    d_bound_var = bitwuzla_mk_var(d_bzla, d_bv_sort8, "bount_var");
    d_bool_var =
        bitwuzla_mk_var(d_bzla, bitwuzla_mk_bool_sort(d_bzla), "bool_var");

    d_not_bv_const1 = bitwuzla_mk_term1(d_bzla, BITWUZLA_KIND_NOT, d_bv_const1);
    d_and_bv_const1 =
        bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_AND, d_true, d_bv_const1);
    d_eq_bv_const8 =
        bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_EQUAL, d_bv_const8, d_bv_zero8);

    BitwuzlaTerm *lambda_body = bitwuzla_mk_term2(
        d_bzla, BITWUZLA_KIND_BV_ADD, d_bound_var, d_bv_const8);
    d_lambda = bitwuzla_mk_term2(
        d_bzla, BITWUZLA_KIND_LAMBDA, d_bound_var, lambda_body);
    d_bool_lambda_body =
        bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_EQUAL, d_bool_var, d_true);
    d_bool_lambda = bitwuzla_mk_term2(
        d_bzla, BITWUZLA_KIND_LAMBDA, d_bool_var, d_bool_lambda_body);
    d_bool_apply =
        bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_APPLY, d_bool_lambda, d_true);

    /* associated with other Bitwuzla instance */
    d_other_bzla            = bitwuzla_new();
    d_other_bv_sort1        = bitwuzla_mk_bv_sort(d_other_bzla, 1);
    d_other_bv_sort8        = bitwuzla_mk_bv_sort(d_other_bzla, 8);
    d_other_fp_sort16       = bitwuzla_mk_fp_sort(d_other_bzla, 5, 11);
    d_other_fun_domain_sort = {d_other_bv_sort8, d_other_bv_sort8};
    d_other_arr_sort_bv = bitwuzla_mk_array_sort(
        d_other_bzla, d_other_bv_sort8, d_other_bv_sort8);

    d_other_true = bitwuzla_mk_true(d_other_bzla);
    d_other_bv_one1  = bitwuzla_mk_bv_one(d_other_bzla, d_other_bv_sort1);
    d_other_bv_zero8 = bitwuzla_mk_bv_zero(d_other_bzla, d_other_bv_sort8);

    d_other_bv_const8 =
        bitwuzla_mk_const(d_other_bzla, d_other_bv_sort8, "bv_const8");

    d_other_exists_var =
        bitwuzla_mk_var(d_other_bzla, d_other_bv_sort8, "exists_var");
    d_other_exists = bitwuzla_mk_term2(
        d_other_bzla,
        BITWUZLA_KIND_EXISTS,
        d_other_exists_var,
        bitwuzla_mk_term2(d_other_bzla,
                          BITWUZLA_KIND_EQUAL,
                          d_other_bv_zero8,
                          bitwuzla_mk_term2(d_other_bzla,
                                            BITWUZLA_KIND_BV_MUL,
                                            d_other_bv_const8,
                                            d_other_exists_var)));
  }

  void TearDown() override
  {
    bitwuzla_delete(d_other_bzla);
    TestBitwuzla::TearDown();
  }

  /* sorts */
  BitwuzlaSort *d_arr_sort_bv;
  BitwuzlaSort *d_arr_sort_bvfp;
  BitwuzlaSort *d_arr_sort_fpbv;
  BitwuzlaSort *d_bv_sort1;
  BitwuzlaSort *d_bv_sort23;
  BitwuzlaSort *d_bv_sort32;
  BitwuzlaSort *d_bv_sort8;
  BitwuzlaSort *d_fp_sort16;
  BitwuzlaSort *d_fp_sort32;
  BitwuzlaSort *d_fun_sort;
  BitwuzlaSort *d_fun_sort_fp;
  std::vector<BitwuzlaSort *> d_fun_domain_sort;
  BitwuzlaSort *d_rm_sort;

  /* terms */
  BitwuzlaTerm *d_true;
  BitwuzlaTerm *d_bv_one1;
  BitwuzlaTerm *d_bv_ones23;
  BitwuzlaTerm *d_bv_zero8;
  BitwuzlaTerm *d_bv_mins8;
  BitwuzlaTerm *d_bv_maxs8;
  BitwuzlaTerm *d_fp_pzero32;
  BitwuzlaTerm *d_fp_nzero32;
  BitwuzlaTerm *d_fp_pinf32;
  BitwuzlaTerm *d_fp_ninf32;
  BitwuzlaTerm *d_fp_nan32;

  BitwuzlaTerm *d_bv_const1;
  BitwuzlaTerm *d_bv_const8;
  BitwuzlaTerm *d_fp_const16;
  BitwuzlaTerm *d_rm_const;

  BitwuzlaTerm *d_fun;
  BitwuzlaTerm *d_fun_fp;
  BitwuzlaTerm *d_array_fpbv;
  BitwuzlaTerm *d_array;
  BitwuzlaTerm *d_store;

  BitwuzlaTerm *d_var1;
  BitwuzlaTerm *d_var2;
  BitwuzlaTerm *d_bound_var;
  BitwuzlaTerm *d_bool_var;

  BitwuzlaTerm *d_not_bv_const1;
  BitwuzlaTerm *d_and_bv_const1;
  BitwuzlaTerm *d_eq_bv_const8;
  BitwuzlaTerm *d_lambda;
  BitwuzlaTerm *d_bool_lambda;
  BitwuzlaTerm *d_bool_lambda_body;
  BitwuzlaTerm *d_bool_apply;

  /* not associated with d_bzla */
  Bitwuzla *d_other_bzla;
  BitwuzlaSort *d_other_arr_sort_bv;
  BitwuzlaSort *d_other_bv_sort1;
  BitwuzlaSort *d_other_bv_sort8;
  BitwuzlaSort *d_other_fp_sort16;
  std::vector<BitwuzlaSort *> d_other_fun_domain_sort;
  BitwuzlaTerm *d_other_bv_one1;
  BitwuzlaTerm *d_other_bv_zero8;
  BitwuzlaTerm *d_other_exists_var;
  BitwuzlaTerm *d_other_bv_const8;
  BitwuzlaTerm *d_other_true;
  BitwuzlaTerm *d_other_exists;

  /* error messages */
  const char *d_error_not_null = "must not be NULL";
  const char *d_error_solver   = "is not associated with given solver instance";
  const char *d_error_exp_arr_sort   = "expected array sort";
  const char *d_error_exp_bv_sort    = "expected bit-vector sort";
  const char *d_error_exp_fp_sort    = "expected floating-point sort";
  const char *d_error_exp_fun_sort   = "expected function sort";
  const char *d_error_exp_str        = "expected non-empty string";
  const char *d_error_unexp_arr_sort = "unexpected array sort";
  const char *d_error_unexp_fun_sort = "unexpected function sort";
  const char *d_error_zero           = "must be > 0";
  const char *d_error_bv_fit         = "does not fit into a bit-vector of size";
  const char *d_error_exp_bool_term  = "expected boolean term";
  const char *d_error_exp_bv_term    = "expected bit-vector term";
  const char *d_error_exp_bv_value   = "expected bit-vector value";
  const char *d_error_exp_fp_term    = "expected floating-point term";
  const char *d_error_exp_rm_term    = "expected rounding-mode term";
  const char *d_error_exp_arr_term   = "expected array term";
  const char *d_error_exp_fun_term   = "expected function term";
  const char *d_error_exp_var_term   = "expected variable term";
  const char *d_error_exp_assumption = "must be an assumption";
  const char *d_error_rm             = "invalid rounding mode";
  const char *d_error_unexp_arr_term = "unexpected array term";
  const char *d_error_unexp_fun_term = "unexpected function term";
  const char *d_error_unexp_param_term = "term must not be parameterized";
  const char *d_error_incremental      = "incremental usage not enabled";
  const char *d_error_produce_models   = "model production not enabled";
  const char *d_error_unsat            = "if input formula is not unsat";
  const char *d_error_unsat_cores      = "unsat core production not enabled";
  const char *d_error_sat              = "if input formula is not sat";
  const char *d_error_format           = "unknown format";
  const char *d_error_inc_quant =
      "incremental solving is currently not supported with quantifiers";
};

/* -------------------------------------------------------------------------- */
/* Bitwuzla                                                                   */
/* -------------------------------------------------------------------------- */

TEST_F(TestApi, set_option)
{
  Bitwuzla *bzla_inc   = bitwuzla_new();
  Bitwuzla *bzla_dp    = bitwuzla_new();
  Bitwuzla *bzla_just  = bitwuzla_new();
  Bitwuzla *bzla_mg    = bitwuzla_new();
  Bitwuzla *bzla_non   = bitwuzla_new();
  Bitwuzla *bzla_uc    = bitwuzla_new();
  Bitwuzla *bzla_ucopt = bitwuzla_new();

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option(bzla_inc, BITWUZLA_OPT_INCREMENTAL, 1));
  ASSERT_DEATH(bitwuzla_set_option(
                   bzla_inc, BITWUZLA_OPT_PP_UNCONSTRAINED_OPTIMIZATION, 1),
               "unconstrained optimization cannot be enabled in incremental "
               "mode");
  bitwuzla_check_sat(bzla_inc);
  ASSERT_DEATH(bitwuzla_set_option(bzla_inc, BITWUZLA_OPT_INCREMENTAL, 0),
               "enabling/disabling incremental usage after having called "
               "'bitwuzla_check_sat' is not allowed");

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option(bzla_dp, BITWUZLA_OPT_FUN_DUAL_PROP, 1));
  ASSERT_DEATH(bitwuzla_set_option(bzla_dp, BITWUZLA_OPT_FUN_JUST, 1),
               "enabling multiple optimization techniques is not allowed");
  ASSERT_DEATH(
      bitwuzla_set_option(bzla_dp, BITWUZLA_OPT_PP_NONDESTR_SUBST, 1),
      "non-destructive substitution is not supported with dual propagation");

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option(bzla_just, BITWUZLA_OPT_FUN_JUST, 1));
  ASSERT_DEATH(bitwuzla_set_option(bzla_just, BITWUZLA_OPT_FUN_DUAL_PROP, 1),
               "enabling multiple optimization techniques is not allowed");

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option(bzla_mg, BITWUZLA_OPT_PRODUCE_MODELS, 1));
  ASSERT_DEATH(bitwuzla_set_option(
                   bzla_mg, BITWUZLA_OPT_PP_UNCONSTRAINED_OPTIMIZATION, 1),
               "unconstrained optimization cannot be enabled if model "
               "generation is enabled");

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option(bzla_non, BITWUZLA_OPT_PP_NONDESTR_SUBST, 1));
  ASSERT_DEATH(
      bitwuzla_set_option(bzla_non, BITWUZLA_OPT_FUN_DUAL_PROP, 1),
      "non-destructive substitution is not supported with dual propagation");

  ASSERT_NO_FATAL_FAILURE(bitwuzla_set_option(
      bzla_ucopt, BITWUZLA_OPT_PP_UNCONSTRAINED_OPTIMIZATION, 1));
  ASSERT_DEATH(bitwuzla_set_option(bzla_ucopt, BITWUZLA_OPT_INCREMENTAL, 1),
               "incremental solving cannot be enabled if unconstrained "
               "optimization is enabled");
  ASSERT_DEATH(bitwuzla_set_option(bzla_ucopt, BITWUZLA_OPT_PRODUCE_MODELS, 1),
               "model generation cannot be enabled if unconstrained "
               "optimization is enabled");

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option(bzla_uc, BITWUZLA_OPT_PRODUCE_UNSAT_CORES, 1));

  bitwuzla_delete(bzla_inc);
  bitwuzla_delete(bzla_dp);
  bitwuzla_delete(bzla_just);
  bitwuzla_delete(bzla_mg);
  bitwuzla_delete(bzla_non);
  bitwuzla_delete(bzla_uc);
  bitwuzla_delete(bzla_ucopt);
}

TEST_F(TestApi, set_option_str)
{
  Bitwuzla *bzla = bitwuzla_new();

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_set_option_str(bzla, BITWUZLA_OPT_SAT_ENGINE, "cadical"));
  ASSERT_DEATH(bitwuzla_set_option_str(bzla, BITWUZLA_OPT_SAT_ENGINE, "asdf"),
               "invalid option value");
  ASSERT_DEATH(bitwuzla_set_option_str(bzla, BITWUZLA_OPT_INCREMENTAL, "true"),
               "option expects an integer value");

  bitwuzla_delete(bzla);
}

TEST_F(TestApi, mk_array_sort)
{
  ASSERT_DEATH(bitwuzla_mk_array_sort(nullptr, d_bv_sort1, d_bv_sort8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_array_sort(d_bzla, nullptr, d_bv_sort8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_array_sort(d_bzla, d_bv_sort1, nullptr),
               d_error_not_null);

  ASSERT_DEATH(
      bitwuzla_mk_array_sort(d_other_bzla, d_other_bv_sort8, d_bv_sort8),
      d_error_solver);
  ASSERT_DEATH(
      bitwuzla_mk_array_sort(d_other_bzla, d_bv_sort8, d_other_bv_sort8),
      d_error_solver);

  ASSERT_DEATH(bitwuzla_mk_array_sort(d_bzla, d_arr_sort_bv, d_bv_sort8),
               d_error_unexp_arr_sort);
  ASSERT_DEATH(bitwuzla_mk_array_sort(d_bzla, d_bv_sort8, d_arr_sort_bv),
               d_error_unexp_arr_sort);
  ASSERT_DEATH(bitwuzla_mk_array_sort(d_bzla, d_fun_sort, d_bv_sort8),
               d_error_unexp_fun_sort);
  ASSERT_DEATH(bitwuzla_mk_array_sort(d_bzla, d_bv_sort8, d_fun_sort),
               d_error_unexp_fun_sort);
}

TEST_F(TestApi, mk_bool_sort)
{
  ASSERT_DEATH(bitwuzla_mk_bool_sort(nullptr), d_error_not_null);
}

TEST_F(TestApi, mk_bv_sort)
{
  ASSERT_DEATH(bitwuzla_mk_bv_sort(nullptr, 4), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_sort(d_bzla, 0), d_error_zero);
}

TEST_F(TestApi, mk_fp_sort)
{
  ASSERT_DEATH(bitwuzla_mk_fp_sort(nullptr, 5, 8), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_sort(d_bzla, 0, 8), d_error_zero);
  ASSERT_DEATH(bitwuzla_mk_fp_sort(d_bzla, 5, 0), d_error_zero);
}

TEST_F(TestApi, mk_fun_sort)
{
  ASSERT_DEATH(bitwuzla_mk_fun_sort(nullptr,
                                    d_fun_domain_sort.size(),
                                    d_fun_domain_sort.data(),
                                    d_bv_sort8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fun_sort(
                   d_bzla, d_fun_domain_sort.size(), nullptr, d_bv_sort8),
               d_error_not_null);

  std::vector<BitwuzlaSort *> empty = {};
  ASSERT_DEATH(
      bitwuzla_mk_fun_sort(d_bzla, empty.size(), empty.data(), d_bv_sort8),
      d_error_zero);

  ASSERT_DEATH(bitwuzla_mk_fun_sort(d_bzla,
                                    d_other_fun_domain_sort.size(),
                                    d_other_fun_domain_sort.data(),
                                    d_bv_sort8),
               d_error_solver);
  ASSERT_DEATH(bitwuzla_mk_fun_sort(d_bzla,
                                    d_fun_domain_sort.size(),
                                    d_fun_domain_sort.data(),
                                    d_other_bv_sort8),
               d_error_solver);
}

TEST_F(TestApi, mk_rm_sort)
{
  ASSERT_DEATH(bitwuzla_mk_rm_sort(nullptr), d_error_not_null);
}

TEST_F(TestApi, mk_true)
{
  ASSERT_DEATH(bitwuzla_mk_true(nullptr), d_error_not_null);
}

TEST_F(TestApi, mk_false)
{
  ASSERT_DEATH(bitwuzla_mk_false(nullptr), d_error_not_null);
}

TEST_F(TestApi, mk_bv_zero)
{
  ASSERT_DEATH(bitwuzla_mk_bv_zero(nullptr, d_bv_sort8), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_zero(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_zero(d_bzla, d_fp_sort16), d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_zero(d_bzla, d_other_bv_sort8), d_error_solver);
}

TEST_F(TestApi, mk_bv_one)
{
  ASSERT_DEATH(bitwuzla_mk_bv_one(nullptr, d_bv_sort8), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_one(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_one(d_bzla, d_fp_sort16), d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_one(d_bzla, d_other_bv_sort8), d_error_solver);
}

TEST_F(TestApi, mk_bv_ones)
{
  ASSERT_DEATH(bitwuzla_mk_bv_ones(nullptr, d_bv_sort8), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_ones(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_ones(d_bzla, d_fp_sort16), d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_ones(d_bzla, d_other_bv_sort8), d_error_solver);
}

TEST_F(TestApi, mk_bv_min_signed)
{
  ASSERT_DEATH(bitwuzla_mk_bv_min_signed(nullptr, d_bv_sort8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_min_signed(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_min_signed(d_bzla, d_fp_sort16),
               d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_min_signed(d_bzla, d_other_bv_sort8),
               d_error_solver);
}

TEST_F(TestApi, mk_bv_max_signed)
{
  ASSERT_DEATH(bitwuzla_mk_bv_max_signed(nullptr, d_fp_sort16),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_max_signed(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_max_signed(d_bzla, d_fp_sort16),
               d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_max_signed(d_bzla, d_other_bv_sort8),
               d_error_solver);
}

TEST_F(TestApi, mk_fp_pos_zero)
{
  ASSERT_DEATH(bitwuzla_mk_fp_pos_zero(nullptr, d_fp_sort16), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_pos_zero(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_pos_zero(d_bzla, d_bv_sort8),
               d_error_exp_fp_sort);
  ASSERT_DEATH(bitwuzla_mk_fp_pos_zero(d_bzla, d_other_fp_sort16),
               d_error_solver);
}

TEST_F(TestApi, mk_fp_neg_zero)
{
  ASSERT_DEATH(bitwuzla_mk_fp_neg_zero(nullptr, d_fp_sort16), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_neg_zero(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_neg_zero(d_bzla, d_bv_sort8),
               d_error_exp_fp_sort);
  ASSERT_DEATH(bitwuzla_mk_fp_neg_zero(d_bzla, d_other_fp_sort16),
               d_error_solver);
}

TEST_F(TestApi, mk_fp_pos_inf)
{
  ASSERT_DEATH(bitwuzla_mk_fp_pos_inf(nullptr, d_fp_sort16), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_pos_inf(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_pos_inf(d_bzla, d_bv_sort8), d_error_exp_fp_sort);
  ASSERT_DEATH(bitwuzla_mk_fp_pos_inf(d_bzla, d_other_fp_sort16),
               d_error_solver);
}

TEST_F(TestApi, mk_fp_neg_inf)
{
  ASSERT_DEATH(bitwuzla_mk_fp_neg_inf(nullptr, d_fp_sort16), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_neg_inf(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_neg_inf(d_bzla, d_bv_sort8), d_error_exp_fp_sort);
  ASSERT_DEATH(bitwuzla_mk_fp_neg_inf(d_bzla, d_other_fp_sort16),
               d_error_solver);
}

TEST_F(TestApi, mk_fp_nan)
{
  ASSERT_DEATH(bitwuzla_mk_fp_nan(nullptr, d_fp_sort16), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_nan(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_nan(d_bzla, d_bv_sort8), d_error_exp_fp_sort);
  ASSERT_DEATH(bitwuzla_mk_fp_nan(d_bzla, d_other_fp_sort16), d_error_solver);
}

TEST_F(TestApi, mk_bv_value)
{
  ASSERT_DEATH(
      bitwuzla_mk_bv_value(nullptr, d_bv_sort8, "010", BITWUZLA_BV_BASE_BIN),
      d_error_not_null);
  ASSERT_DEATH(
      bitwuzla_mk_bv_value(d_bzla, nullptr, "010", BITWUZLA_BV_BASE_BIN),
      d_error_not_null);
  ASSERT_DEATH(
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort8, nullptr, BITWUZLA_BV_BASE_BIN),
      d_error_exp_str);
  ASSERT_DEATH(
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort8, "", BITWUZLA_BV_BASE_BIN),
      d_error_exp_str);

  ASSERT_DEATH(
      bitwuzla_mk_bv_value(d_bzla, d_fp_sort16, "010", BITWUZLA_BV_BASE_BIN),
      d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_value(
                   d_bzla, d_other_bv_sort8, "010", BITWUZLA_BV_BASE_BIN),
               d_error_solver);

  ASSERT_DEATH(bitwuzla_mk_bv_value(
                   d_bzla, d_bv_sort8, "11111111010", BITWUZLA_BV_BASE_BIN),
               d_error_bv_fit);
  ASSERT_DEATH(bitwuzla_mk_bv_value(
                   d_bzla, d_bv_sort8, "1234567890", BITWUZLA_BV_BASE_DEC),
               d_error_bv_fit);
  ASSERT_DEATH(
      bitwuzla_mk_bv_value(
          d_bzla, d_bv_sort8, "1234567890aAbBcCdDeEfF", BITWUZLA_BV_BASE_HEX),
      d_error_bv_fit);
  ASSERT_DEATH(bitwuzla_mk_bv_value(
                   d_bzla, d_bv_sort8, "1234567890", BITWUZLA_BV_BASE_BIN),
               "invalid binary string");
  ASSERT_DEATH(bitwuzla_mk_bv_value(
                   d_bzla, d_bv_sort8, "12z4567890", BITWUZLA_BV_BASE_DEC),
               "invalid decimal string");
  ASSERT_DEATH(bitwuzla_mk_bv_value(
                   d_bzla, d_bv_sort8, "12z4567890", BITWUZLA_BV_BASE_HEX),
               "invalid hex string");
}

TEST_F(TestApi, mk_bv_value_uint64)
{
  ASSERT_DEATH(bitwuzla_mk_bv_value_uint64(nullptr, d_bv_sort8, 23),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_value_uint64(d_bzla, nullptr, 23),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_bv_value_uint64(d_bzla, d_fp_sort16, 23),
               d_error_exp_bv_sort);
  ASSERT_DEATH(bitwuzla_mk_bv_value_uint64(d_bzla, d_other_bv_sort8, 23),
               d_error_solver);
}

TEST_F(TestApi, mk_fp_value)
{
  ASSERT_DEATH(bitwuzla_mk_fp_value(nullptr, d_bv_one1, d_bv_zero8, d_bv_zero8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_value(d_bzla, nullptr, d_bv_zero8, d_bv_zero8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_value(d_bzla, d_bv_one1, nullptr, d_bv_zero8),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_bv_zero8, nullptr),
               d_error_not_null);

  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_other_bv_one1, d_bv_zero8, d_bv_zero8),
      d_error_solver);
  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_other_bv_zero8, d_bv_zero8),
      d_error_solver);
  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_bv_zero8, d_other_bv_zero8),
      d_error_solver);

  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_bv_zero8, d_bv_zero8, d_bv_zero8),
      "invalid bit-vector size for argument 'bv_sign', expected size one");
  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_fp_const16, d_bv_zero8, d_bv_zero8),
      d_error_exp_bv_term);
  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_fp_const16, d_bv_zero8),
      d_error_exp_bv_term);
  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_bv_zero8, d_fp_const16),
      d_error_exp_bv_term);

  ASSERT_DEATH(
      bitwuzla_mk_fp_value(d_bzla, d_bv_const1, d_bv_zero8, d_bv_zero8),
      d_error_exp_bv_value);
  ASSERT_DEATH(bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_bv_const8, d_bv_zero8),
               d_error_exp_bv_value);
  ASSERT_DEATH(bitwuzla_mk_fp_value(d_bzla, d_bv_one1, d_bv_zero8, d_bv_const8),
               d_error_exp_bv_value);
}

TEST_F(TestApi, mk_rm_value)
{
  ASSERT_DEATH(bitwuzla_mk_rm_value(nullptr, BITWUZLA_RM_RNA),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_MAX), d_error_rm);
}

TEST_F(TestApi, mk_term_check_null)
{
  std::vector<BitwuzlaTerm *> bv_args2 = {d_bv_zero8, d_bv_const8};

  std::vector<BitwuzlaTerm *> null_death_args1 = {nullptr};
  std::vector<BitwuzlaTerm *> null_death_args2 = {d_bv_zero8, nullptr};
  std::vector<BitwuzlaTerm *> null_death_args3 = {
      d_rm_const, nullptr, d_fp_const16};

  // mk_term
  ASSERT_DEATH(
      bitwuzla_mk_term(
          nullptr, BITWUZLA_KIND_BV_AND, bv_args2.size(), bv_args2.data()),
      d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NOT,
                                null_death_args1.size(),
                                null_death_args1.data()),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_AND,
                                null_death_args2.size(),
                                null_death_args2.data()),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_ADD,
                                null_death_args3.size(),
                                null_death_args3.data()),
               d_error_not_null);
  // mk_term1
  ASSERT_DEATH(bitwuzla_mk_term1(nullptr, BITWUZLA_KIND_BV_NOT, d_bv_one1),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_term1(d_bzla, BITWUZLA_KIND_BV_NOT, nullptr),
               d_error_not_null);
  // mk_term2
  ASSERT_DEATH(
      bitwuzla_mk_term2(nullptr, BITWUZLA_KIND_BV_AND, d_bv_zero8, d_bv_const8),
      d_error_not_null);
  ASSERT_DEATH(
      bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_BV_AND, nullptr, d_bv_const8),
      d_error_not_null);
  // mk_term3
  ASSERT_DEATH(bitwuzla_mk_term3(nullptr,
                                 BITWUZLA_KIND_FP_ADD,
                                 d_rm_const,
                                 d_fp_const16,
                                 d_fp_const16),
               d_error_not_null);
  ASSERT_DEATH(
      bitwuzla_mk_term3(
          d_bzla, BITWUZLA_KIND_FP_ADD, nullptr, d_fp_const16, d_fp_const16),
      d_error_not_null);
}

TEST_F(TestApi, mk_term_check_cnt)
{
  const char *error_arg_cnt = "invalid number of arguments";

  std::vector<BitwuzlaTerm *> apply_args1 = {d_bv_one1};
  std::vector<BitwuzlaTerm *> apply_args2 = {d_fun, d_bv_const8};
  std::vector<BitwuzlaTerm *> array_args1 = {d_array_fpbv};
  std::vector<BitwuzlaTerm *> bool_args1  = {d_true};
  std::vector<BitwuzlaTerm *> bool_args2  = {d_true, d_true};
  std::vector<BitwuzlaTerm *> bv_args1    = {d_bv_one1};
  std::vector<BitwuzlaTerm *> bv_args1_rm = {d_rm_const};
  std::vector<BitwuzlaTerm *> bv_args2    = {d_bv_zero8, d_bv_const8};
  std::vector<BitwuzlaTerm *> ite_args2   = {d_true, d_bv_const8};
  std::vector<BitwuzlaTerm *> fp_args1    = {d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args1_rm = {d_rm_const};
  std::vector<BitwuzlaTerm *> fp_args2    = {d_fp_const16, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args2_rm = {d_rm_const, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args3_rm = {
      d_rm_const, d_fp_const16, d_fp_const16};
  std::vector<BitwuzlaTerm *> fun_args1 = {d_var1};

  std::vector<uint32_t> idxs1    = {1};
  std::vector<uint32_t> idxs2    = {2, 0};
  std::vector<uint32_t> fp_idxs2 = {5, 8};

  // bool
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_AND, bool_args1.size(), bool_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_IFF, bool_args1.size(), bool_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_IMPLIES, bool_args1.size(), bool_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_NOT, bool_args2.size(), bool_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_OR, bool_args1.size(), bool_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_XOR, bool_args1.size(), bool_args1.data()),
      error_arg_cnt);

  // bit-vectors
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_APPLY, apply_args1.size(), apply_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_APPLY, apply_args2.size(), apply_args2.data()),
      "number of given arguments to function must match arity of function");
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_SELECT,
                                array_args1.size(),
                                array_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_STORE,
                                array_args1.size(),
                                array_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_ADD, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_AND, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_ASHR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_CONCAT, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_DEC, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_INC, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_MUL, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_NAND, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_NEG, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_NOR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_NOT, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_OR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_REDAND, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_REDOR, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_REDXOR, bv_args2.size(), bv_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_OR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_ROL, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_ROR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SADD_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SDIV_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SDIV, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SGE, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SGT, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SHL, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SHR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SLE, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SLT, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SMOD, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SMUL_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SREM, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SSUB_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_SUB, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UADD_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_UDIV, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_UGE, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_UGT, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_ULE, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_ULT, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UMUL_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_UREM, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_USUB_OVERFLOW,
                                bv_args1.size(),
                                bv_args1.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_XNOR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_BV_XOR, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);

  // floating-point
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_ABS, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_ADD, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_DIV, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_EQ, fp_args1_rm.size(), fp_args1_rm.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_FMA, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_FP, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_GEQ, fp_args1.size(), fp_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_GT, fp_args1.size(), fp_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_INF, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_NAN, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_NEG, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_NORMAL, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_POS, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_SUBNORMAL,
                                fp_args2.size(),
                                fp_args2.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_ZERO, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_LEQ, fp_args1.size(), fp_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_LT, fp_args1.size(), fp_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_MAX, fp_args3_rm.size(), fp_args3_rm.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_MIN, fp_args3_rm.size(), fp_args3_rm.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_IS_ZERO, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_MUL, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_REM, fp_args3_rm.size(), fp_args3_rm.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_RTI, fp_args3_rm.size(), fp_args3_rm.data()),
      error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SQRT,
                                fp_args3_rm.size(),
                                fp_args3_rm.data()),
               error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FP_SUB, fp_args2.size(), fp_args2.data()),
      error_arg_cnt);

  // others
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_DISTINCT, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_EQUAL, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_EXISTS, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_FORALL, bv_args1.size(), bv_args1.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_ITE, ite_args2.size(), ite_args2.data()),
      error_arg_cnt);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_LAMBDA, fun_args1.size(), fun_args1.data()),
      error_arg_cnt);

  // indexed
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_EXTRACT,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        idxs2.size(),
                                        idxs2.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_REPEAT,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_ROLI,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_RORI,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_SIGN_EXTEND,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_ZERO_EXTEND,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_BV,
                                        bv_args2.size(),
                                        bv_args2.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_FP,
                                        fp_args3_rm.size(),
                                        fp_args3_rm.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_SBV,
                                        bv_args1_rm.size(),
                                        bv_args1_rm.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_UBV,
                                        bv_args1_rm.size(),
                                        bv_args1_rm.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_SBV,
                                        fp_args1.size(),
                                        fp_args1.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_UBV,
                                        fp_args1.size(),
                                        fp_args1.data(),
                                        idxs1.size(),
                                        idxs1.data()),
               error_arg_cnt);
}

TEST_F(TestApi, mk_term_check_args)
{
  const char *error_inv_sort  = "unexpected sort";
  const char *error_mis_sort  = "mismatching sort";
  const char *error_bvar_term = "expected unbound variable term";
  const char *error_dvar_term = "given variables are not distinct";

  const char *error_arr_index_sort =
      "sort of index term does not match index sort of array";
  const char *error_arr_element_sort =
      "sort of element term does not match element sort of array";

  std::vector<BitwuzlaTerm *> array_select_args2_inv_1 = {d_fp_const16,
                                                          d_array_fpbv};
  std::vector<BitwuzlaTerm *> array_select_args2_inv_2 = {d_array_fpbv,
                                                          d_bv_const8};

  std::vector<BitwuzlaTerm *> array_store_args3_inv_1 = {
      d_fp_const16, d_array_fpbv, d_bv_const8};
  std::vector<BitwuzlaTerm *> array_store_args3_inv_2 = {
      d_array_fpbv, d_bv_const8, d_bv_const8};
  std::vector<BitwuzlaTerm *> array_store_args3_inv_3 = {
      d_array_fpbv, d_fp_const16, d_fp_const16};

  std::vector<BitwuzlaTerm *> apply_args3_inv_1 = {d_fun, d_bv_const8, d_fun};
  std::vector<BitwuzlaTerm *> apply_args3_inv_2 = {
      d_fun, d_bv_const8, d_bv_const8, d_fp_pzero32};

  std::vector<BitwuzlaTerm *> bool_args1_inv = {d_bv_const8};
  std::vector<BitwuzlaTerm *> bool_args2_inv = {d_fp_pzero32, d_fp_pzero32};
  std::vector<BitwuzlaTerm *> bool_args2_mis = {d_true, d_bv_const8};

  std::vector<BitwuzlaTerm *> bv_args1          = {d_bv_const8};
  std::vector<BitwuzlaTerm *> bv_args1_inv      = {d_fp_const16};
  std::vector<BitwuzlaTerm *> bv_args2_inv      = {d_fp_const16, d_fp_const16};
  std::vector<BitwuzlaTerm *> bv_args2_mis      = {d_bv_one1, d_bv_const8};
  std::vector<BitwuzlaTerm *> bv_args2_rm_inv_1 = {d_bv_const8, d_bv_const8};
  std::vector<BitwuzlaTerm *> bv_args2_rm_inv_2 = {d_rm_const, d_fp_const16};

  std::vector<BitwuzlaTerm *> ite_death_args3_1 = {
      d_true, d_bv_const8, d_bv_one1};
  std::vector<BitwuzlaTerm *> ite_args3_inv_2 = {
      d_bv_const8, d_bv_const8, d_bv_const8};

  std::vector<BitwuzlaTerm *> lambda_args2_inv_1 = {d_bv_const8, d_bv_const8};
  std::vector<BitwuzlaTerm *> lambda_args2_inv_2 = {d_bound_var, d_bv_const8};
  std::vector<BitwuzlaTerm *> lambda_args2_inv_3 = {d_var1, d_fun};
  std::vector<BitwuzlaTerm *> lambda_args3_inv_1 = {
      d_var1, d_var1, d_bv_const8};

  BitwuzlaTerm *lambda_body =
      bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_BV_ADD, d_var2, d_bv_const8);
  std::vector<BitwuzlaTerm *> lambda_args3_inv_2 = {
      d_var1,
      d_var2,
      bitwuzla_mk_term2_indexed2(d_bzla,
                                 BITWUZLA_KIND_FP_TO_FP_FROM_UBV,
                                 d_rm_const,
                                 lambda_body,
                                 5,
                                 8)};

  std::vector<BitwuzlaTerm *> fp_args1_inv      = {d_bv_one1};
  std::vector<BitwuzlaTerm *> fp_args2_inv      = {d_bv_zero8, d_bv_const8};
  std::vector<BitwuzlaTerm *> fp_args2_mis      = {d_fp_pzero32, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args2_rm_inv_1 = {d_bv_const8, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args2_rm_inv_2 = {d_rm_const, d_bv_const8};
  std::vector<BitwuzlaTerm *> fp_args3_rm_mis   = {
      d_rm_const, d_fp_pzero32, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args3_rm_inv_1 = {
      d_fp_const16, d_fp_const16, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args3_rm_inv_2 = {
      d_rm_const, d_bv_zero8, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args4_mis = {
      d_rm_const, d_fp_pzero32, d_fp_const16, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args4_rm_inv_1 = {
      d_rm_const, d_bv_zero8, d_fp_const16, d_fp_const16};
  std::vector<BitwuzlaTerm *> fp_args4_rm_inv_2 = {
      d_fp_const16, d_fp_const16, d_fp_const16, d_fp_const16};

  std::vector<BitwuzlaTerm *> fp_fp_args3_inv_1 = {
      d_bv_const8, d_bv_zero8, d_bv_ones23};
  std::vector<BitwuzlaTerm *> fp_fp_args3_inv_2 = {
      d_bv_one1, d_fp_pzero32, d_bv_ones23};
  std::vector<BitwuzlaTerm *> fp_fp_args3_inv_3 = {
      d_bv_one1, d_bv_zero8, d_fp_pzero32};
  std::vector<BitwuzlaTerm *> fp_fp_args3_inv_4 = {
      d_fp_pzero32, d_bv_zero8, d_bv_ones23};

  std::vector<BitwuzlaTerm *> quant_args2_inv_1 = {d_true, d_true};
  std::vector<BitwuzlaTerm *> quant_args2_inv_2 = {d_var1, d_bv_const8};
  std::vector<BitwuzlaTerm *> quant_args2_inv_3 = {d_bound_var, d_bv_const8};
  std::vector<BitwuzlaTerm *> quant_args3_inv   = {d_var1, d_var1, d_bv_const8};

  std::vector<uint32_t> bv_idxs1                 = {3};
  std::vector<uint32_t> bv_idxs2                 = {2, 0};
  std::vector<uint32_t> bv_extract_death_idxs2_1 = {0, 2};
  std::vector<uint32_t> bv_extract_death_idxs2_2 = {9, 0};
  std::vector<uint32_t> bv_repeat_death_idxs1    = {536870913};
  std::vector<uint32_t> bv_extend_death_idxs1    = {UINT32_MAX};
  std::vector<uint32_t> fp_idxs2                 = {5, 8};

  // bool
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_AND,
                                bool_args2_inv.size(),
                                bool_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_AND,
                                bool_args2_mis.size(),
                                bool_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(
      bitwuzla_mk_term(
          d_bzla, BITWUZLA_KIND_IFF, fp_args2_inv.size(), fp_args2_inv.data()),
      error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_IFF,
                                bool_args2_mis.size(),
                                bool_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_IMPLIES,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_IMPLIES,
                                bool_args2_mis.size(),
                                bool_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_NOT,
                                bool_args1_inv.size(),
                                bool_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_OR,
                                bool_args2_inv.size(),
                                bool_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_XOR,
                                bool_args2_inv.size(),
                                bool_args2_inv.data()),
               error_inv_sort);
  // bit-vectors
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ADD,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ADD,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_AND,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_AND,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ASHR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ASHR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_DEC,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_INC,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_MUL,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_MUL,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NAND,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NAND,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NEG,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NOR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NOR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_NOT,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_OR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_OR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_REDAND,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_REDOR,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_REDXOR,
                                bv_args1_inv.size(),
                                bv_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_OR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_OR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ROL,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ROL,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ROR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ROR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SADD_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SADD_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SDIV_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SDIV_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SDIV,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SDIV,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SGE,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SGE,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SGT,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SGT,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SHL,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SHL,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SHR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SHR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SLE,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SLE,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SLT,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SLT,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SMOD,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SMOD,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SMUL_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SMUL_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SREM,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SREM,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SSUB_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SSUB_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SUB,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_SUB,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UADD_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UADD_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UDIV,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UDIV,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UGE,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UGE,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UGT,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UGT,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ULE,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ULE,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ULT,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_ULT,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UMUL_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UMUL_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UREM,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_UREM,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_USUB_OVERFLOW,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_USUB_OVERFLOW,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_XNOR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_XNOR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_XOR,
                                bv_args2_inv.size(),
                                bv_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_BV_XOR,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  // floating-point
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_ABS,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_ADD,
                                fp_args3_rm_inv_2.size(),
                                fp_args3_rm_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_ADD,
                                fp_args3_rm_inv_1.size(),
                                fp_args3_rm_inv_1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_ADD,
                                fp_args3_rm_mis.size(),
                                fp_args3_rm_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_DIV,
                                fp_args3_rm_inv_2.size(),
                                fp_args3_rm_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_DIV,
                                fp_args3_rm_inv_1.size(),
                                fp_args3_rm_inv_1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_DIV,
                                fp_args3_rm_mis.size(),
                                fp_args3_rm_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_EQ,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_EQ,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FMA,
                                fp_args4_rm_inv_1.size(),
                                fp_args4_rm_inv_1.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FMA,
                                fp_args4_rm_inv_2.size(),
                                fp_args4_rm_inv_2.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FMA,
                                fp_args4_mis.size(),
                                fp_args4_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FP,
                                fp_fp_args3_inv_1.size(),
                                fp_fp_args3_inv_1.data()),
               "invalid bit-vector size");
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FP,
                                fp_fp_args3_inv_2.size(),
                                fp_fp_args3_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FP,
                                fp_fp_args3_inv_3.size(),
                                fp_fp_args3_inv_3.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_FP,
                                fp_fp_args3_inv_4.size(),
                                fp_fp_args3_inv_4.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_GEQ,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_GEQ,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_GT,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_GT,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_INF,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_NAN,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_NEG,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_NORMAL,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_POS,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_SUBNORMAL,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_ZERO,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_LEQ,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_LEQ,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_LT,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_LT,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MAX,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MAX,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MIN,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MIN,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_IS_ZERO,
                                fp_args1_inv.size(),
                                fp_args1_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MUL,
                                fp_args3_rm_inv_2.size(),
                                fp_args3_rm_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MUL,
                                fp_args3_rm_inv_1.size(),
                                fp_args3_rm_inv_1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_MUL,
                                fp_args3_rm_mis.size(),
                                fp_args3_rm_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_REM,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_REM,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_RTI,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_RTI,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_RTI,
                                fp_args2_rm_inv_1.size(),
                                fp_args2_rm_inv_1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_RTI,
                                fp_args2_rm_inv_2.size(),
                                fp_args2_rm_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SQRT,
                                fp_args2_inv.size(),
                                fp_args2_inv.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SQRT,
                                fp_args2_mis.size(),
                                fp_args2_mis.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SQRT,
                                fp_args2_rm_inv_1.size(),
                                fp_args2_rm_inv_1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SQRT,
                                fp_args2_rm_inv_2.size(),
                                fp_args2_rm_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SUB,
                                fp_args3_rm_inv_2.size(),
                                fp_args3_rm_inv_2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SUB,
                                fp_args3_rm_inv_1.size(),
                                fp_args3_rm_inv_1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FP_SUB,
                                fp_args3_rm_mis.size(),
                                fp_args3_rm_mis.data()),
               error_mis_sort);
  // others
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_APPLY,
                                apply_args3_inv_1.size(),
                                apply_args3_inv_1.data()),
               d_error_unexp_fun_term);
  ASSERT_DEATH(
      bitwuzla_mk_term(d_bzla,
                       BITWUZLA_KIND_APPLY,
                       apply_args3_inv_2.size(),
                       apply_args3_inv_2.data()),
      "sorts of arguments to apply don't match domain sorts of given function");
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_SELECT,
                                array_select_args2_inv_1.size(),
                                array_select_args2_inv_1.data()),
               d_error_exp_arr_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_SELECT,
                                array_select_args2_inv_2.size(),
                                array_select_args2_inv_2.data()),
               error_arr_index_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_STORE,
                                array_store_args3_inv_1.size(),
                                array_store_args3_inv_1.data()),
               d_error_exp_arr_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_STORE,
                                array_store_args3_inv_2.size(),
                                array_store_args3_inv_2.data()),
               error_arr_index_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ARRAY_STORE,
                                array_store_args3_inv_3.size(),
                                array_store_args3_inv_3.data()),
               error_arr_element_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_DISTINCT,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_EQUAL,
                                bv_args2_mis.size(),
                                bv_args2_mis.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_EXISTS,
                                quant_args2_inv_1.size(),
                                quant_args2_inv_1.data()),
               d_error_exp_var_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_EXISTS,
                                quant_args2_inv_2.size(),
                                quant_args2_inv_2.data()),
               d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_EXISTS,
                                quant_args2_inv_3.size(),
                                quant_args2_inv_3.data()),
               error_bvar_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_EXISTS,
                                quant_args3_inv.size(),
                                quant_args3_inv.data()),
               error_dvar_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FORALL,
                                quant_args2_inv_1.size(),
                                quant_args2_inv_1.data()),
               d_error_exp_var_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FORALL,
                                quant_args2_inv_2.size(),
                                quant_args2_inv_2.data()),
               d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FORALL,
                                quant_args2_inv_3.size(),
                                quant_args2_inv_3.data()),
               error_bvar_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_FORALL,
                                quant_args3_inv.size(),
                                quant_args3_inv.data()),
               error_dvar_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ITE,
                                ite_args3_inv_2.size(),
                                ite_args3_inv_2.data()),
               d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_ITE,
                                ite_death_args3_1.size(),
                                ite_death_args3_1.data()),
               error_mis_sort);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_LAMBDA,
                                lambda_args2_inv_1.size(),
                                lambda_args2_inv_1.data()),
               d_error_exp_var_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_LAMBDA,
                                lambda_args2_inv_2.size(),
                                lambda_args2_inv_2.data()),
               error_bvar_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_LAMBDA,
                                lambda_args2_inv_3.size(),
                                lambda_args2_inv_3.data()),
               d_error_unexp_fun_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_LAMBDA,
                                lambda_args3_inv_1.size(),
                                lambda_args3_inv_1.data()),
               error_dvar_term);
  ASSERT_DEATH(bitwuzla_mk_term(d_bzla,
                                BITWUZLA_KIND_LAMBDA,
                                lambda_args3_inv_2.size(),
                                lambda_args3_inv_2.data()),
               "expected bit-vector term or bit-vector function term");
  // indexed
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_EXTRACT,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        bv_idxs2.size(),
                                        bv_idxs2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_EXTRACT,
                                        bv_args1.size(),
                                        bv_args1.data(),
                                        bv_extract_death_idxs2_1.size(),
                                        bv_extract_death_idxs2_1.data()),
               "upper index must be >= lower index");
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_EXTRACT,
                                        bv_args1.size(),
                                        bv_args1.data(),
                                        bv_extract_death_idxs2_2.size(),
                                        bv_extract_death_idxs2_2.data()),
               "upper index must be < bit-vector size of given term");
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_REPEAT,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
  ASSERT_DEATH(
      bitwuzla_mk_term_indexed(d_bzla,
                               BITWUZLA_KIND_BV_REPEAT,
                               bv_args1.size(),
                               bv_args1.data(),
                               bv_repeat_death_idxs1.size(),
                               bv_repeat_death_idxs1.data()),
      "resulting bit-vector size of 'repeat' exceeds maximum bit-vector size");
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_ROLI,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_RORI,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_SIGN_EXTEND,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_SIGN_EXTEND,
                                        bv_args1.size(),
                                        bv_args1.data(),
                                        bv_extend_death_idxs1.size(),
                                        bv_extend_death_idxs1.data()),
               "exceeds maximum bit-vector size");
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_ZERO_EXTEND,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_BV_ZERO_EXTEND,
                                        bv_args1.size(),
                                        bv_args1.data(),
                                        bv_extend_death_idxs1.size(),
                                        bv_extend_death_idxs1.data()),
               "exceeds maximum bit-vector size");
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_BV,
                                        bv_args1_inv.size(),
                                        bv_args1_inv.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_FP,
                                        fp_args2_rm_inv_1.size(),
                                        fp_args2_rm_inv_1.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_FP,
                                        fp_args2_rm_inv_2.size(),
                                        fp_args2_rm_inv_2.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_SBV,
                                        bv_args2_rm_inv_1.size(),
                                        bv_args2_rm_inv_1.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_SBV,
                                        bv_args2_rm_inv_2.size(),
                                        bv_args2_rm_inv_2.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_UBV,
                                        bv_args2_rm_inv_1.size(),
                                        bv_args2_rm_inv_1.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_FP_FROM_UBV,
                                        bv_args2_rm_inv_2.size(),
                                        bv_args2_rm_inv_2.data(),
                                        fp_idxs2.size(),
                                        fp_idxs2.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_SBV,
                                        fp_args2_rm_inv_1.size(),
                                        fp_args2_rm_inv_1.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_SBV,
                                        fp_args2_rm_inv_2.size(),
                                        fp_args2_rm_inv_2.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_UBV,
                                        fp_args2_rm_inv_1.size(),
                                        fp_args2_rm_inv_1.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               d_error_exp_rm_term);
  ASSERT_DEATH(bitwuzla_mk_term_indexed(d_bzla,
                                        BITWUZLA_KIND_FP_TO_UBV,
                                        fp_args2_rm_inv_2.size(),
                                        fp_args2_rm_inv_2.data(),
                                        bv_idxs1.size(),
                                        bv_idxs1.data()),
               error_inv_sort);
}

TEST_F(TestApi, mk_const)
{
  ASSERT_DEATH(bitwuzla_mk_const(nullptr, d_bv_sort8, "asdf"),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_const(d_bzla, nullptr, "asdf"), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_const(d_bzla, d_other_bv_sort8, "asdf"),
               d_error_solver);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_mk_const(d_bzla, d_bv_sort8, nullptr));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_mk_const(d_bzla, d_bv_sort8, ""));
}

TEST_F(TestApi, mk_const_array)
{
  ASSERT_DEATH(bitwuzla_mk_const_array(nullptr, d_arr_sort_bv, d_bv_one1),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, nullptr, d_bv_one1),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_arr_sort_bv, nullptr),
               d_error_not_null);

  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_arr_sort_bv, d_other_bv_one1),
               d_error_solver);
  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_other_arr_sort_bv, d_bv_one1),
               d_error_solver);

  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_bv_sort8, d_bv_one1),
               d_error_exp_arr_sort);
  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_other_arr_sort_bv, d_bv_one1),
               d_error_solver);
  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_arr_sort_bv, d_array),
               d_error_unexp_arr_term);
  ASSERT_DEATH(bitwuzla_mk_const_array(d_bzla, d_arr_sort_bvfp, d_fp_pzero32),
               "sort of 'value' does not match array element sort");

  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_mk_const_array(d_bzla, d_arr_sort_bvfp, d_fp_const16));
}

TEST_F(TestApi, mk_var)
{
  ASSERT_DEATH(bitwuzla_mk_var(nullptr, d_bv_sort8, "asdf"), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_var(d_bzla, nullptr, "asdf"), d_error_not_null);
  ASSERT_DEATH(bitwuzla_mk_var(d_bzla, d_other_bv_sort8, "asdf"),
               d_error_solver);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_mk_var(d_bzla, d_bv_sort8, nullptr));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_mk_var(d_bzla, d_bv_sort8, ""));
}

TEST_F(TestApi, push)
{
  ASSERT_DEATH(bitwuzla_push(d_bzla, 2), d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_DEATH(bitwuzla_push(nullptr, 2), d_error_not_null);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_push(d_bzla, 0));
}

TEST_F(TestApi, pop)
{
  ASSERT_DEATH(bitwuzla_pop(d_bzla, 2), d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_DEATH(bitwuzla_pop(nullptr, 2), d_error_not_null);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_pop(d_bzla, 0));
}

TEST_F(TestApi, assert)
{
  ASSERT_DEATH(bitwuzla_assert(nullptr, d_true), d_error_not_null);
  ASSERT_DEATH(bitwuzla_assert(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_assert(d_bzla, d_other_true), d_error_solver);
  ASSERT_DEATH(bitwuzla_assert(d_bzla, d_bv_const8), d_error_exp_bool_term);

  ASSERT_DEATH(bitwuzla_assert(d_bzla, d_bool_var), d_error_unexp_param_term);
  ASSERT_DEATH(bitwuzla_assert(d_bzla, d_bool_lambda), d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_assert(d_bzla, d_bool_lambda_body),
               d_error_unexp_param_term);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_assert(d_bzla, d_bool_apply));

  ASSERT_NO_FATAL_FAILURE(bitwuzla_assert(d_bzla, d_bv_one1));
}

TEST_F(TestApi, assume)
{
  ASSERT_DEATH(bitwuzla_assume(d_bzla, d_bv_const1), d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);

  ASSERT_DEATH(bitwuzla_assume(nullptr, d_true), d_error_not_null);
  ASSERT_DEATH(bitwuzla_assume(d_bzla, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_assume(d_bzla, d_other_true), d_error_solver);
  ASSERT_DEATH(bitwuzla_assume(d_bzla, d_bv_const8), d_error_exp_bool_term);

  ASSERT_DEATH(bitwuzla_assume(d_bzla, d_bool_var), d_error_unexp_param_term);
  ASSERT_DEATH(bitwuzla_assume(d_bzla, d_bool_lambda), d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_assume(d_bzla, d_bool_lambda_body),
               d_error_unexp_param_term);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_assume(d_bzla, d_bool_apply));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_assume(d_bzla, d_bv_one1));
}

TEST_F(TestApi, is_unsat_assumption)
{
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1),
               d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);

  ASSERT_DEATH(bitwuzla_is_unsat_assumption(nullptr, d_true), d_error_not_null);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, nullptr), d_error_not_null);

  bitwuzla_assert(d_bzla, d_true);
  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_check_sat(d_bzla);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1),
               d_error_unsat);

  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assume(d_bzla,
                  bitwuzla_mk_term1(d_bzla, BITWUZLA_KIND_NOT, d_bv_const1));
  bitwuzla_check_sat(d_bzla);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_other_true),
               d_error_solver);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const8),
               d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_true),
               d_error_exp_assumption);

  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_bool_var),
               d_error_exp_assumption);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_bool_lambda),
               d_error_exp_bool_term);
  ASSERT_DEATH(bitwuzla_is_unsat_assumption(d_bzla, d_bool_lambda_body),
               d_error_exp_assumption);

  ASSERT_NO_FATAL_FAILURE(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1));
}

TEST_F(TestApi, get_unsat_assumptions)
{
  size_t size;
  ASSERT_DEATH(bitwuzla_get_unsat_assumptions(d_bzla, &size),
               d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);

  ASSERT_DEATH(bitwuzla_get_unsat_assumptions(nullptr, &size),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_get_unsat_assumptions(d_bzla, nullptr),
               d_error_not_null);

  bitwuzla_assert(d_bzla, d_true);
  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_check_sat(d_bzla);
  ASSERT_DEATH(bitwuzla_get_unsat_assumptions(d_bzla, &size), d_error_unsat);

  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assume(d_bzla, d_not_bv_const1);
  bitwuzla_assume(d_bzla, d_and_bv_const1);
  bitwuzla_assume(d_bzla, d_eq_bv_const8);
  bitwuzla_check_sat(d_bzla);
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1));
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_not_bv_const1));
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_and_bv_const1));
  ASSERT_FALSE(bitwuzla_is_unsat_assumption(d_bzla, d_eq_bv_const8));
  BitwuzlaTerm **unsat_ass = bitwuzla_get_unsat_assumptions(d_bzla, &size);
  size_t i = 0;
  for (; i < size; ++i)
  {
    ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, unsat_ass[i]));
  }
  ASSERT_EQ(i, 3);
  for (i = 0; i < size; ++i)
  {
    bitwuzla_assert(d_bzla, unsat_ass[i]);
  }
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
}

TEST_F(TestApi, get_unsat_core)
{
  size_t size;
  ASSERT_DEATH(bitwuzla_get_unsat_core(d_bzla, &size), d_error_unsat_cores);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_DEATH(bitwuzla_get_unsat_core(d_bzla, &size), d_error_unsat_cores);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_UNSAT_CORES, 1);

  ASSERT_DEATH(bitwuzla_get_unsat_core(nullptr, &size), d_error_not_null);
  ASSERT_DEATH(bitwuzla_get_unsat_core(d_bzla, nullptr), d_error_not_null);

  bitwuzla_assert(d_bzla, d_true);
  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_check_sat(d_bzla);
  ASSERT_DEATH(bitwuzla_get_unsat_core(d_bzla, &size), d_error_unsat);

  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assert(d_bzla, d_not_bv_const1);
  bitwuzla_assume(d_bzla, d_and_bv_const1);
  bitwuzla_assert(d_bzla, d_eq_bv_const8);
  bitwuzla_check_sat(d_bzla);
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1));
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_and_bv_const1));
  BitwuzlaTerm **unsat_core = bitwuzla_get_unsat_core(d_bzla, &size);
  ASSERT_TRUE(unsat_core[0] == d_not_bv_const1);
  ASSERT_TRUE(size == 1);

  BitwuzlaTerm **unsat_ass = bitwuzla_get_unsat_assumptions(d_bzla, &size);
  ASSERT_TRUE(unsat_ass[0] == d_bv_const1);
  ASSERT_TRUE(unsat_ass[1] == d_and_bv_const1);
  ASSERT_TRUE(size == 2);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_SAT);
  bitwuzla_assert(d_bzla, unsat_ass[0]);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
}

TEST_F(TestApi, fixate_assumptions)
{
  ASSERT_DEATH(bitwuzla_fixate_assumptions(d_bzla), d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);

  ASSERT_DEATH(bitwuzla_fixate_assumptions(nullptr), d_error_not_null);

  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assert(d_bzla, d_not_bv_const1);
  bitwuzla_assume(d_bzla, d_and_bv_const1);
  bitwuzla_assert(d_bzla, d_eq_bv_const8);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1));
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_and_bv_const1));
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_SAT);
  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assume(d_bzla, d_and_bv_const1);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
  bitwuzla_fixate_assumptions(d_bzla);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
}

TEST_F(TestApi, reset_assumptions)
{
  ASSERT_DEATH(bitwuzla_reset_assumptions(d_bzla), d_error_incremental);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);

  ASSERT_DEATH(bitwuzla_reset_assumptions(nullptr), d_error_not_null);

  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assert(d_bzla, d_not_bv_const1);
  bitwuzla_assume(d_bzla, d_and_bv_const1);
  bitwuzla_assert(d_bzla, d_eq_bv_const8);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_bv_const1));
  ASSERT_TRUE(bitwuzla_is_unsat_assumption(d_bzla, d_and_bv_const1));
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_SAT);
  bitwuzla_assume(d_bzla, d_bv_const1);
  bitwuzla_assume(d_bzla, d_and_bv_const1);
  bitwuzla_reset_assumptions(d_bzla);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_SAT);
}

TEST_F(TestApi, simplify)
{
  ASSERT_DEATH(bitwuzla_simplify(nullptr), d_error_not_null);
  bitwuzla_assert(d_bzla, d_bv_const1);
  bitwuzla_assert(d_bzla, d_and_bv_const1);
  ASSERT_TRUE(bitwuzla_simplify(d_bzla) == BITWUZLA_SAT);
}

TEST_F(TestApi, check_sat)
{
  ASSERT_DEATH(bitwuzla_check_sat(nullptr), d_error_not_null);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_check_sat(d_bzla));
  ASSERT_DEATH(bitwuzla_check_sat(d_bzla), d_error_incremental);

  bitwuzla_set_option(d_other_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  bitwuzla_assert(d_other_bzla, d_other_exists);
  ASSERT_DEATH(bitwuzla_check_sat(d_other_bzla), d_error_inc_quant);

  Bitwuzla *bzla = bitwuzla_new();
  bitwuzla_set_option(bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_check_sat(bzla));
  bitwuzla_delete(bzla);
}

TEST_F(TestApi, get_value)
{
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_DEATH(bitwuzla_get_value(d_bzla, d_bv_const8), d_error_produce_models);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  ASSERT_DEATH(bitwuzla_get_value(nullptr, d_bv_const8), d_error_not_null);
  ASSERT_DEATH(bitwuzla_get_value(d_bzla, nullptr), d_error_not_null);
  bitwuzla_assert(d_bzla, d_bv_const1);
  bitwuzla_assume(d_bzla, d_not_bv_const1);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
  ASSERT_DEATH(bitwuzla_get_value(d_bzla, d_bv_const1), d_error_sat);
  bitwuzla_check_sat(d_bzla);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_get_value(d_bzla, d_bv_const1));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_get_value(d_bzla, d_not_bv_const1));

  bitwuzla_set_option(d_other_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  bitwuzla_assert(d_other_bzla, d_other_exists);
  ASSERT_DEATH(bitwuzla_get_value(d_other_bzla, d_other_bv_const8),
               d_error_sat);
  ASSERT_DEATH(bitwuzla_check_sat(d_other_bzla),
               "Quantifiers support is disabled.");
// Disabled since quantifiers support was disabled.
//  ASSERT_EQ(bitwuzla_check_sat(d_other_bzla), BITWUZLA_SAT);
//  ASSERT_DEATH(bitwuzla_get_value(d_other_bzla, d_other_bv_const8),
//               "'get-value' is currently not supported with quantifiers");
}

TEST_F(TestApi, get_bv_value)
{
  ASSERT_DEATH(bitwuzla_get_bv_value(d_bzla, d_bv_one1),
               d_error_produce_models);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  ASSERT_DEATH(bitwuzla_get_bv_value(nullptr, d_bv_one1), d_error_not_null);
  ASSERT_DEATH(bitwuzla_get_bv_value(d_bzla, nullptr), d_error_not_null);
  bitwuzla_check_sat(d_bzla);
  ASSERT_DEATH(bitwuzla_get_bv_value(d_bzla, d_fp_nan32), "not a bit-vector");
  ASSERT_TRUE(!strcmp("1", bitwuzla_get_bv_value(d_bzla, d_bv_one1)));
}

TEST_F(TestApi, get_rm_value)
{
  ASSERT_DEATH(bitwuzla_get_rm_value(d_bzla, d_bv_one1),
               d_error_produce_models);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  ASSERT_DEATH(bitwuzla_get_rm_value(nullptr, d_bv_one1), d_error_not_null);
  ASSERT_DEATH(bitwuzla_get_rm_value(d_bzla, nullptr), d_error_not_null);

  BitwuzlaTerm *rna = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNA);
  BitwuzlaTerm *rne = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNE);
  BitwuzlaTerm *rtn = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTN);
  BitwuzlaTerm *rtp = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTP);
  BitwuzlaTerm *rtz = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTZ);
  bitwuzla_check_sat(d_bzla);
  ASSERT_DEATH(bitwuzla_get_rm_value(d_bzla, d_fp_nan32),
               "not a rounding mode");
  ASSERT_TRUE(!strcmp("RNA", bitwuzla_get_rm_value(d_bzla, rna)));
  ASSERT_TRUE(!strcmp("RNE", bitwuzla_get_rm_value(d_bzla, rne)));
  ASSERT_TRUE(!strcmp("RTN", bitwuzla_get_rm_value(d_bzla, rtn)));
  ASSERT_TRUE(!strcmp("RTP", bitwuzla_get_rm_value(d_bzla, rtp)));
  ASSERT_TRUE(!strcmp("RTZ", bitwuzla_get_rm_value(d_bzla, rtz)));
}

TEST_F(TestApi, get_array_value)
{
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  BitwuzlaTerm *a = bitwuzla_mk_const(d_bzla, d_arr_sort_bvfp, nullptr);

  BitwuzlaTerm *i =
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort8, "1", BITWUZLA_BV_BASE_DEC);
  BitwuzlaTerm *j =
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort8, "10", BITWUZLA_BV_BASE_DEC);
  BitwuzlaTerm *k =
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort8, "100", BITWUZLA_BV_BASE_DEC);

  BitwuzlaTerm *rm = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNE);
  BitwuzlaTerm *u =
      bitwuzla_mk_fp_value_from_real(d_bzla, d_fp_sort16, rm, "1.3");
  BitwuzlaTerm *v =
      bitwuzla_mk_fp_value_from_real(d_bzla, d_fp_sort16, rm, "15.123");
  BitwuzlaTerm *w =
      bitwuzla_mk_fp_value_from_real(d_bzla, d_fp_sort16, rm, "1333.18");

  BitwuzlaTerm *stores = bitwuzla_mk_term3(
      d_bzla,
      BITWUZLA_KIND_ARRAY_STORE,
      bitwuzla_mk_term3(
          d_bzla,
          BITWUZLA_KIND_ARRAY_STORE,
          bitwuzla_mk_term3(d_bzla, BITWUZLA_KIND_ARRAY_STORE, a, i, u),
          j,
          v),
      k,
      w);
  bitwuzla_check_sat(d_bzla);

  size_t size;
  BitwuzlaTerm **indices, **values, *default_value;
  bitwuzla_get_array_value(
      d_bzla, stores, &indices, &values, &size, &default_value);

  ASSERT_EQ(size, 3);
  for (size_t ii = 0; ii < size; ++ii)
  {
    ASSERT_TRUE(indices[ii] == i || indices[ii] == j || indices[ii] == k);
    ASSERT_TRUE(values[ii] == u || values[ii] == v || values[ii] == w);
    bitwuzla_term_dump(indices[ii], "smt2", stdout);
    std::cout << " -> ";
    bitwuzla_term_dump(values[ii], "smt2", stdout);
    std::cout << std::endl;
  }

  BitwuzlaTerm *b = bitwuzla_mk_const_array(d_bzla, d_arr_sort_bvfp, w);
  bitwuzla_get_array_value(d_bzla, b, &indices, &values, &size, &default_value);
  ASSERT_EQ(size, 0);
  ASSERT_EQ(indices, nullptr);
  ASSERT_EQ(values, nullptr);
  ASSERT_EQ(default_value, w);
}

TEST_F(TestApi, get_fun_value)
{
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  BitwuzlaTerm *f = bitwuzla_mk_const(d_bzla, d_fun_sort, nullptr);

  BitwuzlaTerm *arg0 =
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort8, "42", BITWUZLA_BV_BASE_DEC);
  BitwuzlaTerm *arg1 = bitwuzla_mk_fp_value_from_real(
      d_bzla,
      d_fp_sort16,
      bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTP),
      "0.4324");
  BitwuzlaTerm *arg2 =
      bitwuzla_mk_bv_value(d_bzla, d_bv_sort32, "381012", BITWUZLA_BV_BASE_DEC);

  std::vector<BitwuzlaTerm *> _args = {f, arg0, arg1, arg2};
  BitwuzlaTerm *app0 =
      bitwuzla_mk_term(d_bzla, BITWUZLA_KIND_APPLY, _args.size(), _args.data());

  bitwuzla_assert(d_bzla,
                  bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_EQUAL, app0, arg0));
  bitwuzla_check_sat(d_bzla);

  size_t size, arity;
  BitwuzlaTerm ***args, **values;
  bitwuzla_get_fun_value(d_bzla, f, &args, &arity, &values, &size);

  ASSERT_EQ(size, 1);
  ASSERT_EQ(arity, 3);

  for (size_t i = 0; i < size; ++i)
  {
    for (size_t j = 0; j < arity; ++j)
    {
      bitwuzla_term_dump(args[i][j], "smt2", stdout);
      std::cout << " ";
    }
    std::cout << "-> ";
    bitwuzla_term_dump(values[i], "smt2", stdout);
    std::cout << std::endl;
  }
}

TEST_F(TestApi, get_fun_value2)
{
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  BitwuzlaSort *bv1       = bitwuzla_mk_bv_sort(d_bzla, 1);
  BitwuzlaSort *args1_1[] = {bv1, bv1};
  BitwuzlaSort *fn1_1_1   = bitwuzla_mk_fun_sort(d_bzla, 2, args1_1, bv1);
  BitwuzlaTerm *a         = bitwuzla_mk_const(d_bzla, fn1_1_1, "a");
  BitwuzlaTerm *t         = bitwuzla_mk_true(d_bzla);
  BitwuzlaTerm *f         = bitwuzla_mk_false(d_bzla);
  BitwuzlaTerm *a0_0 = bitwuzla_mk_term3(d_bzla, BITWUZLA_KIND_APPLY, a, f, f);
  BitwuzlaTerm *a0_1 = bitwuzla_mk_term3(d_bzla, BITWUZLA_KIND_APPLY, a, f, t);
  BitwuzlaTerm *c0   = bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_EQUAL, a0_0, t);
  BitwuzlaTerm *c1   = bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_EQUAL, a0_1, f);
  bitwuzla_assert(d_bzla, c0);
  bitwuzla_assert(d_bzla, c1);
  bitwuzla_check_sat(d_bzla);

  BitwuzlaTerm ***args, **values;
  size_t arity, size;
  bitwuzla_get_fun_value(d_bzla, a, &args, &arity, &values, &size);
  for (size_t i = 0; i < size; i += 1)
  {
    std::cout << "(" << bitwuzla_get_bv_value(d_bzla, args[i][0]);
    for (size_t j = 1; j < arity; j += 1)
    {
      std::cout << ", " << bitwuzla_get_bv_value(d_bzla, args[i][j]);
    }
    std::cout << "): " << bitwuzla_get_bv_value(d_bzla, values[i]) << std::endl;
  }
}

TEST_F(TestApi, print_model)
{
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_DEATH(bitwuzla_print_model(d_bzla, "btor", stdout),
               d_error_produce_models);
  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  ASSERT_DEATH(bitwuzla_print_model(nullptr, "btor", stdout), d_error_not_null);
  ASSERT_DEATH(bitwuzla_print_model(d_bzla, nullptr, stdout), d_error_exp_str);
  ASSERT_DEATH(bitwuzla_print_model(d_bzla, "smt2", nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_print_model(d_bzla, "asdf", stdout),
               "invalid model output format");

  bitwuzla_assert(d_bzla, d_bv_const1);
  bitwuzla_assume(d_bzla, d_not_bv_const1);
  ASSERT_EQ(bitwuzla_check_sat(d_bzla), BITWUZLA_UNSAT);
  ASSERT_DEATH(bitwuzla_print_model(d_bzla, "btor", stdout), d_error_sat);
  bitwuzla_check_sat(d_bzla);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_print_model(d_bzla, "btor", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_print_model(d_bzla, "smt2", stdout));

  bitwuzla_set_option(d_other_bzla, BITWUZLA_OPT_PRODUCE_MODELS, 1);
  bitwuzla_assert(d_other_bzla, d_other_exists);
  ASSERT_DEATH(bitwuzla_check_sat(d_other_bzla),
               "Quantifiers support is disabled.");
// Disabled since quantifiers support was disabled.
//  ASSERT_EQ(bitwuzla_check_sat(d_other_bzla), BITWUZLA_SAT);
//  ASSERT_NO_FATAL_FAILURE(bitwuzla_print_model(d_other_bzla, "btor", stdout));
//  ASSERT_NO_FATAL_FAILURE(bitwuzla_print_model(d_other_bzla, "smt2", stdout));
}

TEST_F(TestApi, dump_formula1)
{
  ASSERT_DEATH(bitwuzla_dump_formula(nullptr, "btor", stdout),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_dump_formula(d_bzla, nullptr, stdout), d_error_exp_str);
  ASSERT_DEATH(bitwuzla_dump_formula(d_bzla, "smt2", nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_dump_formula(d_bzla, "asdf", stdout), d_error_format);

  ASSERT_DEATH(bitwuzla_set_option(d_bzla, BITWUZLA_OPT_RW_LEVEL, 0),
               "before creating expressions");

  bitwuzla_assert(d_bzla, d_bv_const1);
  bitwuzla_assert(
      d_bzla,
      bitwuzla_mk_term2(
          d_bzla,
          BITWUZLA_KIND_EQUAL,
          bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_APPLY, d_lambda, d_bv_const8),
          d_bv_zero8));

  ASSERT_NO_FATAL_FAILURE(bitwuzla_dump_formula(d_bzla, "btor", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_dump_formula(d_bzla, "smt2", stdout));

  bitwuzla_assert(d_other_bzla, d_other_exists);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_dump_formula(d_other_bzla, "btor", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_dump_formula(d_other_bzla, "smt2", stdout));
  bitwuzla_set_option(d_other_bzla, BITWUZLA_OPT_INCREMENTAL, 1);
  ASSERT_DEATH(bitwuzla_dump_formula(d_other_bzla, "btor", stdout),
               "dumping in incremental mode is currently not supported");
}

TEST_F(TestApi, parse)
{
  bool is_smt2;
  BitwuzlaResult status;
  char *error_msg;
  std::string infile_name = "fp_regr1.smt2";
  std::stringstream ss;
  ss << BZLA_OUT_DIR << infile_name;
  FILE *infile = fopen(ss.str().c_str(), "r");

  ASSERT_DEATH(bitwuzla_parse(nullptr,
                              infile,
                              infile_name.c_str(),
                              stdout,
                              &error_msg,
                              &status,
                              &is_smt2),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse(d_bzla,
                              nullptr,
                              infile_name.c_str(),
                              stdout,
                              &error_msg,
                              &status,
                              &is_smt2),
               d_error_not_null);
  ASSERT_DEATH(
      bitwuzla_parse(
          d_bzla, infile, nullptr, stdout, &error_msg, &status, &is_smt2),
      d_error_exp_str);
  ASSERT_DEATH(bitwuzla_parse(d_bzla,
                              infile,
                              infile_name.c_str(),
                              stdout,
                              nullptr,
                              &status,
                              &is_smt2),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse(d_bzla,
                              infile,
                              infile_name.c_str(),
                              stdout,
                              &error_msg,
                              nullptr,
                              &is_smt2),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse(d_bzla,
                              infile,
                              infile_name.c_str(),
                              stdout,
                              &error_msg,
                              &status,
                              nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse(d_bzla,
                              infile,
                              infile_name.c_str(),
                              stdout,
                              &error_msg,
                              &status,
                              &is_smt2),
               "file parsing after having created expressions is not allowed");

  Bitwuzla *bzla = bitwuzla_new();
  ASSERT_NO_FATAL_FAILURE(bitwuzla_parse(bzla,
                                         infile,
                                         infile_name.c_str(),
                                         stdout,
                                         &error_msg,
                                         &status,
                                         &is_smt2));
  ASSERT_TRUE(is_smt2);
  bitwuzla_delete(bzla);
}

TEST_F(TestApi, parse_format)
{
  BitwuzlaResult status;
  char *error_msg;
  std::string infile_name = "fp_regr1.smt2";
  std::stringstream ss;
  ss << BZLA_OUT_DIR << infile_name;
  FILE *infile = fopen(ss.str().c_str(), "r");

  ASSERT_DEATH(bitwuzla_parse_format(nullptr,
                                     "btor",
                                     infile,
                                     infile_name.c_str(),
                                     stdout,
                                     &error_msg,
                                     &status),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse_format(d_bzla,
                                     nullptr,
                                     infile,
                                     infile_name.c_str(),
                                     stdout,
                                     &error_msg,
                                     &status),
               d_error_exp_str);
  ASSERT_DEATH(bitwuzla_parse_format(d_bzla,
                                     "smt2",
                                     nullptr,
                                     infile_name.c_str(),
                                     stdout,
                                     &error_msg,
                                     &status),
               d_error_not_null);
  ASSERT_DEATH(
      bitwuzla_parse_format(
          d_bzla, "btor", infile, nullptr, stdout, &error_msg, &status),
      d_error_exp_str);
  ASSERT_DEATH(bitwuzla_parse_format(d_bzla,
                                     "smt2",
                                     infile,
                                     infile_name.c_str(),
                                     stdout,
                                     nullptr,
                                     &status),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse_format(d_bzla,
                                     "btor",
                                     infile,
                                     infile_name.c_str(),
                                     stdout,
                                     &error_msg,
                                     nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_parse_format(d_bzla,
                                     "smt2",
                                     infile,
                                     infile_name.c_str(),
                                     stdout,
                                     &error_msg,
                                     &status),
               "file parsing after having created expressions is not allowed");

  Bitwuzla *bzla = bitwuzla_new();
  ASSERT_DEATH(bitwuzla_parse_format(bzla,
                                     "asdf",
                                     infile,
                                     infile_name.c_str(),
                                     stdout,
                                     &error_msg,
                                     &status),
               d_error_format);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_parse_format(
      bzla, "smt2", infile, infile_name.c_str(), stdout, &error_msg, &status));
  bitwuzla_delete(bzla);
}

/* -------------------------------------------------------------------------- */
/* BitwuzlaSort                                                               */
/* -------------------------------------------------------------------------- */

TEST_F(TestApi, sort_hash)
{
  ASSERT_DEATH(bitwuzla_sort_hash(nullptr), d_error_not_null);
}

TEST_F(TestApi, sort_bv_get_size)
{
  ASSERT_DEATH(bitwuzla_sort_bv_get_size(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_bv_get_size(d_fp_sort16), d_error_exp_bv_sort);
  ASSERT_EQ(bitwuzla_sort_bv_get_size(d_bv_sort8), 8);
}

TEST_F(TestApi, sort_fp_get_exp_size)
{
  ASSERT_DEATH(bitwuzla_sort_fp_get_exp_size(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_fp_get_exp_size(d_bv_sort8), d_error_exp_fp_sort);
  ASSERT_EQ(bitwuzla_sort_fp_get_exp_size(d_fp_sort16), 5);
}

TEST_F(TestApi, sort_fp_get_sig_size)
{
  ASSERT_DEATH(bitwuzla_sort_fp_get_sig_size(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_fp_get_sig_size(d_bv_sort8), d_error_exp_fp_sort);
  ASSERT_EQ(bitwuzla_sort_fp_get_sig_size(d_fp_sort16), 11);
}

TEST_F(TestApi, sort_array_get_index)
{
  ASSERT_DEATH(bitwuzla_sort_array_get_index(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_array_get_index(d_bv_sort23),
               d_error_exp_arr_sort);
  ASSERT_TRUE(
      bitwuzla_sort_is_bv(bitwuzla_sort_array_get_index(d_arr_sort_bvfp)));
}

TEST_F(TestApi, sort_array_get_element)
{
  ASSERT_DEATH(bitwuzla_sort_array_get_element(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_array_get_element(d_bv_sort23),
               d_error_exp_arr_sort);
  ASSERT_TRUE(
      bitwuzla_sort_is_fp(bitwuzla_sort_array_get_element(d_arr_sort_bvfp)));
}

TEST_F(TestApi, sort_fun_get_domain_sorts)
{
  size_t size;
  ASSERT_DEATH(bitwuzla_sort_fun_get_domain_sorts(nullptr, nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_fun_get_domain_sorts(d_fun_sort, nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_fun_get_domain_sorts(d_bv_sort32, &size),
               d_error_exp_fun_sort);

  BitwuzlaSort **index_sorts =
      bitwuzla_sort_fun_get_domain_sorts(d_arr_sort_bv, &size);
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort32, index_sorts[0]));
  ASSERT_EQ(size, 1);

  BitwuzlaSort **domain_sorts =
      bitwuzla_sort_fun_get_domain_sorts(d_fun_sort, &size);
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort8, domain_sorts[0]));
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_fp_sort16, domain_sorts[1]));
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort32, domain_sorts[2]));
  ASSERT_EQ(size, 3);
}

TEST_F(TestApi, sort_fun_get_codomain)
{
  ASSERT_DEATH(bitwuzla_sort_fun_get_codomain(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_fun_get_codomain(d_bv_sort32),
               d_error_exp_fun_sort);
}

TEST_F(TestApi, sort_fun_get_arity)
{
  ASSERT_DEATH(bitwuzla_sort_fun_get_arity(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_fun_get_arity(d_bv_sort32), d_error_exp_fun_sort);
  ASSERT_EQ(bitwuzla_sort_fun_get_arity(d_fun_sort), 3);
}

TEST_F(TestApi, sort_is_equal)
{
  ASSERT_DEATH(bitwuzla_sort_is_equal(nullptr, d_bv_sort1), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_is_equal(d_bv_sort1, nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_is_equal(d_bv_sort1, d_other_bv_sort1),
               "given sorts are not associated with the same solver instance");
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort1, d_bv_sort1));
}

TEST_F(TestApi, sort_is_array)
{
  ASSERT_DEATH(bitwuzla_sort_is_array(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_sort_is_array(d_arr_sort_bv));
  ASSERT_TRUE(bitwuzla_sort_is_array(d_arr_sort_bvfp));
  ASSERT_TRUE(bitwuzla_sort_is_array(d_arr_sort_fpbv));
  ASSERT_FALSE(bitwuzla_sort_is_array(d_fun_sort));
  ASSERT_FALSE(bitwuzla_sort_is_array(d_fun_sort_fp));
  ASSERT_FALSE(bitwuzla_sort_is_array(d_bv_sort8));
  ASSERT_FALSE(bitwuzla_sort_is_array(d_fp_sort16));
}

TEST_F(TestApi, sort_is_bv)
{
  ASSERT_DEATH(bitwuzla_sort_is_bv(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_sort_is_bv(d_bv_sort1));
  ASSERT_TRUE(bitwuzla_sort_is_bv(d_bv_sort8));
  ASSERT_TRUE(bitwuzla_sort_is_bv(d_bv_sort23));
  ASSERT_TRUE(bitwuzla_sort_is_bv(d_bv_sort32));
  ASSERT_FALSE(bitwuzla_sort_is_bv(d_fp_sort16));
  ASSERT_FALSE(bitwuzla_sort_is_bv(d_arr_sort_bv));
  ASSERT_FALSE(bitwuzla_sort_is_bv(d_arr_sort_bvfp));
  ASSERT_FALSE(bitwuzla_sort_is_bv(d_arr_sort_fpbv));
  ASSERT_FALSE(bitwuzla_sort_is_bv(d_fun_sort));
}

TEST_F(TestApi, sort_is_fp)
{
  ASSERT_DEATH(bitwuzla_sort_is_fp(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_sort_is_fp(d_fp_sort16));
  ASSERT_TRUE(bitwuzla_sort_is_fp(d_fp_sort32));
  ASSERT_FALSE(bitwuzla_sort_is_fp(d_bv_sort8));
  ASSERT_FALSE(bitwuzla_sort_is_fp(d_arr_sort_bv));
  ASSERT_FALSE(bitwuzla_sort_is_fp(d_arr_sort_bvfp));
  ASSERT_FALSE(bitwuzla_sort_is_fp(d_fun_sort_fp));
}

TEST_F(TestApi, sort_is_fun)
{
  ASSERT_DEATH(bitwuzla_sort_is_fun(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_sort_is_fun(d_fun_sort));
  ASSERT_TRUE(bitwuzla_sort_is_fun(d_fun_sort_fp));
  ASSERT_TRUE(bitwuzla_sort_is_fun(d_arr_sort_bv));
  ASSERT_TRUE(bitwuzla_sort_is_fun(d_arr_sort_bvfp));
  ASSERT_TRUE(bitwuzla_sort_is_fun(d_arr_sort_fpbv));
  ASSERT_FALSE(bitwuzla_sort_is_fun(d_bv_sort8));
  ASSERT_FALSE(bitwuzla_sort_is_fun(d_fp_sort16));
}

TEST_F(TestApi, sort_is_rm)
{
  ASSERT_DEATH(bitwuzla_sort_is_rm(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_sort_is_rm(d_rm_sort));
  ASSERT_FALSE(bitwuzla_sort_is_rm(d_bv_sort8));
  ASSERT_FALSE(bitwuzla_sort_is_rm(d_fp_sort16));
  ASSERT_FALSE(bitwuzla_sort_is_rm(d_arr_sort_bv));
}

TEST_F(TestApi, sort_dump)
{
  ASSERT_DEATH(bitwuzla_sort_dump(nullptr, "btor", stdout), d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_dump(d_bv_sort1, nullptr, stdout),
               d_error_exp_str);
  ASSERT_DEATH(bitwuzla_sort_dump(d_bv_sort1, "smt2", nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_sort_dump(d_bv_sort1, "asdf", stdout), d_error_format);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_sort_dump(d_bv_sort1, "btor", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_sort_dump(d_bv_sort8, "smt2", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_sort_dump(d_rm_sort, "smt2", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_sort_dump(d_fp_sort32, "smt2", stdout));
  std::cout << std::endl;
}

TEST_F(TestApi, regr1)
{
  std::vector<BitwuzlaSort *> domain({d_bv_sort8});
  BitwuzlaSort *fun_sort =
      bitwuzla_mk_fun_sort(d_bzla, domain.size(), domain.data(), d_bv_sort8);
  ASSERT_NO_FATAL_FAILURE(
      bitwuzla_mk_array_sort(d_bzla, d_bv_sort8, d_bv_sort8));
  std::vector<BitwuzlaTerm *> args({bitwuzla_mk_const(d_bzla, d_bv_sort8, "x"),
                                    bitwuzla_mk_const(d_bzla, fun_sort, "f")});
  ASSERT_DEATH(
      bitwuzla_mk_term(d_bzla, BITWUZLA_KIND_APPLY, args.size(), args.data()),
      d_error_unexp_fun_term);
}

TEST_F(TestApi, regr2)
{
  std::vector<BitwuzlaSort *> domain({d_bv_sort8});
  BitwuzlaSort *fun_sort =
      bitwuzla_mk_fun_sort(d_bzla, domain.size(), domain.data(), d_bv_sort8);
  BitwuzlaSort *array_sort =
      bitwuzla_mk_array_sort(d_bzla, d_bv_sort8, d_bv_sort8);
  ASSERT_NE(fun_sort, array_sort);
  BitwuzlaTerm *fun   = bitwuzla_mk_const(d_bzla, fun_sort, 0);
  BitwuzlaTerm *array = bitwuzla_mk_const(d_bzla, array_sort, 0);
  ASSERT_EQ(array_sort, bitwuzla_term_get_sort(array));
  ASSERT_EQ(fun_sort, bitwuzla_term_get_sort(fun));
  ASSERT_NE(bitwuzla_term_get_sort(fun), bitwuzla_term_get_sort(array));
  ASSERT_TRUE(bitwuzla_term_is_fun(fun));
  ASSERT_TRUE(bitwuzla_term_is_array(array));
}

/* -------------------------------------------------------------------------- */
/* BitwuzlaTerm                                                               */
/* -------------------------------------------------------------------------- */

TEST_F(TestApi, term_hash)
{
  ASSERT_DEATH(bitwuzla_term_hash(nullptr), d_error_not_null);
}

TEST_F(TestApi, term_get_bitwuzla)
{
  ASSERT_DEATH(bitwuzla_term_get_bitwuzla(nullptr), d_error_not_null);
}

TEST_F(TestApi, term_get_sort)
{
  ASSERT_DEATH(bitwuzla_term_get_sort(nullptr), d_error_not_null);
}

TEST_F(TestApi, term_array_get_index_sort)
{
  ASSERT_DEATH(bitwuzla_term_array_get_index_sort(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_array_get_index_sort(d_bv_zero8),
               d_error_exp_arr_term);
  ASSERT_TRUE(
      bitwuzla_sort_is_fp(bitwuzla_term_array_get_index_sort(d_array_fpbv)));
}

TEST_F(TestApi, term_array_get_element_sort)
{
  ASSERT_DEATH(bitwuzla_term_array_get_element_sort(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_array_get_element_sort(d_bv_zero8),
               d_error_exp_arr_term);
  ASSERT_TRUE(
      bitwuzla_sort_is_bv(bitwuzla_term_array_get_element_sort(d_array_fpbv)));
}

TEST_F(TestApi, term_fun_get_domain_sorts)
{
  size_t size;
  BitwuzlaTerm *bv_term = bitwuzla_mk_const(d_bzla, d_bv_sort32, "bv");

  ASSERT_DEATH(bitwuzla_term_fun_get_domain_sorts(nullptr, nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_fun_get_domain_sorts(bv_term, nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_fun_get_domain_sorts(bv_term, &size),
               "expected function term");

  BitwuzlaSort **index_sorts =
      bitwuzla_term_fun_get_domain_sorts(d_array, &size);
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort32, index_sorts[0]));
  ASSERT_EQ(size, 1);

  BitwuzlaSort **domain_sorts =
      bitwuzla_term_fun_get_domain_sorts(d_fun, &size);
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort8, domain_sorts[0]));
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_fp_sort16, domain_sorts[1]));
  ASSERT_TRUE(bitwuzla_sort_is_equal(d_bv_sort32, domain_sorts[2]));
  ASSERT_EQ(size, 3);
}

TEST_F(TestApi, term_fun_get_codomain_sort)
{
  ASSERT_DEATH(bitwuzla_term_fun_get_codomain_sort(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_fun_get_codomain_sort(d_bv_zero8),
               d_error_exp_fun_term);
}

TEST_F(TestApi, term_bv_get_size)
{
  ASSERT_DEATH(bitwuzla_term_bv_get_size(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_bv_get_size(d_fp_const16), d_error_exp_bv_term);
  ASSERT_EQ(bitwuzla_term_bv_get_size(d_bv_zero8), 8);
}

TEST_F(TestApi, term_fp_get_exp_size)
{
  ASSERT_DEATH(bitwuzla_term_fp_get_exp_size(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_fp_get_exp_size(d_bv_const8), d_error_exp_fp_term);
  ASSERT_EQ(bitwuzla_term_fp_get_exp_size(d_fp_const16), 5);
}

TEST_F(TestApi, term_fp_get_sig_size)
{
  ASSERT_DEATH(bitwuzla_term_fp_get_sig_size(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_fp_get_sig_size(d_bv_const8), d_error_exp_fp_term);
  ASSERT_EQ(bitwuzla_term_fp_get_sig_size(d_fp_const16), 11);
}

TEST_F(TestApi, term_fun_get_arity)
{
  ASSERT_DEATH(bitwuzla_term_fun_get_arity(nullptr), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_fun_get_arity(d_bv_const8), d_error_exp_fun_term);
  ASSERT_EQ(bitwuzla_term_fun_get_arity(d_fun), 3);
}

TEST_F(TestApi, term_get_symbol)
{
  ASSERT_DEATH(bitwuzla_term_get_symbol(nullptr), d_error_not_null);
  ASSERT_EQ(std::string(bitwuzla_term_get_symbol(d_fun)), std::string("fun"));
}

TEST_F(TestApi, term_set_symbol)
{
  ASSERT_DEATH(bitwuzla_term_set_symbol(nullptr, "fun"), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_set_symbol(d_fun, nullptr), d_error_exp_str);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_term_set_symbol(d_fun, "funfun"));
  ASSERT_EQ(std::string(bitwuzla_term_get_symbol(d_fun)),
            std::string("funfun"));
}

TEST_F(TestApi, term_is_equal_sort)
{
  ASSERT_DEATH(bitwuzla_term_is_equal_sort(nullptr, d_bv_const1),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_is_equal_sort(d_bv_const1, nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_is_equal_sort(d_bv_const8, d_other_bv_const8),
               "given terms are not associated with the same solver instance");
  ASSERT_TRUE(bitwuzla_term_is_equal_sort(d_bv_const8, d_bv_zero8));
  ASSERT_FALSE(bitwuzla_term_is_equal_sort(d_bv_const1, d_bv_zero8));
}

TEST_F(TestApi, term_is_const)
{
  ASSERT_DEATH(bitwuzla_term_is_const(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_const(d_array));
  ASSERT_TRUE(bitwuzla_term_is_const(d_fun));
  ASSERT_TRUE(bitwuzla_term_is_const(d_bv_const1));
  ASSERT_TRUE(bitwuzla_term_is_const(d_fp_const16));
  ASSERT_TRUE(bitwuzla_term_is_const(d_rm_const));
  ASSERT_FALSE(bitwuzla_term_is_const(d_bv_one1));
  ASSERT_FALSE(bitwuzla_term_is_const(d_store));
}

TEST_F(TestApi, term_is_var)
{
  ASSERT_DEATH(bitwuzla_term_is_var(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_var(d_var1));
  ASSERT_TRUE(bitwuzla_term_is_var(d_bound_var));
  ASSERT_FALSE(bitwuzla_term_is_var(d_fp_pzero32));
}

TEST_F(TestApi, term_is_bound_var)
{
  ASSERT_DEATH(bitwuzla_term_is_bound_var(nullptr), d_error_not_null);
  ASSERT_FALSE(bitwuzla_term_is_bound_var(d_var1));
  ASSERT_TRUE(bitwuzla_term_is_bound_var(d_bound_var));
  ASSERT_DEATH(bitwuzla_term_is_bound_var(d_fp_pzero32), d_error_exp_var_term);
}

TEST_F(TestApi, term_is_array)
{
  ASSERT_DEATH(bitwuzla_term_is_array(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_array(d_array));
  ASSERT_TRUE(bitwuzla_term_is_array(d_store));
  ASSERT_FALSE(bitwuzla_term_is_array(d_fun));
  ASSERT_FALSE(bitwuzla_term_is_array(d_fp_pzero32));
}

TEST_F(TestApi, term_is_bv)
{
  ASSERT_DEATH(bitwuzla_term_is_bv(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv(d_bv_zero8));
  ASSERT_FALSE(bitwuzla_term_is_bv(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_bv(d_array));
  ASSERT_FALSE(bitwuzla_term_is_bv(d_array_fpbv));
  ASSERT_FALSE(bitwuzla_term_is_bv(d_fun));
}

TEST_F(TestApi, term_is_fp)
{
  ASSERT_DEATH(bitwuzla_term_is_fp(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp(d_bv_zero8));
  ASSERT_FALSE(bitwuzla_term_is_fp(d_array));
  ASSERT_FALSE(bitwuzla_term_is_fp(d_array_fpbv));
  ASSERT_FALSE(bitwuzla_term_is_fp(d_fun));
}

TEST_F(TestApi, term_is_fun)
{
  ASSERT_DEATH(bitwuzla_term_is_fun(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fun(d_fun));
  ASSERT_FALSE(bitwuzla_term_is_fun(d_array));
  ASSERT_FALSE(bitwuzla_term_is_fun(d_array_fpbv));
  ASSERT_FALSE(bitwuzla_term_is_fun(d_fp_pzero32));
}

TEST_F(TestApi, term_is_rm)
{
  ASSERT_DEATH(bitwuzla_term_is_rm(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_rm(d_rm_const));
  ASSERT_FALSE(bitwuzla_term_is_rm(d_bv_zero8));
}

TEST_F(TestApi, term_is_bv_value)
{
  ASSERT_DEATH(bitwuzla_term_is_bv_value(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv_value(d_bv_zero8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value(d_bv_const1));
}

TEST_F(TestApi, term_is_fp_value)
{
  ASSERT_DEATH(bitwuzla_term_is_fp_value(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp_value(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value(d_fp_const16));
}

TEST_F(TestApi, term_is_rm_value)
{
  ASSERT_DEATH(bitwuzla_term_is_rm_value(nullptr), d_error_not_null);
  ASSERT_TRUE(
      bitwuzla_term_is_rm_value(bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNE)));
  ASSERT_FALSE(bitwuzla_term_is_rm_value(d_rm_const));
}

TEST_F(TestApi, term_is_bv_value_zero)
{
  ASSERT_DEATH(bitwuzla_term_is_bv_value_zero(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv_value_zero(d_bv_zero8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_zero(d_bv_one1));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_zero(d_bv_ones23));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_zero(d_bv_mins8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_zero(d_bv_maxs8));
}

TEST_F(TestApi, term_is_bv_value_one)
{
  ASSERT_DEATH(bitwuzla_term_is_bv_value_one(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv_value_one(d_bv_one1));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_one(d_bv_ones23));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_one(d_bv_mins8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_one(d_bv_maxs8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_one(d_bv_zero8));
}

TEST_F(TestApi, term_is_bv_value_ones)
{
  ASSERT_DEATH(bitwuzla_term_is_bv_value_ones(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv_value_ones(d_bv_ones23));
  ASSERT_TRUE(bitwuzla_term_is_bv_value_ones(d_bv_one1));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_ones(d_bv_mins8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_ones(d_bv_maxs8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_ones(d_bv_zero8));
}

TEST_F(TestApi, term_is_bv_value_min_signed)
{
  ASSERT_DEATH(bitwuzla_term_is_bv_value_min_signed(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv_value_min_signed(d_bv_mins8));
  ASSERT_TRUE(bitwuzla_term_is_bv_value_min_signed(d_bv_one1));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_min_signed(d_bv_ones23));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_min_signed(d_bv_maxs8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_min_signed(d_bv_zero8));
}

TEST_F(TestApi, term_is_bv_value_max_signed)
{
  ASSERT_DEATH(bitwuzla_term_is_bv_value_max_signed(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_bv_value_max_signed(d_bv_maxs8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_max_signed(d_bv_mins8));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_max_signed(d_bv_one1));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_max_signed(d_bv_ones23));
  ASSERT_FALSE(bitwuzla_term_is_bv_value_max_signed(d_bv_zero8));
}

TEST_F(TestApi, term_is_fp_value_pos_zero)
{
  ASSERT_DEATH(bitwuzla_term_is_fp_value_pos_zero(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp_value_pos_zero(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_zero(d_fp_nzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_zero(d_fp_pinf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_zero(d_fp_ninf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_zero(d_fp_nan32));
}

TEST_F(TestApi, term_is_fp_value_neg_zero)
{
  ASSERT_DEATH(bitwuzla_term_is_fp_value_neg_zero(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp_value_neg_zero(d_fp_nzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_zero(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_zero(d_fp_pinf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_zero(d_fp_ninf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_zero(d_fp_nan32));
}

TEST_F(TestApi, term_is_fp_value_pos_inf)
{
  ASSERT_DEATH(bitwuzla_term_is_fp_value_pos_inf(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp_value_pos_inf(d_fp_pinf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_inf(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_inf(d_fp_nzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_inf(d_fp_ninf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_pos_inf(d_fp_nan32));
}

TEST_F(TestApi, term_is_fp_value_neg_inf)
{
  ASSERT_DEATH(bitwuzla_term_is_fp_value_neg_inf(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp_value_neg_inf(d_fp_ninf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_inf(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_inf(d_fp_nzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_inf(d_fp_pinf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_neg_inf(d_fp_nan32));
}

TEST_F(TestApi, term_is_fp_value_nan)
{
  ASSERT_DEATH(bitwuzla_term_is_fp_value_nan(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_fp_value_nan(d_fp_nan32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_nan(d_fp_pzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_nan(d_fp_nzero32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_nan(d_fp_pinf32));
  ASSERT_FALSE(bitwuzla_term_is_fp_value_nan(d_fp_ninf32));
}

TEST_F(TestApi, term_is_const_array)
{
  ASSERT_DEATH(bitwuzla_term_is_const_array(nullptr), d_error_not_null);
  ASSERT_TRUE(bitwuzla_term_is_const_array(
      bitwuzla_mk_const_array(d_bzla, d_arr_sort_bv, d_bv_zero8)));
  ASSERT_FALSE(bitwuzla_term_is_const_array(d_array));
  ASSERT_FALSE(bitwuzla_term_is_const_array(d_array_fpbv));
}

TEST_F(TestApi, term_dump)
{
  ASSERT_DEATH(bitwuzla_term_dump(nullptr, "btor", stdout), d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_dump(d_and_bv_const1, nullptr, stdout),
               d_error_exp_str);
  ASSERT_DEATH(bitwuzla_term_dump(d_and_bv_const1, "smt2", nullptr),
               d_error_not_null);
  ASSERT_DEATH(bitwuzla_term_dump(d_and_bv_const1, "asdf", stdout),
               d_error_format);
  ASSERT_NO_FATAL_FAILURE(bitwuzla_term_dump(d_and_bv_const1, "btor", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_term_dump(d_and_bv_const1, "smt2", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_term_dump(d_other_exists, "btor", stdout));
  ASSERT_NO_FATAL_FAILURE(bitwuzla_term_dump(d_other_exists, "smt2", stdout));
  std::cout << std::endl;
}

TEST_F(TestApi, term_dump_regr0)
{
  BitwuzlaTerm *rne = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNE);
  BitwuzlaTerm *rna = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNA);
  BitwuzlaTerm *rtn = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTN);
  BitwuzlaTerm *rtp = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTP);
  BitwuzlaTerm *rtz = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RTZ);

  testing::internal::CaptureStdout();

  bitwuzla_term_dump(rne, "smt2", stdout);
  printf("\n");
  bitwuzla_term_dump(rna, "smt2", stdout);
  printf("\n");
  bitwuzla_term_dump(rtn, "smt2", stdout);
  printf("\n");
  bitwuzla_term_dump(rtp, "smt2", stdout);
  printf("\n");
  bitwuzla_term_dump(rtz, "smt2", stdout);

  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_EQ(output, "RNE\nRNA\nRTN\nRTP\nRTZ");
}

TEST_F(TestApi, term_dump_regr1)
{
  BitwuzlaSort *bv_sort5  = bitwuzla_mk_bv_sort(d_bzla, 5);
  BitwuzlaSort *bv_sort10 = bitwuzla_mk_bv_sort(d_bzla, 10);

  BitwuzlaTerm *fp_const;
  std::string output;

  fp_const = bitwuzla_mk_fp_value(d_bzla,
                                  bitwuzla_mk_bv_zero(d_bzla, d_bv_sort1),
                                  bitwuzla_mk_bv_zero(d_bzla, bv_sort5),
                                  bitwuzla_mk_bv_zero(d_bzla, bv_sort10));

  testing::internal::CaptureStdout();
  bitwuzla_term_dump(fp_const, "smt2", stdout);
  output = testing::internal::GetCapturedStdout();
  ASSERT_EQ(output, "(fp #b0 #b00000 #b0000000000)");

  fp_const = bitwuzla_mk_fp_value(d_bzla,
                                  bitwuzla_mk_bv_one(d_bzla, d_bv_sort1),
                                  bitwuzla_mk_bv_zero(d_bzla, bv_sort5),
                                  bitwuzla_mk_bv_zero(d_bzla, bv_sort10));

  testing::internal::CaptureStdout();
  bitwuzla_term_dump(fp_const, "smt2", stdout);
  output = testing::internal::GetCapturedStdout();
  ASSERT_EQ(output, "(fp #b1 #b00000 #b0000000000)");

  fp_const = bitwuzla_mk_fp_value(d_bzla,
                                  bitwuzla_mk_bv_zero(d_bzla, d_bv_sort1),
                                  bitwuzla_mk_bv_zero(d_bzla, bv_sort5),
                                  bitwuzla_mk_bv_one(d_bzla, bv_sort10));

  testing::internal::CaptureStdout();
  bitwuzla_term_dump(fp_const, "smt2", stdout);
  output = testing::internal::GetCapturedStdout();
  ASSERT_EQ(output, "(fp #b0 #b00000 #b0000000001)");

  fp_const = bitwuzla_mk_fp_value(d_bzla,
                                  bitwuzla_mk_bv_one(d_bzla, d_bv_sort1),
                                  bitwuzla_mk_bv_zero(d_bzla, bv_sort5),
                                  bitwuzla_mk_bv_one(d_bzla, bv_sort10));

  testing::internal::CaptureStdout();
  bitwuzla_term_dump(fp_const, "smt2", stdout);
  output = testing::internal::GetCapturedStdout();
  ASSERT_EQ(output, "(fp #b1 #b00000 #b0000000001)");
}

TEST_F(TestApi, reset)
{
  Bitwuzla *bzla                         = bitwuzla_new();
  BitwuzlaSort *s                        = bitwuzla_mk_bv_sort(bzla, 8);
  BitwuzlaTerm *x                        = bitwuzla_mk_const(bzla, s, "x");
  std::vector<BitwuzlaTerm *> args       = {x, x};
  bitwuzla_assert(
      bzla,
      bitwuzla_mk_term(bzla, BITWUZLA_KIND_DISTINCT, args.size(), args.data()));
  ASSERT_EQ(BITWUZLA_UNSAT, bitwuzla_check_sat(bzla));
  bitwuzla_reset(bzla);
  s = bitwuzla_mk_bv_sort(bzla, 8);
  x = bitwuzla_mk_const(bzla, s, "x");
  ASSERT_EQ(BITWUZLA_SAT, bitwuzla_check_sat(bzla));
  bitwuzla_delete(bzla);
}

TEST_F(TestApi, indexed)
{
  BitwuzlaSort *fp_sort = bitwuzla_mk_fp_sort(d_bzla, 5, 11);
  BitwuzlaSort *bv_sort = bitwuzla_mk_bv_sort(d_bzla, 8);
  BitwuzlaTerm *fp_term = bitwuzla_mk_const(d_bzla, fp_sort, 0);
  BitwuzlaTerm *bv_term = bitwuzla_mk_const(d_bzla, bv_sort, 0);
  BitwuzlaTerm *rm      = bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNE);

  size_t size;
  uint32_t *indices;
  BitwuzlaTerm *idx;

  idx = bitwuzla_mk_term2_indexed1(
      d_bzla, BITWUZLA_KIND_FP_TO_SBV, rm, fp_term, 8);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 1);
  ASSERT_EQ(indices[0], 8);

  idx = bitwuzla_mk_term2_indexed1(
      d_bzla, BITWUZLA_KIND_FP_TO_UBV, rm, fp_term, 9);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 1);
  ASSERT_EQ(indices[0], 9);

  idx = bitwuzla_mk_term1_indexed2(
      d_bzla, BITWUZLA_KIND_FP_TO_FP_FROM_BV, bv_term, 3, 5);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 2);
  ASSERT_EQ(indices[0], 3);
  ASSERT_EQ(indices[1], 5);

  idx = bitwuzla_mk_term2_indexed2(
      d_bzla, BITWUZLA_KIND_FP_TO_FP_FROM_FP, rm, fp_term, 7, 18);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 2);
  ASSERT_EQ(indices[0], 7);
  ASSERT_EQ(indices[1], 18);

  idx = bitwuzla_mk_term2_indexed2(
      d_bzla, BITWUZLA_KIND_FP_TO_FP_FROM_SBV, rm, bv_term, 8, 24);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 2);
  ASSERT_EQ(indices[0], 8);
  ASSERT_EQ(indices[1], 24);

  idx = bitwuzla_mk_term2_indexed2(
      d_bzla, BITWUZLA_KIND_FP_TO_FP_FROM_UBV, rm, bv_term, 5, 11);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 2);
  ASSERT_EQ(indices[0], 5);
  ASSERT_EQ(indices[1], 11);

  idx = bitwuzla_mk_term1_indexed2(
      d_bzla, BITWUZLA_KIND_BV_EXTRACT, bv_term, 6, 0);
  ASSERT_TRUE(bitwuzla_term_is_indexed(idx));
  indices = bitwuzla_term_get_indices(idx, &size);
  ASSERT_EQ(size, 2);
  ASSERT_EQ(indices[0], 6);
  ASSERT_EQ(indices[1], 0);
}

TEST_F(TestApi, terms)
{
  BitwuzlaSort *fp_sort    = bitwuzla_mk_fp_sort(d_bzla, 5, 11);
  BitwuzlaSort *bv_sort    = bitwuzla_mk_bv_sort(d_bzla, 16);
  BitwuzlaSort *bool_sort  = bitwuzla_mk_bool_sort(d_bzla);
  BitwuzlaSort *array_sort = bitwuzla_mk_array_sort(d_bzla, bv_sort, bv_sort);
  std::vector<BitwuzlaSort *> domain = {
      bv_sort,
      bv_sort,
      bv_sort,
  };
  BitwuzlaSort *fun_sort =
      bitwuzla_mk_fun_sort(d_bzla, domain.size(), domain.data(), bv_sort);

  std::vector<BitwuzlaTerm *> fp_args = {
      bitwuzla_mk_rm_value(d_bzla, BITWUZLA_RM_RNA),
      bitwuzla_mk_const(d_bzla, fp_sort, nullptr),
      bitwuzla_mk_const(d_bzla, fp_sort, nullptr),
      bitwuzla_mk_const(d_bzla, fp_sort, nullptr),
  };

  std::vector<BitwuzlaTerm *> bv_args = {
      bitwuzla_mk_const(d_bzla, bv_sort, nullptr),
      bitwuzla_mk_const(d_bzla, bv_sort, nullptr),
      bitwuzla_mk_const(d_bzla, bv_sort, nullptr),
      bitwuzla_mk_const(d_bzla, bv_sort, nullptr),
  };

  std::vector<BitwuzlaTerm *> bool_args = {
      bitwuzla_mk_const(d_bzla, bool_sort, nullptr),
      bitwuzla_mk_const(d_bzla, bool_sort, nullptr),
  };

  BitwuzlaKind kind;
  BitwuzlaTerm *term;
  for (size_t i = 0; i < BITWUZLA_NUM_KINDS; ++i)
  {
    kind = static_cast<BitwuzlaKind>(i);

    term = nullptr;
    switch (kind)
    {
      // Boolean
      case BITWUZLA_KIND_NOT:
        term = bitwuzla_mk_term1(d_bzla, kind, bool_args[0]);
        break;

      case BITWUZLA_KIND_AND:
      case BITWUZLA_KIND_IFF:
      case BITWUZLA_KIND_IMPLIES:
      case BITWUZLA_KIND_OR:
      case BITWUZLA_KIND_XOR:
        term =
            bitwuzla_mk_term(d_bzla, kind, bool_args.size(), bool_args.data());
        break;

      // BV Unary
      case BITWUZLA_KIND_BV_DEC:
      case BITWUZLA_KIND_BV_INC:
      case BITWUZLA_KIND_BV_NEG:
      case BITWUZLA_KIND_BV_NOT:
      case BITWUZLA_KIND_BV_REDAND:
      case BITWUZLA_KIND_BV_REDOR:
      case BITWUZLA_KIND_BV_REDXOR:
        term = bitwuzla_mk_term(d_bzla, kind, 1, bv_args.data());
        break;

      // BV Binary
      case BITWUZLA_KIND_BV_ASHR:
      case BITWUZLA_KIND_BV_COMP:
      case BITWUZLA_KIND_BV_NAND:
      case BITWUZLA_KIND_BV_NOR:
      case BITWUZLA_KIND_BV_ROL:
      case BITWUZLA_KIND_BV_ROR:
      case BITWUZLA_KIND_BV_SADD_OVERFLOW:
      case BITWUZLA_KIND_BV_SDIV_OVERFLOW:
      case BITWUZLA_KIND_BV_SDIV:
      case BITWUZLA_KIND_BV_SGE:
      case BITWUZLA_KIND_BV_SGT:
      case BITWUZLA_KIND_BV_SHL:
      case BITWUZLA_KIND_BV_SHR:
      case BITWUZLA_KIND_BV_SLE:
      case BITWUZLA_KIND_BV_SLT:
      case BITWUZLA_KIND_BV_SMOD:
      case BITWUZLA_KIND_BV_SMUL_OVERFLOW:
      case BITWUZLA_KIND_BV_SREM:
      case BITWUZLA_KIND_BV_SSUB_OVERFLOW:
      case BITWUZLA_KIND_BV_SUB:
      case BITWUZLA_KIND_BV_UADD_OVERFLOW:
      case BITWUZLA_KIND_BV_UDIV:
      case BITWUZLA_KIND_BV_UGE:
      case BITWUZLA_KIND_BV_UGT:
      case BITWUZLA_KIND_BV_ULE:
      case BITWUZLA_KIND_BV_ULT:
      case BITWUZLA_KIND_BV_UMUL_OVERFLOW:
      case BITWUZLA_KIND_BV_UREM:
      case BITWUZLA_KIND_BV_USUB_OVERFLOW:
      case BITWUZLA_KIND_BV_XNOR:
        term = bitwuzla_mk_term(d_bzla, kind, 2, bv_args.data());
        break;

      // BV Binary+
      case BITWUZLA_KIND_BV_ADD:
      case BITWUZLA_KIND_BV_AND:
      case BITWUZLA_KIND_BV_CONCAT:
      case BITWUZLA_KIND_BV_MUL:
      case BITWUZLA_KIND_BV_OR:
      case BITWUZLA_KIND_BV_XOR:
        term = bitwuzla_mk_term(d_bzla, kind, bv_args.size(), bv_args.data());
        break;

      case BITWUZLA_KIND_DISTINCT:
      case BITWUZLA_KIND_EQUAL:
        term = bitwuzla_mk_term(d_bzla, kind, 2, bv_args.data());
        break;

      // BV indexed
      case BITWUZLA_KIND_BV_EXTRACT:
        term = bitwuzla_mk_term1_indexed2(d_bzla, kind, bv_args[0], 3, 2);
        break;

      case BITWUZLA_KIND_BV_REPEAT:
      case BITWUZLA_KIND_BV_ROLI:
      case BITWUZLA_KIND_BV_RORI:
      case BITWUZLA_KIND_BV_SIGN_EXTEND:
      case BITWUZLA_KIND_BV_ZERO_EXTEND:
        term = bitwuzla_mk_term1_indexed1(d_bzla, kind, bv_args[0], 5);
        break;

      // Arrays
      case BITWUZLA_KIND_ARRAY_SELECT: {
        std::vector<BitwuzlaTerm *> args = {
            bitwuzla_mk_const(d_bzla, array_sort, nullptr),
            bv_args[0],
        };
        term = bitwuzla_mk_term(d_bzla, kind, args.size(), args.data());
        break;
      }

      case BITWUZLA_KIND_ARRAY_STORE: {
        std::vector<BitwuzlaTerm *> args = {
            bitwuzla_mk_const(d_bzla, array_sort, nullptr),
            bv_args[0],
            bv_args[1],
        };
        term = bitwuzla_mk_term(d_bzla, kind, args.size(), args.data());
        break;
      }

      case BITWUZLA_KIND_APPLY: {
        std::vector<BitwuzlaTerm *> args = {
            bitwuzla_mk_const(d_bzla, fun_sort, nullptr),
            bv_args[0],
            bv_args[1],
            bv_args[2],
        };
        term = bitwuzla_mk_term(d_bzla, kind, args.size(), args.data());
        break;
      }

      // Binder
      case BITWUZLA_KIND_EXISTS:
      case BITWUZLA_KIND_FORALL:
      case BITWUZLA_KIND_LAMBDA: {
        std::vector<BitwuzlaTerm *> args = {
            bitwuzla_mk_var(d_bzla, bv_sort, nullptr),
            bitwuzla_mk_var(d_bzla, bv_sort, nullptr),
        };
        // body
        args.push_back(bitwuzla_mk_term(
            d_bzla, BITWUZLA_KIND_BV_SLT, args.size(), args.data()));
        term = bitwuzla_mk_term(d_bzla, kind, args.size(), args.data());
        break;
      }

      // FP Unary
      case BITWUZLA_KIND_FP_ABS:
      case BITWUZLA_KIND_FP_IS_INF:
      case BITWUZLA_KIND_FP_IS_NAN:
      case BITWUZLA_KIND_FP_IS_NEG:
      case BITWUZLA_KIND_FP_IS_NORMAL:
      case BITWUZLA_KIND_FP_IS_POS:
      case BITWUZLA_KIND_FP_IS_SUBNORMAL:
      case BITWUZLA_KIND_FP_IS_ZERO:
      case BITWUZLA_KIND_FP_NEG:
        term = bitwuzla_mk_term1(d_bzla, kind, fp_args[1]);
        break;

      // FP Binary
      case BITWUZLA_KIND_FP_EQ:
      case BITWUZLA_KIND_FP_GEQ:
      case BITWUZLA_KIND_FP_GT:
      case BITWUZLA_KIND_FP_LEQ:
      case BITWUZLA_KIND_FP_LT:
      case BITWUZLA_KIND_FP_MAX:
      case BITWUZLA_KIND_FP_MIN:
      case BITWUZLA_KIND_FP_REM:
        term = bitwuzla_mk_term(d_bzla, kind, 2, fp_args.data() + 1);
        break;

      case BITWUZLA_KIND_FP_SQRT:
      case BITWUZLA_KIND_FP_RTI:
        term = bitwuzla_mk_term(d_bzla, kind, 2, fp_args.data());
        break;

      // FP Ternary
      case BITWUZLA_KIND_FP_ADD:
      case BITWUZLA_KIND_FP_DIV:
      case BITWUZLA_KIND_FP_MUL:
      case BITWUZLA_KIND_FP_SUB:
        term = bitwuzla_mk_term(d_bzla, kind, 3, fp_args.data());
        break;

      case BITWUZLA_KIND_FP_FP: {
        std::vector<BitwuzlaTerm *> args = {
            bool_args[0],
            bv_args[0],
            bv_args[1],
        };
        term = bitwuzla_mk_term(d_bzla, kind, args.size(), args.data());
        break;
      }

      // FP Quaternery
      case BITWUZLA_KIND_FP_FMA:
        term = bitwuzla_mk_term(d_bzla, kind, fp_args.size(), fp_args.data());
        break;

      // FP indexed
      case BITWUZLA_KIND_FP_TO_FP_FROM_BV:
        term = bitwuzla_mk_term1_indexed2(d_bzla, kind, bv_args[0], 5, 11);
        break;

      case BITWUZLA_KIND_FP_TO_FP_FROM_SBV:
      case BITWUZLA_KIND_FP_TO_FP_FROM_UBV:
        term = bitwuzla_mk_term2_indexed2(
            d_bzla, kind, fp_args[0], bv_args[0], 5, 11);
        break;

      case BITWUZLA_KIND_FP_TO_FP_FROM_FP:
        term = bitwuzla_mk_term2_indexed2(
            d_bzla, kind, fp_args[0], fp_args[1], 5, 11);
        break;

      case BITWUZLA_KIND_FP_TO_SBV:
      case BITWUZLA_KIND_FP_TO_UBV:
        term = bitwuzla_mk_term2_indexed1(
            d_bzla, kind, fp_args[0], fp_args[1], 16);
        break;

      // Others
      case BITWUZLA_KIND_ITE: {
        std::vector<BitwuzlaTerm *> args = {
            bool_args[0],
            bv_args[0],
            bv_args[1],
        };
        term = bitwuzla_mk_term(d_bzla, kind, args.size(), args.data());
        break;
      }

      default: break;
    }
    // Unhandled BitwuzlaKind
    ASSERT_NE(term, nullptr);

    size_t size;
    BitwuzlaTerm **children = bitwuzla_term_get_children(term, &size);

    if (bitwuzla_term_is_const(term) || bitwuzla_term_is_var(term)
        || bitwuzla_term_is_value(term))
    {
      assert(size == 0);
      ASSERT_EQ(size, 0);
      ASSERT_EQ(children, nullptr);
      continue;
    }

    ASSERT_GT(size, 0);
    ASSERT_NE(children, nullptr);
    for (size_t i = 0; i < size; ++i)
    {
      ASSERT_NE(children[i], nullptr);
    }

    BitwuzlaTerm *tterm;
    if (bitwuzla_term_is_const_array(term))
    {
      ASSERT_EQ(size, 1);
      tterm = bitwuzla_mk_const_array(
          d_bzla, bitwuzla_term_get_sort(term), children[0]);
    }
    else
    {
      kind = bitwuzla_term_get_kind(term);
      if (bitwuzla_term_is_indexed(term))
      {
        size_t num_indices;
        uint32_t *indices = bitwuzla_term_get_indices(term, &num_indices);
        tterm             = bitwuzla_mk_term_indexed(
            d_bzla, kind, size, children, num_indices, indices);
      }
      else if (kind == BITWUZLA_KIND_LAMBDA || kind == BITWUZLA_KIND_FORALL
               || kind == BITWUZLA_KIND_EXISTS)
      {
        // TODO: variables are already bound and can't be passed to mk_term
        // create new vars and substitute
        tterm = term;
      }
      else
      {
        assert(kind != BITWUZLA_KIND_BV_NOT || size == 1);
        tterm = bitwuzla_mk_term(d_bzla, kind, size, children);
      }
    }
    ASSERT_EQ(tterm, term);
  }

  size_t size;
  BitwuzlaTerm *t;

  t = bitwuzla_mk_const(d_bzla, bv_sort, nullptr);
  ASSERT_DEATH(bitwuzla_term_get_kind(t), "cannot get kind");
  ASSERT_EQ(bitwuzla_term_get_children(t, &size), nullptr);
  ASSERT_EQ(size, 0);

  t = bitwuzla_mk_var(d_bzla, bv_sort, nullptr);
  ASSERT_DEATH(bitwuzla_term_get_kind(t), "cannot get kind");
  ASSERT_EQ(bitwuzla_term_get_children(t, &size), nullptr);
  ASSERT_EQ(size, 0);

  t = bitwuzla_mk_bv_value(d_bzla, bv_sort, "43", BITWUZLA_BV_BASE_DEC);
  ASSERT_DEATH(bitwuzla_term_get_kind(t), "cannot get kind");
  ASSERT_EQ(bitwuzla_term_get_children(t, &size), nullptr);
  ASSERT_EQ(size, 0);

  t = bitwuzla_mk_const_array(d_bzla, array_sort, t);
  ASSERT_DEATH(bitwuzla_term_get_kind(t), "cannot get kind");
  ASSERT_NE(bitwuzla_term_get_children(t, &size), nullptr);
  ASSERT_EQ(size, 1);
}

TEST_F(TestApi, substitute)
{
  BitwuzlaSort *bv_sort              = bitwuzla_mk_bv_sort(d_bzla, 16);
  BitwuzlaSort *bool_sort            = bitwuzla_mk_bool_sort(d_bzla);
  std::vector<BitwuzlaSort *> domain = {
      bv_sort,
      bv_sort,
      bv_sort,
  };
  BitwuzlaSort *fun_sort =
      bitwuzla_mk_fun_sort(d_bzla, domain.size(), domain.data(), bool_sort);
  BitwuzlaSort *array_sort = bitwuzla_mk_array_sort(d_bzla, bv_sort, bv_sort);

  BitwuzlaTerm *bv_const = bitwuzla_mk_const(d_bzla, bv_sort, 0);
  BitwuzlaTerm *bv_value =
      bitwuzla_mk_bv_value(d_bzla, bv_sort, "143", BITWUZLA_BV_BASE_DEC);

  BitwuzlaTerm *result;

  // simple substitution const -> value
  {
    std::vector<BitwuzlaTerm *> keys   = {bv_const};
    std::vector<BitwuzlaTerm *> values = {bv_value};
    result                             = bitwuzla_substitute_term(
        d_bzla, bv_const, keys.size(), keys.data(), values.data());
    ASSERT_EQ(result, bv_value);
  }

  // (sdiv x y) -> (sdiv value y)
  {
    BitwuzlaTerm *x = bitwuzla_mk_const(d_bzla, bv_sort, 0);
    BitwuzlaTerm *y = bitwuzla_mk_const(d_bzla, bv_sort, 0);

    std::vector<BitwuzlaTerm *> keys   = {x};
    std::vector<BitwuzlaTerm *> values = {bv_value};

    result = bitwuzla_substitute_term(
        d_bzla,
        bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_BV_SDIV, x, y),
        keys.size(),
        keys.data(),
        values.data());
    ASSERT_EQ(result,
              bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_BV_SDIV, bv_value, y));
  }

  // partial substitution of variables in quantified formula
  {
    std::vector<BitwuzlaTerm *> args = {
        bitwuzla_mk_const(d_bzla, fun_sort, 0),
        bitwuzla_mk_var(d_bzla, bv_sort, "x"),
        bitwuzla_mk_var(d_bzla, bv_sort, "y"),
        bitwuzla_mk_var(d_bzla, bv_sort, "z"),
    };
    args.push_back(bitwuzla_mk_term(
        d_bzla, BITWUZLA_KIND_APPLY, args.size(), args.data()));
    BitwuzlaTerm *q = bitwuzla_mk_term(
        d_bzla, BITWUZLA_KIND_FORALL, args.size() - 1, args.data() + 1);

    std::vector<BitwuzlaTerm *> keys   = {args[1], args[2]};
    std::vector<BitwuzlaTerm *> values = {
        bitwuzla_mk_const(d_bzla, bv_sort, 0),
        bitwuzla_mk_const(d_bzla, bv_sort, 0),
    };

    // Build expected
    std::vector<BitwuzlaTerm *> args_expected = {
        args[0],
        values[0],
        values[1],
        bitwuzla_mk_var(d_bzla, bv_sort, 0),
    };
    args_expected.push_back(bitwuzla_mk_term(d_bzla,
                                             BITWUZLA_KIND_APPLY,
                                             args_expected.size(),
                                             args_expected.data()));
    BitwuzlaTerm *expected =
        bitwuzla_mk_term(d_bzla, BITWUZLA_KIND_FORALL, 2, &args_expected[3]);

    result = bitwuzla_substitute_term(
        d_bzla, q, keys.size(), keys.data(), values.data());
    ASSERT_EQ(result, expected);
  }

  // substitute term in constant array
  {
    BitwuzlaTerm *term = bitwuzla_mk_const(d_bzla, bv_sort, 0);
    BitwuzlaTerm *const_array =
        bitwuzla_mk_const_array(d_bzla, array_sort, term);

    std::vector<BitwuzlaTerm *> keys   = {term};
    std::vector<BitwuzlaTerm *> values = {bv_value};

    result = bitwuzla_substitute_term(
        d_bzla, const_array, keys.size(), keys.data(), values.data());

    BitwuzlaTerm *expected =
        bitwuzla_mk_const_array(d_bzla, array_sort, bv_value);
    ASSERT_EQ(result, expected);
    ASSERT_TRUE(bitwuzla_term_is_const_array(result));
  }
}

TEST_F(TestApi, term_dump1)
{
  std::string filename = "term_dump1.out";
  FILE *tmpfile        = fopen(filename.c_str(), "w");
  BitwuzlaSort *bv1    = bitwuzla_mk_bool_sort(d_bzla);
  BitwuzlaTerm *a      = bitwuzla_mk_const(d_bzla, bv1, "a");
  BitwuzlaTerm *nota   = bitwuzla_mk_term1(d_bzla, BITWUZLA_KIND_NOT, a);
  bitwuzla_term_dump(nota, "smt2", tmpfile);
  fclose(tmpfile);

  std::ifstream ifs(filename);
  std::string content((std::istreambuf_iterator<char>(ifs)),
                      (std::istreambuf_iterator<char>()));
  unlink(filename.c_str());

  ASSERT_EQ("(bvnot a)", content);
}

TEST_F(TestApi, term_dump2)
{
  std::string filename = "term_dump2.out";
  FILE *tmpfile        = fopen(filename.c_str(), "w");

  BitwuzlaSort *bv1 = bitwuzla_mk_bv_sort(d_bzla, 1);
  BitwuzlaSort *fn1_1 = bitwuzla_mk_fun_sort(d_bzla, 1, &bv1, bv1);
  BitwuzlaTerm *f = bitwuzla_mk_const(d_bzla, fn1_1, "f");
  bitwuzla_term_dump(f, "smt2", tmpfile);
  fclose(tmpfile);

  std::ifstream ifs(filename);
  std::string content((std::istreambuf_iterator<char>(ifs)),
                      (std::istreambuf_iterator<char>()));
  unlink(filename.c_str());

  ASSERT_EQ("(declare-fun f ((_ BitVec 1)) (_ BitVec 1))\n", content);
}

TEST_F(TestApi, term_dump3)
{
  std::string filename = "term_dump3.out";
  FILE *tmpfile        = fopen(filename.c_str(), "w");

  BitwuzlaSort *bv1   = bitwuzla_mk_bv_sort(d_bzla, 1);
  BitwuzlaSort *ar1_1 = bitwuzla_mk_array_sort(d_bzla, bv1, bv1);
  BitwuzlaTerm *a     = bitwuzla_mk_const(d_bzla, ar1_1, "a");
  bitwuzla_term_dump(a, "smt2", tmpfile);
  fclose(tmpfile);

  std::ifstream ifs(filename);
  std::string content((std::istreambuf_iterator<char>(ifs)),
                      (std::istreambuf_iterator<char>()));
  unlink(filename.c_str());

  ASSERT_EQ("(declare-const a (Array (_ BitVec 1) (_ BitVec 1)))\n", content);
}

TEST_F(TestApi, dump_formula2)
{
  std::string filename = "formula_dump2.out";
  FILE *tmpfile        = fopen(filename.c_str(), "w");

  bitwuzla_set_option(d_bzla, BITWUZLA_OPT_PRETTY_PRINT, 0);
  BitwuzlaSort *bv1   = bitwuzla_mk_bv_sort(d_bzla, 1);
  BitwuzlaSort *ar1_1 = bitwuzla_mk_array_sort(d_bzla, bv1, bv1);
  BitwuzlaTerm *a     = bitwuzla_mk_const(d_bzla, ar1_1, "a");
  BitwuzlaTerm *b     = bitwuzla_mk_const(d_bzla, ar1_1, "b");
  BitwuzlaTerm *z     = bitwuzla_mk_false(d_bzla);
  BitwuzlaTerm *e = bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_ARRAY_SELECT, a, z);
  BitwuzlaTerm *c = bitwuzla_mk_term2(d_bzla, BITWUZLA_KIND_EQUAL, a, b);
  bitwuzla_assert(d_bzla, e);
  bitwuzla_assert(d_bzla, c);
  bitwuzla_dump_formula(d_bzla, "smt2", tmpfile);
  fclose(tmpfile);

  std::ifstream ifs(filename);
  std::string content((std::istreambuf_iterator<char>(ifs)),
                      (std::istreambuf_iterator<char>()));
  unlink(filename.c_str());

  ASSERT_EQ(
      "(set-logic QF_ABV)\n"
      "(declare-const a (Array (_ BitVec 1) (_ BitVec 1)))\n"
      "(declare-const b (Array (_ BitVec 1) (_ BitVec 1)))\n"
      "(assert (= (select a #b0) #b1))\n"
      "(assert (= a b))\n"
      "(check-sat)\n"
      "(exit)\n",
      content);
}

TEST_F(TestApi, arrayfun)
{
  BitwuzlaSort *bvsort = bitwuzla_mk_bv_sort(d_bzla, 4);
  std::vector<BitwuzlaSort *> domain({bvsort});
  BitwuzlaSort *funsort =
      bitwuzla_mk_fun_sort(d_bzla, domain.size(), domain.data(), bvsort);
  BitwuzlaSort *arrsort = bitwuzla_mk_array_sort(d_bzla, bvsort, bvsort);
  BitwuzlaTerm *f       = bitwuzla_mk_const(d_bzla, funsort, "f");
  BitwuzlaTerm *a       = bitwuzla_mk_const(d_bzla, arrsort, "a");
  ASSERT_TRUE(bitwuzla_term_get_sort(f) != bitwuzla_term_get_sort(a));
  ASSERT_TRUE(bitwuzla_term_is_fun(f));
  ASSERT_TRUE(!bitwuzla_term_is_fun(a));
  ASSERT_TRUE(!bitwuzla_term_is_array(f));
  ASSERT_TRUE(bitwuzla_term_is_array(a));
}
