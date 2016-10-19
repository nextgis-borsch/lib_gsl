#define brown3_N         3
#define brown3_P         2

static double brown3_x0[brown3_P] = { 1.0, 1.0 };
static double brown3_epsrel = 1.0e-12;

static double brown3_J[brown3_N * brown3_P];

static void
brown3_checksol(const double x[], const double sumsq,
                const double epsrel, const char *sname,
                const char *pname)
{
  size_t i;
  const double sumsq_exact = 0.0;
  const double brown3_x[brown3_P] = { 1.0e6, 2.0e-6 };

  gsl_test_rel(sumsq, sumsq_exact, epsrel, "%s/%s sumsq",
               sname, pname);

  for (i = 0; i < brown3_P; ++i)
    {
      gsl_test_rel(x[i], brown3_x[i], epsrel, "%s/%s i="F_ZU,
                   sname, pname, i);
    }
}

static int
brown3_f (const gsl_vector * x, void *params, gsl_vector * f)
{
  double x1 = gsl_vector_get(x, 0);
  double x2 = gsl_vector_get(x, 1);

  gsl_vector_set(f, 0, x1 - 1.0e6);
  gsl_vector_set(f, 1, x2 - 2.0e-6);
  gsl_vector_set(f, 2, x1*x2 - 2.0);

  (void)params; /* avoid unused parameter warning */

  return GSL_SUCCESS;
}

static int
brown3_df (CBLAS_TRANSPOSE_t TransJ, const gsl_vector * x,
           const gsl_vector * u, void * params, gsl_vector * v,
           gsl_matrix * JTJ)
{
  gsl_matrix_view J = gsl_matrix_view_array(brown3_J, brown3_N, brown3_P);
  double x1 = gsl_vector_get(x, 0);
  double x2 = gsl_vector_get(x, 1);

  gsl_matrix_set_zero(&J.matrix);

  gsl_matrix_set(&J.matrix, 0, 0, 1.0);
  gsl_matrix_set(&J.matrix, 1, 1, 1.0);
  gsl_matrix_set(&J.matrix, 2, 0, x2);
  gsl_matrix_set(&J.matrix, 2, 1, x1);

  if (v)
    gsl_blas_dgemv(TransJ, 1.0, &J.matrix, u, 0.0, v);

  if (JTJ)
    gsl_blas_dsyrk(CblasLower, CblasTrans, 1.0, &J.matrix, 0.0, JTJ);

  (void)params; /* avoid unused parameter warning */

  return GSL_SUCCESS;
}

static int
brown3_fvv (const gsl_vector * x, const gsl_vector * v,
            void *params, gsl_vector * fvv)
{
  double v1 = gsl_vector_get(v, 0);
  double v2 = gsl_vector_get(v, 1);

  gsl_vector_set(fvv, 0, 0.0);
  gsl_vector_set(fvv, 1, 0.0);
  gsl_vector_set(fvv, 2, 2.0 * v1 * v2);

  (void)x;      /* avoid unused parameter warning */
  (void)params; /* avoid unused parameter warning */

  return GSL_SUCCESS;
}

static gsl_multilarge_nlinear_fdf brown3_func =
{
  brown3_f,
  brown3_df,
  brown3_fvv,
  brown3_N,
  brown3_P,
  NULL,
  0,
  0,
  0,
  0
};

static test_fdf_problem brown3_problem =
{
  "brown_badly_scaled",
  brown3_x0,
  NULL,
  &brown3_epsrel,
  &brown3_checksol,
  &brown3_func
};
