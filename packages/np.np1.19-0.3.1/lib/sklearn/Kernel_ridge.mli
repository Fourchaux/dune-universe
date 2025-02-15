(** Get an attribute of this module as a Py.Object.t.
                   This is useful to pass a Python function to another function. *)
val get_py : string -> Py.Object.t

module KernelRidge : sig
type tag = [`KernelRidge]
type t = [`BaseEstimator | `KernelRidge | `MultiOutputMixin | `Object | `RegressorMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_estimator : t -> [`BaseEstimator] Obj.t
val as_regressor : t -> [`RegressorMixin] Obj.t
val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val create : ?alpha:[>`ArrayLike] Np.Obj.t -> ?kernel:[`S of string | `Callable of Py.Object.t] -> ?gamma:float -> ?degree:float -> ?coef0:float -> ?kernel_params:Dict.t -> unit -> t
(**
Kernel ridge regression.

Kernel ridge regression (KRR) combines ridge regression (linear least
squares with l2-norm regularization) with the kernel trick. It thus
learns a linear function in the space induced by the respective kernel and
the data. For non-linear kernels, this corresponds to a non-linear
function in the original space.

The form of the model learned by KRR is identical to support vector
regression (SVR). However, different loss functions are used: KRR uses
squared error loss while support vector regression uses epsilon-insensitive
loss, both combined with l2 regularization. In contrast to SVR, fitting a
KRR model can be done in closed-form and is typically faster for
medium-sized datasets. On the other hand, the learned model is non-sparse
and thus slower than SVR, which learns a sparse model for epsilon > 0, at
prediction-time.

This estimator has built-in support for multi-variate regression
(i.e., when y is a 2d-array of shape [n_samples, n_targets]).

Read more in the :ref:`User Guide <kernel_ridge>`.

Parameters
----------
alpha : float or array-like of shape (n_targets,)
    Regularization strength; must be a positive float. Regularization
    improves the conditioning of the problem and reduces the variance of
    the estimates. Larger values specify stronger regularization.
    Alpha corresponds to ``1 / (2C)`` in other linear models such as
    :class:`~sklearn.linear_model.LogisticRegression` or
    :class:`sklearn.svm.LinearSVC`. If an array is passed, penalties are
    assumed to be specific to the targets. Hence they must correspond in
    number. See :ref:`ridge_regression` for formula.

kernel : string or callable, default='linear'
    Kernel mapping used internally. This parameter is directly passed to
    :class:`sklearn.metrics.pairwise.pairwise_kernel`.
    If `kernel` is a string, it must be one of the metrics
    in `pairwise.PAIRWISE_KERNEL_FUNCTIONS`.
    If `kernel` is 'precomputed', X is assumed to be a kernel matrix.
    Alternatively, if `kernel` is a callable function, it is called on
    each pair of instances (rows) and the resulting value recorded. The
    callable should take two rows from X as input and return the
    corresponding kernel value as a single number. This means that
    callables from :mod:`sklearn.metrics.pairwise` are not allowed, as
    they operate on matrices, not single samples. Use the string
    identifying the kernel instead.

gamma : float, default=None
    Gamma parameter for the RBF, laplacian, polynomial, exponential chi2
    and sigmoid kernels. Interpretation of the default value is left to
    the kernel; see the documentation for sklearn.metrics.pairwise.
    Ignored by other kernels.

degree : float, default=3
    Degree of the polynomial kernel. Ignored by other kernels.

coef0 : float, default=1
    Zero coefficient for polynomial and sigmoid kernels.
    Ignored by other kernels.

kernel_params : mapping of string to any, optional
    Additional parameters (keyword arguments) for kernel function passed
    as callable object.

Attributes
----------
dual_coef_ : ndarray of shape (n_samples,) or (n_samples, n_targets)
    Representation of weight vector(s) in kernel space

X_fit_ : {ndarray, sparse matrix} of shape (n_samples, n_features)
    Training data, which is also required for prediction. If
    kernel == 'precomputed' this is instead the precomputed
    training matrix, of shape (n_samples, n_samples).

References
----------
* Kevin P. Murphy
  'Machine Learning: A Probabilistic Perspective', The MIT Press
  chapter 14.4.3, pp. 492-493

See also
--------
sklearn.linear_model.Ridge:
    Linear ridge regression.
sklearn.svm.SVR:
    Support Vector Regression implemented using libsvm.

Examples
--------
>>> from sklearn.kernel_ridge import KernelRidge
>>> import numpy as np
>>> n_samples, n_features = 10, 5
>>> rng = np.random.RandomState(0)
>>> y = rng.randn(n_samples)
>>> X = rng.randn(n_samples, n_features)
>>> clf = KernelRidge(alpha=1.0)
>>> clf.fit(X, y)
KernelRidge(alpha=1.0)
*)

val fit : ?y:[>`ArrayLike] Np.Obj.t -> ?sample_weight:[>`ArrayLike] Np.Obj.t -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit Kernel Ridge regression model

Parameters
----------
X : {array-like, sparse matrix} of shape (n_samples, n_features)
    Training data. If kernel == 'precomputed' this is instead
    a precomputed kernel matrix, of shape (n_samples, n_samples).

y : array-like of shape (n_samples,) or (n_samples, n_targets)
    Target values

sample_weight : float or array-like of shape [n_samples]
    Individual weights for each sample, ignored if None is passed.

Returns
-------
self : returns an instance of self.
*)

val get_params : ?deep:bool -> [> tag] Obj.t -> Dict.t
(**
Get parameters for this estimator.

Parameters
----------
deep : bool, default=True
    If True, will return the parameters for this estimator and
    contained subobjects that are estimators.

Returns
-------
params : mapping of string to any
    Parameter names mapped to their values.
*)

val predict : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Predict using the kernel ridge model

Parameters
----------
X : {array-like, sparse matrix} of shape (n_samples, n_features)
    Samples. If kernel == 'precomputed' this is instead a
    precomputed kernel matrix, shape = [n_samples,
    n_samples_fitted], where n_samples_fitted is the number of
    samples used in the fitting for this estimator.

Returns
-------
C : ndarray of shape (n_samples,) or (n_samples, n_targets)
    Returns predicted values.
*)

val score : ?sample_weight:[>`ArrayLike] Np.Obj.t -> x:[>`ArrayLike] Np.Obj.t -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> float
(**
Return the coefficient of determination R^2 of the prediction.

The coefficient R^2 is defined as (1 - u/v), where u is the residual
sum of squares ((y_true - y_pred) ** 2).sum() and v is the total
sum of squares ((y_true - y_true.mean()) ** 2).sum().
The best possible score is 1.0 and it can be negative (because the
model can be arbitrarily worse). A constant model that always
predicts the expected value of y, disregarding the input features,
would get a R^2 score of 0.0.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Test samples. For some estimators this may be a
    precomputed kernel matrix or a list of generic objects instead,
    shape = (n_samples, n_samples_fitted),
    where n_samples_fitted is the number of
    samples used in the fitting for the estimator.

y : array-like of shape (n_samples,) or (n_samples, n_outputs)
    True values for X.

sample_weight : array-like of shape (n_samples,), default=None
    Sample weights.

Returns
-------
score : float
    R^2 of self.predict(X) wrt. y.

Notes
-----
The R2 score used when calling ``score`` on a regressor uses
``multioutput='uniform_average'`` from version 0.23 to keep consistent
with default value of :func:`~sklearn.metrics.r2_score`.
This influences the ``score`` method of all the multioutput
regressors (except for
:class:`~sklearn.multioutput.MultiOutputRegressor`).
*)

val set_params : ?params:(string * Py.Object.t) list -> [> tag] Obj.t -> t
(**
Set the parameters of this estimator.

The method works on simple estimators as well as on nested objects
(such as pipelines). The latter have parameters of the form
``<component>__<parameter>`` so that it's possible to update each
component of a nested object.

Parameters
----------
**params : dict
    Estimator parameters.

Returns
-------
self : object
    Estimator instance.
*)


(** Attribute dual_coef_: get value or raise Not_found if None.*)
val dual_coef_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute dual_coef_: get value as an option. *)
val dual_coef_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Attribute X_fit_: get value or raise Not_found if None.*)
val x_fit_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute X_fit_: get value as an option. *)
val x_fit_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

val check_is_fitted : ?attributes:[`S of string | `StringList of string list | `Arr of [>`ArrayLike] Np.Obj.t] -> ?msg:string -> ?all_or_any:[`Callable of Py.Object.t | `PyObject of Py.Object.t] -> estimator:[>`BaseEstimator] Np.Obj.t -> unit -> Py.Object.t
(**
Perform is_fitted validation for estimator.

Checks if the estimator is fitted by verifying the presence of
fitted attributes (ending with a trailing underscore) and otherwise
raises a NotFittedError with the given message.

This utility is meant to be used internally by estimators themselves,
typically in their own predict / transform methods.

Parameters
----------
estimator : estimator instance.
    estimator instance for which the check is performed.

attributes : str, list or tuple of str, default=None
    Attribute name(s) given as string or a list/tuple of strings
    Eg.: ``['coef_', 'estimator_', ...], 'coef_'``

    If `None`, `estimator` is considered fitted if there exist an
    attribute that ends with a underscore and does not start with double
    underscore.

msg : string
    The default error message is, 'This %(name)s instance is not fitted
    yet. Call 'fit' with appropriate arguments before using this
    estimator.'

    For custom messages if '%(name)s' is present in the message string,
    it is substituted for the estimator name.

    Eg. : 'Estimator, %(name)s, must be fitted before sparsifying'.

all_or_any : callable, {all, any}, default all
    Specify whether all or any of the given attributes must exist.

Returns
-------
None

Raises
------
NotFittedError
    If the attributes are not found.
*)

val pairwise_kernels : ?y:[>`ArrayLike] Np.Obj.t -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?filter_params:bool -> ?n_jobs:int -> ?kwds:(string * Py.Object.t) list -> x:[`Otherwise of Py.Object.t | `Arr of [>`ArrayLike] Np.Obj.t] -> unit -> [>`ArrayLike] Np.Obj.t
(**
Compute the kernel between arrays X and optional array Y.

This method takes either a vector array or a kernel matrix, and returns
a kernel matrix. If the input is a vector array, the kernels are
computed. If the input is a kernel matrix, it is returned instead.

This method provides a safe way to take a kernel matrix as input, while
preserving compatibility with many other algorithms that take a vector
array.

If Y is given (default is None), then the returned matrix is the pairwise
kernel between the arrays from both X and Y.

Valid values for metric are:
    ['additive_chi2', 'chi2', 'linear', 'poly', 'polynomial', 'rbf',
    'laplacian', 'sigmoid', 'cosine']

Read more in the :ref:`User Guide <metrics>`.

Parameters
----------
X : array [n_samples_a, n_samples_a] if metric == 'precomputed', or,              [n_samples_a, n_features] otherwise
    Array of pairwise kernels between samples, or a feature array.

Y : array [n_samples_b, n_features]
    A second feature array only if X has shape [n_samples_a, n_features].

metric : string, or callable
    The metric to use when calculating kernel between instances in a
    feature array. If metric is a string, it must be one of the metrics
    in pairwise.PAIRWISE_KERNEL_FUNCTIONS.
    If metric is 'precomputed', X is assumed to be a kernel matrix.
    Alternatively, if metric is a callable function, it is called on each
    pair of instances (rows) and the resulting value recorded. The callable
    should take two rows from X as input and return the corresponding
    kernel value as a single number. This means that callables from
    :mod:`sklearn.metrics.pairwise` are not allowed, as they operate on
    matrices, not single samples. Use the string identifying the kernel
    instead.

filter_params : boolean
    Whether to filter invalid parameters or not.

n_jobs : int or None, optional (default=None)
    The number of jobs to use for the computation. This works by breaking
    down the pairwise matrix into n_jobs even slices and computing them in
    parallel.

    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

**kwds : optional keyword parameters
    Any further parameters are passed directly to the kernel function.

Returns
-------
K : array [n_samples_a, n_samples_a] or [n_samples_a, n_samples_b]
    A kernel matrix K such that K_{i, j} is the kernel between the
    ith and jth vectors of the given matrix X, if Y is None.
    If Y is not None, then K_{i, j} is the kernel between the ith array
    from X and the jth array from Y.

Notes
-----
If metric is 'precomputed', Y is ignored and X is returned.
*)

