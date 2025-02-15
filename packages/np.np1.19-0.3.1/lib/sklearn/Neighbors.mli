(** Get an attribute of this module as a Py.Object.t.
                   This is useful to pass a Python function to another function. *)
val get_py : string -> Py.Object.t

module BallTree : sig
type tag = [`BallTree]
type t = [`BallTree | `Object] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val create : ?leaf_size:Py.Object.t -> ?metric:[`S of string | `DistanceMetric_object of Py.Object.t] -> ?kwargs:(string * Py.Object.t) list -> x:[>`ArrayLike] Np.Obj.t -> unit -> t
(**
BallTree(X, leaf_size=40, metric='minkowski', **kwargs)

BallTree for fast generalized N-point problems

Parameters
----------
X : array-like of shape (n_samples, n_features)
    n_samples is the number of points in the data set, and
    n_features is the dimension of the parameter space.
    Note: if X is a C-contiguous array of doubles then data will
    not be copied. Otherwise, an internal copy will be made.

leaf_size : positive int, default=40
    Number of points at which to switch to brute-force. Changing
    leaf_size will not affect the results of a query, but can
    significantly impact the speed of a query and the memory required
    to store the constructed tree.  The amount of memory needed to
    store the tree scales as approximately n_samples / leaf_size.
    For a specified ``leaf_size``, a leaf node is guaranteed to
    satisfy ``leaf_size <= n_points <= 2 * leaf_size``, except in
    the case that ``n_samples < leaf_size``.

metric : str or DistanceMetric object
    the distance metric to use for the tree.  Default='minkowski'
    with p=2 (that is, a euclidean metric). See the documentation
    of the DistanceMetric class for a list of available metrics.
    ball_tree.valid_metrics gives a list of the metrics which
    are valid for BallTree.

Additional keywords are passed to the distance metric class.
Note: Callable functions in the metric parameter are NOT supported for KDTree
and Ball Tree. Function call overhead will result in very poor performance.

Attributes
----------
data : memory view
    The training data

Examples
--------
Query for k-nearest neighbors

    >>> import numpy as np
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((10, 3))  # 10 points in 3 dimensions
    >>> tree = BallTree(X, leaf_size=2)              # doctest: +SKIP
    >>> dist, ind = tree.query(X[:1], k=3)                # doctest: +SKIP
    >>> print(ind)  # indices of 3 closest neighbors
    [0 3 1]
    >>> print(dist)  # distances to 3 closest neighbors
    [ 0.          0.19662693  0.29473397]

Pickle and Unpickle a tree.  Note that the state of the tree is saved in the
pickle operation: the tree needs not be rebuilt upon unpickling.

    >>> import numpy as np
    >>> import pickle
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((10, 3))  # 10 points in 3 dimensions
    >>> tree = BallTree(X, leaf_size=2)        # doctest: +SKIP
    >>> s = pickle.dumps(tree)                     # doctest: +SKIP
    >>> tree_copy = pickle.loads(s)                # doctest: +SKIP
    >>> dist, ind = tree_copy.query(X[:1], k=3)     # doctest: +SKIP
    >>> print(ind)  # indices of 3 closest neighbors
    [0 3 1]
    >>> print(dist)  # distances to 3 closest neighbors
    [ 0.          0.19662693  0.29473397]

Query for neighbors within a given radius

    >>> import numpy as np
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((10, 3))  # 10 points in 3 dimensions
    >>> tree = BallTree(X, leaf_size=2)     # doctest: +SKIP
    >>> print(tree.query_radius(X[:1], r=0.3, count_only=True))
    3
    >>> ind = tree.query_radius(X[:1], r=0.3)  # doctest: +SKIP
    >>> print(ind)  # indices of neighbors within distance 0.3
    [3 0 1]


Compute a gaussian kernel density estimate:

    >>> import numpy as np
    >>> rng = np.random.RandomState(42)
    >>> X = rng.random_sample((100, 3))
    >>> tree = BallTree(X)                # doctest: +SKIP
    >>> tree.kernel_density(X[:3], h=0.1, kernel='gaussian')
    array([ 6.94114649,  7.83281226,  7.2071716 ])

Compute a two-point auto-correlation function

    >>> import numpy as np
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((30, 3))
    >>> r = np.linspace(0, 1, 5)
    >>> tree = BallTree(X)                # doctest: +SKIP
    >>> tree.two_point_correlation(X, r)
    array([ 30,  62, 278, 580, 820])
*)

val get_arrays : [> tag] Obj.t -> Py.Object.t
(**
get_arrays(self)

Get data and node arrays.

Returns
-------
arrays: tuple of array
    Arrays for storing tree data, index, node data and node bounds.
*)

val get_n_calls : [> tag] Obj.t -> int
(**
get_n_calls(self)

Get number of calls.

Returns
-------
n_calls: int
    number of distance computation calls
*)

val get_tree_stats : [> tag] Obj.t -> Py.Object.t
(**
get_tree_stats(self)

Get tree status.

Returns
-------
tree_stats: tuple of int
    (number of trims, number of leaves, number of splits)
*)

val kernel_density : ?kernel:string -> ?atol:Py.Object.t -> ?rtol:Py.Object.t -> ?breadth_first:bool -> ?return_log:bool -> x:[>`ArrayLike] Np.Obj.t -> h:float -> [> tag] Obj.t -> Py.Object.t
(**
kernel_density(self, X, h, kernel='gaussian', atol=0, rtol=1E-8,
               breadth_first=True, return_log=False)

Compute the kernel density estimate at points X with the given kernel,
using the distance metric specified at tree creation.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    An array of points to query.  Last dimension should match dimension
    of training data.
h : float
    the bandwidth of the kernel
kernel : str, default='gaussian'
    specify the kernel to use.  Options are
    - 'gaussian'
    - 'tophat'
    - 'epanechnikov'
    - 'exponential'
    - 'linear'
    - 'cosine'
    Default is kernel = 'gaussian'
atol, rtol : float, default=0, 1e-8
    Specify the desired relative and absolute tolerance of the result.
    If the true result is K_true, then the returned result K_ret
    satisfies ``abs(K_true - K_ret) < atol + rtol * K_ret``
    The default is zero (i.e. machine precision) for both.
breadth_first : bool, default=False
    If True, use a breadth-first search.  If False (default) use a
    depth-first search.  Breadth-first is generally faster for
    compact kernels and/or high tolerances.
return_log : bool, default=False
    Return the logarithm of the result.  This can be more accurate
    than returning the result itself for narrow kernels.

Returns
-------
density : ndarray of shape X.shape[:-1]
    The array of (log)-density evaluations
*)

val reset_n_calls : [> tag] Obj.t -> Py.Object.t
(**
reset_n_calls(self)

Reset number of calls to 0.
*)


(** Attribute data: get value or raise Not_found if None.*)
val data : t -> Py.Object.t

(** Attribute data: get value as an option. *)
val data_opt : t -> (Py.Object.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module DistanceMetric : sig
type tag = [`DistanceMetric]
type t = [`DistanceMetric | `Object] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module KDTree : sig
type tag = [`KDTree]
type t = [`KDTree | `Object] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val create : ?leaf_size:Py.Object.t -> ?metric:[`S of string | `DistanceMetric_object of Py.Object.t] -> ?kwargs:(string * Py.Object.t) list -> x:[>`ArrayLike] Np.Obj.t -> unit -> t
(**
KDTree(X, leaf_size=40, metric='minkowski', **kwargs)

KDTree for fast generalized N-point problems

Parameters
----------
X : array-like of shape (n_samples, n_features)
    n_samples is the number of points in the data set, and
    n_features is the dimension of the parameter space.
    Note: if X is a C-contiguous array of doubles then data will
    not be copied. Otherwise, an internal copy will be made.

leaf_size : positive int, default=40
    Number of points at which to switch to brute-force. Changing
    leaf_size will not affect the results of a query, but can
    significantly impact the speed of a query and the memory required
    to store the constructed tree.  The amount of memory needed to
    store the tree scales as approximately n_samples / leaf_size.
    For a specified ``leaf_size``, a leaf node is guaranteed to
    satisfy ``leaf_size <= n_points <= 2 * leaf_size``, except in
    the case that ``n_samples < leaf_size``.

metric : str or DistanceMetric object
    the distance metric to use for the tree.  Default='minkowski'
    with p=2 (that is, a euclidean metric). See the documentation
    of the DistanceMetric class for a list of available metrics.
    kd_tree.valid_metrics gives a list of the metrics which
    are valid for KDTree.

Additional keywords are passed to the distance metric class.
Note: Callable functions in the metric parameter are NOT supported for KDTree
and Ball Tree. Function call overhead will result in very poor performance.

Attributes
----------
data : memory view
    The training data

Examples
--------
Query for k-nearest neighbors

    >>> import numpy as np
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((10, 3))  # 10 points in 3 dimensions
    >>> tree = KDTree(X, leaf_size=2)              # doctest: +SKIP
    >>> dist, ind = tree.query(X[:1], k=3)                # doctest: +SKIP
    >>> print(ind)  # indices of 3 closest neighbors
    [0 3 1]
    >>> print(dist)  # distances to 3 closest neighbors
    [ 0.          0.19662693  0.29473397]

Pickle and Unpickle a tree.  Note that the state of the tree is saved in the
pickle operation: the tree needs not be rebuilt upon unpickling.

    >>> import numpy as np
    >>> import pickle
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((10, 3))  # 10 points in 3 dimensions
    >>> tree = KDTree(X, leaf_size=2)        # doctest: +SKIP
    >>> s = pickle.dumps(tree)                     # doctest: +SKIP
    >>> tree_copy = pickle.loads(s)                # doctest: +SKIP
    >>> dist, ind = tree_copy.query(X[:1], k=3)     # doctest: +SKIP
    >>> print(ind)  # indices of 3 closest neighbors
    [0 3 1]
    >>> print(dist)  # distances to 3 closest neighbors
    [ 0.          0.19662693  0.29473397]

Query for neighbors within a given radius

    >>> import numpy as np
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((10, 3))  # 10 points in 3 dimensions
    >>> tree = KDTree(X, leaf_size=2)     # doctest: +SKIP
    >>> print(tree.query_radius(X[:1], r=0.3, count_only=True))
    3
    >>> ind = tree.query_radius(X[:1], r=0.3)  # doctest: +SKIP
    >>> print(ind)  # indices of neighbors within distance 0.3
    [3 0 1]


Compute a gaussian kernel density estimate:

    >>> import numpy as np
    >>> rng = np.random.RandomState(42)
    >>> X = rng.random_sample((100, 3))
    >>> tree = KDTree(X)                # doctest: +SKIP
    >>> tree.kernel_density(X[:3], h=0.1, kernel='gaussian')
    array([ 6.94114649,  7.83281226,  7.2071716 ])

Compute a two-point auto-correlation function

    >>> import numpy as np
    >>> rng = np.random.RandomState(0)
    >>> X = rng.random_sample((30, 3))
    >>> r = np.linspace(0, 1, 5)
    >>> tree = KDTree(X)                # doctest: +SKIP
    >>> tree.two_point_correlation(X, r)
    array([ 30,  62, 278, 580, 820])
*)

val get_arrays : [> tag] Obj.t -> Py.Object.t
(**
get_arrays(self)

Get data and node arrays.

Returns
-------
arrays: tuple of array
    Arrays for storing tree data, index, node data and node bounds.
*)

val get_n_calls : [> tag] Obj.t -> int
(**
get_n_calls(self)

Get number of calls.

Returns
-------
n_calls: int
    number of distance computation calls
*)

val get_tree_stats : [> tag] Obj.t -> Py.Object.t
(**
get_tree_stats(self)

Get tree status.

Returns
-------
tree_stats: tuple of int
    (number of trims, number of leaves, number of splits)
*)

val kernel_density : ?kernel:string -> ?atol:Py.Object.t -> ?rtol:Py.Object.t -> ?breadth_first:bool -> ?return_log:bool -> x:[>`ArrayLike] Np.Obj.t -> h:float -> [> tag] Obj.t -> Py.Object.t
(**
kernel_density(self, X, h, kernel='gaussian', atol=0, rtol=1E-8,
               breadth_first=True, return_log=False)

Compute the kernel density estimate at points X with the given kernel,
using the distance metric specified at tree creation.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    An array of points to query.  Last dimension should match dimension
    of training data.
h : float
    the bandwidth of the kernel
kernel : str, default='gaussian'
    specify the kernel to use.  Options are
    - 'gaussian'
    - 'tophat'
    - 'epanechnikov'
    - 'exponential'
    - 'linear'
    - 'cosine'
    Default is kernel = 'gaussian'
atol, rtol : float, default=0, 1e-8
    Specify the desired relative and absolute tolerance of the result.
    If the true result is K_true, then the returned result K_ret
    satisfies ``abs(K_true - K_ret) < atol + rtol * K_ret``
    The default is zero (i.e. machine precision) for both.
breadth_first : bool, default=False
    If True, use a breadth-first search.  If False (default) use a
    depth-first search.  Breadth-first is generally faster for
    compact kernels and/or high tolerances.
return_log : bool, default=False
    Return the logarithm of the result.  This can be more accurate
    than returning the result itself for narrow kernels.

Returns
-------
density : ndarray of shape X.shape[:-1]
    The array of (log)-density evaluations
*)

val reset_n_calls : [> tag] Obj.t -> Py.Object.t
(**
reset_n_calls(self)

Reset number of calls to 0.
*)


(** Attribute data: get value or raise Not_found if None.*)
val data : t -> Py.Object.t

(** Attribute data: get value as an option. *)
val data_opt : t -> (Py.Object.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module KNeighborsClassifier : sig
type tag = [`KNeighborsClassifier]
type t = [`BaseEstimator | `ClassifierMixin | `KNeighborsClassifier | `KNeighborsMixin | `MultiOutputMixin | `NeighborsBase | `Object | `SupervisedIntegerMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_k_neighbors : t -> [`KNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val as_classifier : t -> [`ClassifierMixin] Obj.t
val as_supervised_integer : t -> [`SupervisedIntegerMixin] Obj.t
val create : ?n_neighbors:int -> ?weights:[`Uniform | `Callable of Py.Object.t | `Distance] -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?p:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?metric_params:Dict.t -> ?n_jobs:int -> ?kwargs:(string * Py.Object.t) list -> unit -> t
(**
Classifier implementing the k-nearest neighbors vote.

Read more in the :ref:`User Guide <classification>`.

Parameters
----------
n_neighbors : int, default=5
    Number of neighbors to use by default for :meth:`kneighbors` queries.

weights : {'uniform', 'distance'} or callable, default='uniform'
    weight function used in prediction.  Possible values:

    - 'uniform' : uniform weights.  All points in each neighborhood
      are weighted equally.
    - 'distance' : weight points by the inverse of their distance.
      in this case, closer neighbors of a query point will have a
      greater influence than neighbors which are further away.
    - [callable] : a user-defined function which accepts an
      array of distances, and returns an array of the same shape
      containing the weights.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

p : int, default=2
    Power parameter for the Minkowski metric. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric : str or callable, default='minkowski'
    the distance metric to use for the tree.  The default metric is
    minkowski, and with p=2 is equivalent to the standard Euclidean
    metric. See the documentation of :class:`DistanceMetric` for a
    list of available metrics.
    If metric is 'precomputed', X is assumed to be a distance matrix and
    must be square during fit. X may be a :term:`sparse graph`,
    in which case only 'nonzero' elements may be considered neighbors.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.
    Doesn't affect :meth:`fit` method.

Attributes
----------
classes_ : array of shape (n_classes,)
    Class labels known to the classifier

effective_metric_ : str or callble
    The distance metric used. It will be same as the `metric` parameter
    or a synonym of it, e.g. 'euclidean' if the `metric` parameter set to
    'minkowski' and `p` parameter set to 2.

effective_metric_params_ : dict
    Additional keyword arguments for the metric function. For most metrics
    will be same with `metric_params` parameter, but may also contain the
    `p` parameter value if the `effective_metric_` attribute is set to
    'minkowski'.

outputs_2d_ : bool
    False when `y`'s shape is (n_samples, ) or (n_samples, 1) during fit
    otherwise True.

Examples
--------
>>> X = [[0], [1], [2], [3]]
>>> y = [0, 0, 1, 1]
>>> from sklearn.neighbors import KNeighborsClassifier
>>> neigh = KNeighborsClassifier(n_neighbors=3)
>>> neigh.fit(X, y)
KNeighborsClassifier(...)
>>> print(neigh.predict([[1.1]]))
[0]
>>> print(neigh.predict_proba([[0.9]]))
[[0.66666667 0.33333333]]

See also
--------
RadiusNeighborsClassifier
KNeighborsRegressor
RadiusNeighborsRegressor
NearestNeighbors

Notes
-----
See :ref:`Nearest Neighbors <neighbors>` in the online documentation
for a discussion of the choice of ``algorithm`` and ``leaf_size``.

.. warning::

   Regarding the Nearest Neighbors algorithms, if it is found that two
   neighbors, neighbor `k+1` and `k`, have identical distances
   but different labels, the results will depend on the ordering of the
   training data.

https://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm
*)

val fit : x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the model using X as training data and y as target values

Parameters
----------
X : {array-like, sparse matrix, BallTree, KDTree}
    Training data. If array or matrix, shape [n_samples, n_features],
    or [n_samples, n_samples] if metric='precomputed'.

y : {array-like, sparse matrix}
    Target values of shape = [n_samples] or [n_samples, n_outputs]
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

val kneighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> [> tag] Obj.t -> ([>`ArrayLike] Np.Obj.t * [>`ArrayLike] Np.Obj.t)
(**
Finds the K-neighbors of a point.
Returns indices of and distances to the neighbors of each point.

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors to get (default is the value
    passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned

Returns
-------
neigh_dist : array, shape (n_queries, n_neighbors)
    Array representing the lengths to points, only present if
    return_distance=True

neigh_ind : array, shape (n_queries, n_neighbors)
    Indices of the nearest points in the population matrix.

Examples
--------
In the following example, we construct a NearestNeighbors
class from an array representing our data set and ask who's
the closest point to [1,1,1]

>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=1)
>>> neigh.fit(samples)
NearestNeighbors(n_neighbors=1)
>>> print(neigh.kneighbors([[1., 1., 1.]]))
(array([[0.5]]), array([[2]]))

As you can see, it returns [[0.5]], and [[2]], which means that the
element is at distance 0.5 and is the third element of samples
(indexes start at 0). You can also query for multiple points:

>>> X = [[0., 1., 0.], [1., 0., 1.]]
>>> neigh.kneighbors(X, return_distance=False)
array([[1],
       [2]]...)
*)

val kneighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> ?mode:[`Connectivity | `Distance] -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of k-Neighbors for points in X

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors for each sample.
    (default is value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=2)
>>> neigh.fit(X)
NearestNeighbors(n_neighbors=2)
>>> A = neigh.kneighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 1.],
       [1., 0., 1.]])

See also
--------
NearestNeighbors.radius_neighbors_graph
*)

val predict : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Predict the class labels for the provided data.

Parameters
----------
X : array-like of shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    Test samples.

Returns
-------
y : ndarray of shape (n_queries,) or (n_queries, n_outputs)
    Class labels for each data sample.
*)

val predict_proba : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Return probability estimates for the test data X.

Parameters
----------
X : array-like of shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    Test samples.

Returns
-------
p : ndarray of shape (n_queries, n_classes), or a list of n_outputs
    of such arrays if n_outputs > 1.
    The class probabilities of the input samples. Classes are ordered
    by lexicographic order.
*)

val score : ?sample_weight:[>`ArrayLike] Np.Obj.t -> x:[>`ArrayLike] Np.Obj.t -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> float
(**
Return the mean accuracy on the given test data and labels.

In multi-label classification, this is the subset accuracy
which is a harsh metric since you require for each sample that
each label set be correctly predicted.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Test samples.

y : array-like of shape (n_samples,) or (n_samples, n_outputs)
    True labels for X.

sample_weight : array-like of shape (n_samples,), default=None
    Sample weights.

Returns
-------
score : float
    Mean accuracy of self.predict(X) wrt. y.
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


(** Attribute classes_: get value or raise Not_found if None.*)
val classes_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute classes_: get value as an option. *)
val classes_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Attribute effective_metric_: get value or raise Not_found if None.*)
val effective_metric_ : t -> Py.Object.t

(** Attribute effective_metric_: get value as an option. *)
val effective_metric_opt : t -> (Py.Object.t) option


(** Attribute effective_metric_params_: get value or raise Not_found if None.*)
val effective_metric_params_ : t -> Dict.t

(** Attribute effective_metric_params_: get value as an option. *)
val effective_metric_params_opt : t -> (Dict.t) option


(** Attribute outputs_2d_: get value or raise Not_found if None.*)
val outputs_2d_ : t -> bool

(** Attribute outputs_2d_: get value as an option. *)
val outputs_2d_opt : t -> (bool) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module KNeighborsRegressor : sig
type tag = [`KNeighborsRegressor]
type t = [`BaseEstimator | `KNeighborsMixin | `KNeighborsRegressor | `MultiOutputMixin | `NeighborsBase | `Object | `RegressorMixin | `SupervisedFloatMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_supervised_float : t -> [`SupervisedFloatMixin] Obj.t
val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_regressor : t -> [`RegressorMixin] Obj.t
val as_k_neighbors : t -> [`KNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val create : ?n_neighbors:int -> ?weights:[`Uniform | `Callable of Py.Object.t | `Distance] -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?p:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?metric_params:Dict.t -> ?n_jobs:int -> ?kwargs:(string * Py.Object.t) list -> unit -> t
(**
Regression based on k-nearest neighbors.

The target is predicted by local interpolation of the targets
associated of the nearest neighbors in the training set.

Read more in the :ref:`User Guide <regression>`.

.. versionadded:: 0.9

Parameters
----------
n_neighbors : int, default=5
    Number of neighbors to use by default for :meth:`kneighbors` queries.

weights : {'uniform', 'distance'} or callable, default='uniform'
    weight function used in prediction.  Possible values:

    - 'uniform' : uniform weights.  All points in each neighborhood
      are weighted equally.
    - 'distance' : weight points by the inverse of their distance.
      in this case, closer neighbors of a query point will have a
      greater influence than neighbors which are further away.
    - [callable] : a user-defined function which accepts an
      array of distances, and returns an array of the same shape
      containing the weights.

    Uniform weights are used by default.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

p : int, default=2
    Power parameter for the Minkowski metric. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric : str or callable, default='minkowski'
    the distance metric to use for the tree.  The default metric is
    minkowski, and with p=2 is equivalent to the standard Euclidean
    metric. See the documentation of :class:`DistanceMetric` for a
    list of available metrics.
    If metric is 'precomputed', X is assumed to be a distance matrix and
    must be square during fit. X may be a :term:`sparse graph`,
    in which case only 'nonzero' elements may be considered neighbors.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.
    Doesn't affect :meth:`fit` method.

Attributes
----------
effective_metric_ : str or callable
    The distance metric to use. It will be same as the `metric` parameter
    or a synonym of it, e.g. 'euclidean' if the `metric` parameter set to
    'minkowski' and `p` parameter set to 2.

effective_metric_params_ : dict
    Additional keyword arguments for the metric function. For most metrics
    will be same with `metric_params` parameter, but may also contain the
    `p` parameter value if the `effective_metric_` attribute is set to
    'minkowski'.

Examples
--------
>>> X = [[0], [1], [2], [3]]
>>> y = [0, 0, 1, 1]
>>> from sklearn.neighbors import KNeighborsRegressor
>>> neigh = KNeighborsRegressor(n_neighbors=2)
>>> neigh.fit(X, y)
KNeighborsRegressor(...)
>>> print(neigh.predict([[1.5]]))
[0.5]

See also
--------
NearestNeighbors
RadiusNeighborsRegressor
KNeighborsClassifier
RadiusNeighborsClassifier

Notes
-----
See :ref:`Nearest Neighbors <neighbors>` in the online documentation
for a discussion of the choice of ``algorithm`` and ``leaf_size``.

.. warning::

   Regarding the Nearest Neighbors algorithms, if it is found that two
   neighbors, neighbor `k+1` and `k`, have identical distances but
   different labels, the results will depend on the ordering of the
   training data.

https://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm
*)

val fit : x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the model using X as training data and y as target values

Parameters
----------
X : {array-like, sparse matrix, BallTree, KDTree}
    Training data. If array or matrix, shape [n_samples, n_features],
    or [n_samples, n_samples] if metric='precomputed'.

y : {array-like, sparse matrix}
    Target values, array of float values, shape = [n_samples]
     or [n_samples, n_outputs]
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

val kneighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> [> tag] Obj.t -> ([>`ArrayLike] Np.Obj.t * [>`ArrayLike] Np.Obj.t)
(**
Finds the K-neighbors of a point.
Returns indices of and distances to the neighbors of each point.

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors to get (default is the value
    passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned

Returns
-------
neigh_dist : array, shape (n_queries, n_neighbors)
    Array representing the lengths to points, only present if
    return_distance=True

neigh_ind : array, shape (n_queries, n_neighbors)
    Indices of the nearest points in the population matrix.

Examples
--------
In the following example, we construct a NearestNeighbors
class from an array representing our data set and ask who's
the closest point to [1,1,1]

>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=1)
>>> neigh.fit(samples)
NearestNeighbors(n_neighbors=1)
>>> print(neigh.kneighbors([[1., 1., 1.]]))
(array([[0.5]]), array([[2]]))

As you can see, it returns [[0.5]], and [[2]], which means that the
element is at distance 0.5 and is the third element of samples
(indexes start at 0). You can also query for multiple points:

>>> X = [[0., 1., 0.], [1., 0., 1.]]
>>> neigh.kneighbors(X, return_distance=False)
array([[1],
       [2]]...)
*)

val kneighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> ?mode:[`Connectivity | `Distance] -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of k-Neighbors for points in X

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors for each sample.
    (default is value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=2)
>>> neigh.fit(X)
NearestNeighbors(n_neighbors=2)
>>> A = neigh.kneighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 1.],
       [1., 0., 1.]])

See also
--------
NearestNeighbors.radius_neighbors_graph
*)

val predict : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Predict the target for the provided data

Parameters
----------
X : array-like of shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    Test samples.

Returns
-------
y : ndarray of shape (n_queries,) or (n_queries, n_outputs), dtype=int
    Target values.
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


(** Attribute effective_metric_: get value or raise Not_found if None.*)
val effective_metric_ : t -> Py.Object.t

(** Attribute effective_metric_: get value as an option. *)
val effective_metric_opt : t -> (Py.Object.t) option


(** Attribute effective_metric_params_: get value or raise Not_found if None.*)
val effective_metric_params_ : t -> Dict.t

(** Attribute effective_metric_params_: get value as an option. *)
val effective_metric_params_opt : t -> (Dict.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module KNeighborsTransformer : sig
type tag = [`KNeighborsTransformer]
type t = [`BaseEstimator | `KNeighborsMixin | `KNeighborsTransformer | `MultiOutputMixin | `NeighborsBase | `Object | `TransformerMixin | `UnsupervisedMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_k_neighbors : t -> [`KNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val as_transformer : t -> [`TransformerMixin] Obj.t
val as_unsupervised : t -> [`UnsupervisedMixin] Obj.t
val create : ?mode:[`Distance | `Connectivity] -> ?n_neighbors:int -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?p:int -> ?metric_params:Dict.t -> ?n_jobs:int -> unit -> t
(**
Transform X into a (weighted) graph of k nearest neighbors

The transformed data is a sparse graph as returned by kneighbors_graph.

Read more in the :ref:`User Guide <neighbors_transformer>`.

.. versionadded:: 0.22

Parameters
----------
mode : {'distance', 'connectivity'}, default='distance'
    Type of returned matrix: 'connectivity' will return the connectivity
    matrix with ones and zeros, and 'distance' will return the distances
    between neighbors according to the given metric.

n_neighbors : int, default=5
    Number of neighbors for each sample in the transformed sparse graph.
    For compatibility reasons, as each sample is considered as its own
    neighbor, one extra neighbor will be computed when mode == 'distance'.
    In this case, the sparse graph contains (n_neighbors + 1) neighbors.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

metric : str or callable, default='minkowski'
    metric to use for distance computation. Any metric from scikit-learn
    or scipy.spatial.distance can be used.

    If metric is a callable function, it is called on each
    pair of instances (rows) and the resulting value recorded. The callable
    should take two arrays as input and return one value indicating the
    distance between them. This works for Scipy's metrics, but is less
    efficient than passing the metric name as a string.

    Distance matrices are not supported.

    Valid values for metric are:

    - from scikit-learn: ['cityblock', 'cosine', 'euclidean', 'l1', 'l2',
      'manhattan']

    - from scipy.spatial.distance: ['braycurtis', 'canberra', 'chebyshev',
      'correlation', 'dice', 'hamming', 'jaccard', 'kulsinski',
      'mahalanobis', 'minkowski', 'rogerstanimoto', 'russellrao',
      'seuclidean', 'sokalmichener', 'sokalsneath', 'sqeuclidean',
      'yule']

    See the documentation for scipy.spatial.distance for details on these
    metrics.

p : int, default=2
    Parameter for the Minkowski metric from
    sklearn.metrics.pairwise.pairwise_distances. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=1
    The number of parallel jobs to run for neighbors search.
    If ``-1``, then the number of jobs is set to the number of CPU cores.

Examples
--------
>>> from sklearn.manifold import Isomap
>>> from sklearn.neighbors import KNeighborsTransformer
>>> from sklearn.pipeline import make_pipeline
>>> estimator = make_pipeline(
...     KNeighborsTransformer(n_neighbors=5, mode='distance'),
...     Isomap(neighbors_algorithm='precomputed'))
*)

val fit : ?y:Py.Object.t -> x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> [> tag] Obj.t -> t
(**
Fit the model using X as training data

Parameters
----------
X : {array-like, sparse matrix, BallTree, KDTree}
    Training data. If array or matrix, shape [n_samples, n_features],
    or [n_samples, n_samples] if metric='precomputed'.
*)

val fit_transform : ?y:Py.Object.t -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Fit to data, then transform it.

Fits transformer to X and y with optional parameters fit_params
and returns a transformed version of X.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Training set.

y : ignored

Returns
-------
Xt : sparse matrix of shape (n_samples, n_samples)
    Xt[i, j] is assigned the weight of edge that connects i to j.
    Only the neighbors have an explicit value.
    The diagonal is always explicit.
    The matrix is of CSR format.
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

val kneighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> [> tag] Obj.t -> ([>`ArrayLike] Np.Obj.t * [>`ArrayLike] Np.Obj.t)
(**
Finds the K-neighbors of a point.
Returns indices of and distances to the neighbors of each point.

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors to get (default is the value
    passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned

Returns
-------
neigh_dist : array, shape (n_queries, n_neighbors)
    Array representing the lengths to points, only present if
    return_distance=True

neigh_ind : array, shape (n_queries, n_neighbors)
    Indices of the nearest points in the population matrix.

Examples
--------
In the following example, we construct a NearestNeighbors
class from an array representing our data set and ask who's
the closest point to [1,1,1]

>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=1)
>>> neigh.fit(samples)
NearestNeighbors(n_neighbors=1)
>>> print(neigh.kneighbors([[1., 1., 1.]]))
(array([[0.5]]), array([[2]]))

As you can see, it returns [[0.5]], and [[2]], which means that the
element is at distance 0.5 and is the third element of samples
(indexes start at 0). You can also query for multiple points:

>>> X = [[0., 1., 0.], [1., 0., 1.]]
>>> neigh.kneighbors(X, return_distance=False)
array([[1],
       [2]]...)
*)

val kneighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> ?mode:[`Connectivity | `Distance] -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of k-Neighbors for points in X

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors for each sample.
    (default is value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=2)
>>> neigh.fit(X)
NearestNeighbors(n_neighbors=2)
>>> A = neigh.kneighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 1.],
       [1., 0., 1.]])

See also
--------
NearestNeighbors.radius_neighbors_graph
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

val transform : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Parameters
----------
X : array-like of shape (n_samples_transform, n_features)
    Sample data.

Returns
-------
Xt : sparse matrix of shape (n_samples_transform, n_samples_fit)
    Xt[i, j] is assigned the weight of edge that connects i to j.
    Only the neighbors have an explicit value.
    The diagonal is always explicit.
    The matrix is of CSR format.
*)


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module KernelDensity : sig
type tag = [`KernelDensity]
type t = [`BaseEstimator | `KernelDensity | `Object] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_estimator : t -> [`BaseEstimator] Obj.t
val create : ?bandwidth:float -> ?algorithm:string -> ?kernel:string -> ?metric:string -> ?atol:float -> ?rtol:float -> ?breadth_first:bool -> ?leaf_size:int -> ?metric_params:Dict.t -> unit -> t
(**
Kernel Density Estimation.

Read more in the :ref:`User Guide <kernel_density>`.

Parameters
----------
bandwidth : float
    The bandwidth of the kernel.

algorithm : str
    The tree algorithm to use.  Valid options are
    ['kd_tree'|'ball_tree'|'auto'].  Default is 'auto'.

kernel : str
    The kernel to use.  Valid kernels are
    ['gaussian'|'tophat'|'epanechnikov'|'exponential'|'linear'|'cosine']
    Default is 'gaussian'.

metric : str
    The distance metric to use.  Note that not all metrics are
    valid with all algorithms.  Refer to the documentation of
    :class:`BallTree` and :class:`KDTree` for a description of
    available algorithms.  Note that the normalization of the density
    output is correct only for the Euclidean distance metric. Default
    is 'euclidean'.

atol : float
    The desired absolute tolerance of the result.  A larger tolerance will
    generally lead to faster execution. Default is 0.

rtol : float
    The desired relative tolerance of the result.  A larger tolerance will
    generally lead to faster execution.  Default is 1E-8.

breadth_first : bool
    If true (default), use a breadth-first approach to the problem.
    Otherwise use a depth-first approach.

leaf_size : int
    Specify the leaf size of the underlying tree.  See :class:`BallTree`
    or :class:`KDTree` for details.  Default is 40.

metric_params : dict
    Additional parameters to be passed to the tree for use with the
    metric.  For more information, see the documentation of
    :class:`BallTree` or :class:`KDTree`.

See Also
--------
sklearn.neighbors.KDTree : K-dimensional tree for fast generalized N-point
    problems.
sklearn.neighbors.BallTree : Ball tree for fast generalized N-point
    problems.

Examples
--------
Compute a gaussian kernel density estimate with a fixed bandwidth.
>>> import numpy as np
>>> rng = np.random.RandomState(42)
>>> X = rng.random_sample((100, 3))
>>> kde = KernelDensity(kernel='gaussian', bandwidth=0.5).fit(X)
>>> log_density = kde.score_samples(X[:3])
>>> log_density
array([-1.52955942, -1.51462041, -1.60244657])
*)

val fit : ?y:Py.Object.t -> ?sample_weight:[>`ArrayLike] Np.Obj.t -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the Kernel Density model on the data.

Parameters
----------
X : array_like, shape (n_samples, n_features)
    List of n_features-dimensional data points.  Each row
    corresponds to a single data point.
y : None
    Ignored. This parameter exists only for compatibility with
    :class:`sklearn.pipeline.Pipeline`.
sample_weight : array_like, shape (n_samples,), optional
    List of sample weights attached to the data X.

    .. versionadded:: 0.20

Returns
-------
self : object
    Returns instance of object.
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

val sample : ?n_samples:int -> ?random_state:int -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Generate random samples from the model.

Currently, this is implemented only for gaussian and tophat kernels.

Parameters
----------
n_samples : int, optional
    Number of samples to generate. Defaults to 1.

random_state : int, RandomState instance, default=None
    Determines random number generation used to generate
    random samples. Pass an int for reproducible results
    across multiple function calls.
    See :term: `Glossary <random_state>`.

Returns
-------
X : array_like, shape (n_samples, n_features)
    List of samples.
*)

val score : ?y:Py.Object.t -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> float
(**
Compute the total log probability density under the model.

Parameters
----------
X : array_like, shape (n_samples, n_features)
    List of n_features-dimensional data points.  Each row
    corresponds to a single data point.
y : None
    Ignored. This parameter exists only for compatibility with
    :class:`sklearn.pipeline.Pipeline`.

Returns
-------
logprob : float
    Total log-likelihood of the data in X. This is normalized to be a
    probability density, so the value will be low for high-dimensional
    data.
*)

val score_samples : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Evaluate the log density model on the data.

Parameters
----------
X : array_like, shape (n_samples, n_features)
    An array of points to query.  Last dimension should match dimension
    of training data (n_features).

Returns
-------
density : ndarray, shape (n_samples,)
    The array of log(density) evaluations. These are normalized to be
    probability densities, so values will be low for high-dimensional
    data.
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


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module LocalOutlierFactor : sig
type tag = [`LocalOutlierFactor]
type t = [`BaseEstimator | `KNeighborsMixin | `LocalOutlierFactor | `MultiOutputMixin | `NeighborsBase | `Object | `OutlierMixin | `UnsupervisedMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_outlier : t -> [`OutlierMixin] Obj.t
val as_k_neighbors : t -> [`KNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val as_unsupervised : t -> [`UnsupervisedMixin] Obj.t
val create : ?n_neighbors:int -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?p:int -> ?metric_params:Dict.t -> ?contamination:[`Auto | `F of float] -> ?novelty:bool -> ?n_jobs:int -> unit -> t
(**
Unsupervised Outlier Detection using Local Outlier Factor (LOF)

The anomaly score of each sample is called Local Outlier Factor.
It measures the local deviation of density of a given sample with
respect to its neighbors.
It is local in that the anomaly score depends on how isolated the object
is with respect to the surrounding neighborhood.
More precisely, locality is given by k-nearest neighbors, whose distance
is used to estimate the local density.
By comparing the local density of a sample to the local densities of
its neighbors, one can identify samples that have a substantially lower
density than their neighbors. These are considered outliers.

.. versionadded:: 0.19

Parameters
----------
n_neighbors : int, default=20
    Number of neighbors to use by default for :meth:`kneighbors` queries.
    If n_neighbors is larger than the number of samples provided,
    all samples will be used.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to :class:`BallTree` or :class:`KDTree`. This can
    affect the speed of the construction and query, as well as the memory
    required to store the tree. The optimal value depends on the
    nature of the problem.

metric : str or callable, default='minkowski'
    metric used for the distance computation. Any metric from scikit-learn
    or scipy.spatial.distance can be used.

    If metric is 'precomputed', X is assumed to be a distance matrix and
    must be square. X may be a sparse matrix, in which case only 'nonzero'
    elements may be considered neighbors.

    If metric is a callable function, it is called on each
    pair of instances (rows) and the resulting value recorded. The callable
    should take two arrays as input and return one value indicating the
    distance between them. This works for Scipy's metrics, but is less
    efficient than passing the metric name as a string.

    Valid values for metric are:

    - from scikit-learn: ['cityblock', 'cosine', 'euclidean', 'l1', 'l2',
      'manhattan']

    - from scipy.spatial.distance: ['braycurtis', 'canberra', 'chebyshev',
      'correlation', 'dice', 'hamming', 'jaccard', 'kulsinski',
      'mahalanobis', 'minkowski', 'rogerstanimoto', 'russellrao',
      'seuclidean', 'sokalmichener', 'sokalsneath', 'sqeuclidean',
      'yule']

    See the documentation for scipy.spatial.distance for details on these
    metrics:
    https://docs.scipy.org/doc/scipy/reference/spatial.distance.html

p : int, default=2
    Parameter for the Minkowski metric from
    :func:`sklearn.metrics.pairwise.pairwise_distances`. When p = 1, this
    is equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

contamination : 'auto' or float, default='auto'
    The amount of contamination of the data set, i.e. the proportion
    of outliers in the data set. When fitting this is used to define the
    threshold on the scores of the samples.

    - if 'auto', the threshold is determined as in the
      original paper,
    - if a float, the contamination should be in the range [0, 0.5].

    .. versionchanged:: 0.22
       The default value of ``contamination`` changed from 0.1
       to ``'auto'``.

novelty : bool, default=False
    By default, LocalOutlierFactor is only meant to be used for outlier
    detection (novelty=False). Set novelty to True if you want to use
    LocalOutlierFactor for novelty detection. In this case be aware that
    that you should only use predict, decision_function and score_samples
    on new unseen data and not on the training set.

    .. versionadded:: 0.20

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

Attributes
----------
negative_outlier_factor_ : ndarray of shape (n_samples,)
    The opposite LOF of the training samples. The higher, the more normal.
    Inliers tend to have a LOF score close to 1
    (``negative_outlier_factor_`` close to -1), while outliers tend to have
    a larger LOF score.

    The local outlier factor (LOF) of a sample captures its
    supposed 'degree of abnormality'.
    It is the average of the ratio of the local reachability density of
    a sample and those of its k-nearest neighbors.

n_neighbors_ : int
    The actual number of neighbors used for :meth:`kneighbors` queries.

offset_ : float
    Offset used to obtain binary labels from the raw scores.
    Observations having a negative_outlier_factor smaller than `offset_`
    are detected as abnormal.
    The offset is set to -1.5 (inliers score around -1), except when a
    contamination parameter different than 'auto' is provided. In that
    case, the offset is defined in such a way we obtain the expected
    number of outliers in training.

    .. versionadded:: 0.20

Examples
--------
>>> import numpy as np
>>> from sklearn.neighbors import LocalOutlierFactor
>>> X = [[-1.1], [0.2], [101.1], [0.3]]
>>> clf = LocalOutlierFactor(n_neighbors=2)
>>> clf.fit_predict(X)
array([ 1,  1, -1,  1])
>>> clf.negative_outlier_factor_
array([ -0.9821...,  -1.0370..., -73.3697...,  -0.9821...])

References
----------
.. [1] Breunig, M. M., Kriegel, H. P., Ng, R. T., & Sander, J. (2000, May).
       LOF: identifying density-based local outliers. In ACM sigmod record.
*)

val fit : ?y:Py.Object.t -> x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> [> tag] Obj.t -> t
(**
Fit the model using X as training data.

Parameters
----------
X : BallTree, KDTree or {array-like, sparse matrix} of shape                 (n_samples, n_features) or (n_samples, n_samples)
    Training data. If array or matrix, the shape is (n_samples,
    n_features), or (n_samples, n_samples) if metric='precomputed'.

y : Ignored
    Not used, present for API consistency by convention.

Returns
-------
self : object
*)

val fit_predict : ?y:Py.Object.t -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Fits the model to the training set X and returns the labels.

Label is 1 for an inlier and -1 for an outlier according to the LOF
score and the contamination parameter.

Parameters
----------
X : array-like of shape (n_samples, n_features), default=None
    The query sample or samples to compute the Local Outlier Factor
    w.r.t. to the training samples.

Returns
-------
is_inlier : ndarray of shape (n_samples,)
    Returns -1 for anomalies/outliers and 1 for inliers.
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

val kneighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> [> tag] Obj.t -> ([>`ArrayLike] Np.Obj.t * [>`ArrayLike] Np.Obj.t)
(**
Finds the K-neighbors of a point.
Returns indices of and distances to the neighbors of each point.

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors to get (default is the value
    passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned

Returns
-------
neigh_dist : array, shape (n_queries, n_neighbors)
    Array representing the lengths to points, only present if
    return_distance=True

neigh_ind : array, shape (n_queries, n_neighbors)
    Indices of the nearest points in the population matrix.

Examples
--------
In the following example, we construct a NearestNeighbors
class from an array representing our data set and ask who's
the closest point to [1,1,1]

>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=1)
>>> neigh.fit(samples)
NearestNeighbors(n_neighbors=1)
>>> print(neigh.kneighbors([[1., 1., 1.]]))
(array([[0.5]]), array([[2]]))

As you can see, it returns [[0.5]], and [[2]], which means that the
element is at distance 0.5 and is the third element of samples
(indexes start at 0). You can also query for multiple points:

>>> X = [[0., 1., 0.], [1., 0., 1.]]
>>> neigh.kneighbors(X, return_distance=False)
array([[1],
       [2]]...)
*)

val kneighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> ?mode:[`Connectivity | `Distance] -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of k-Neighbors for points in X

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors for each sample.
    (default is value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=2)
>>> neigh.fit(X)
NearestNeighbors(n_neighbors=2)
>>> A = neigh.kneighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 1.],
       [1., 0., 1.]])

See also
--------
NearestNeighbors.radius_neighbors_graph
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


(** Attribute negative_outlier_factor_: get value or raise Not_found if None.*)
val negative_outlier_factor_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute negative_outlier_factor_: get value as an option. *)
val negative_outlier_factor_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Attribute n_neighbors_: get value or raise Not_found if None.*)
val n_neighbors_ : t -> int

(** Attribute n_neighbors_: get value as an option. *)
val n_neighbors_opt : t -> (int) option


(** Attribute offset_: get value or raise Not_found if None.*)
val offset_ : t -> float

(** Attribute offset_: get value as an option. *)
val offset_opt : t -> (float) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module NearestCentroid : sig
type tag = [`NearestCentroid]
type t = [`BaseEstimator | `ClassifierMixin | `NearestCentroid | `Object] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_classifier : t -> [`ClassifierMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val create : ?metric:[`S of string | `Callable of Py.Object.t] -> ?shrink_threshold:float -> unit -> t
(**
Nearest centroid classifier.

Each class is represented by its centroid, with test samples classified to
the class with the nearest centroid.

Read more in the :ref:`User Guide <nearest_centroid_classifier>`.

Parameters
----------
metric : str or callable
    The metric to use when calculating distance between instances in a
    feature array. If metric is a string or callable, it must be one of
    the options allowed by metrics.pairwise.pairwise_distances for its
    metric parameter.
    The centroids for the samples corresponding to each class is the point
    from which the sum of the distances (according to the metric) of all
    samples that belong to that particular class are minimized.
    If the 'manhattan' metric is provided, this centroid is the median and
    for all other metrics, the centroid is now set to be the mean.

    .. versionchanged:: 0.19
        ``metric='precomputed'`` was deprecated and now raises an error

shrink_threshold : float, default=None
    Threshold for shrinking centroids to remove features.

Attributes
----------
centroids_ : array-like of shape (n_classes, n_features)
    Centroid of each class.

classes_ : array of shape (n_classes,)
    The unique classes labels.

Examples
--------
>>> from sklearn.neighbors import NearestCentroid
>>> import numpy as np
>>> X = np.array([[-1, -1], [-2, -1], [-3, -2], [1, 1], [2, 1], [3, 2]])
>>> y = np.array([1, 1, 1, 2, 2, 2])
>>> clf = NearestCentroid()
>>> clf.fit(X, y)
NearestCentroid()
>>> print(clf.predict([[-0.8, -1]]))
[1]

See also
--------
sklearn.neighbors.KNeighborsClassifier: nearest neighbors classifier

Notes
-----
When used for text classification with tf-idf vectors, this classifier is
also known as the Rocchio classifier.

References
----------
Tibshirani, R., Hastie, T., Narasimhan, B., & Chu, G. (2002). Diagnosis of
multiple cancer types by shrunken centroids of gene expression. Proceedings
of the National Academy of Sciences of the United States of America,
99(10), 6567-6572. The National Academy of Sciences.
*)

val fit : x:[>`ArrayLike] Np.Obj.t -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the NearestCentroid model according to the given training data.

Parameters
----------
X : {array-like, sparse matrix} of shape (n_samples, n_features)
    Training vector, where n_samples is the number of samples and
    n_features is the number of features.
    Note that centroid shrinking cannot be used with sparse matrices.
y : array-like of shape (n_samples,)
    Target values (integers)
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
Perform classification on an array of test vectors X.

The predicted class C for each sample in X is returned.

Parameters
----------
X : array-like of shape (n_samples, n_features)

Returns
-------
C : ndarray of shape (n_samples,)

Notes
-----
If the metric constructor parameter is 'precomputed', X is assumed to
be the distance matrix between the data to be predicted and
``self.centroids_``.
*)

val score : ?sample_weight:[>`ArrayLike] Np.Obj.t -> x:[>`ArrayLike] Np.Obj.t -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> float
(**
Return the mean accuracy on the given test data and labels.

In multi-label classification, this is the subset accuracy
which is a harsh metric since you require for each sample that
each label set be correctly predicted.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Test samples.

y : array-like of shape (n_samples,) or (n_samples, n_outputs)
    True labels for X.

sample_weight : array-like of shape (n_samples,), default=None
    Sample weights.

Returns
-------
score : float
    Mean accuracy of self.predict(X) wrt. y.
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


(** Attribute centroids_: get value or raise Not_found if None.*)
val centroids_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute centroids_: get value as an option. *)
val centroids_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Attribute classes_: get value or raise Not_found if None.*)
val classes_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute classes_: get value as an option. *)
val classes_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module NearestNeighbors : sig
type tag = [`NearestNeighbors]
type t = [`BaseEstimator | `KNeighborsMixin | `MultiOutputMixin | `NearestNeighbors | `NeighborsBase | `Object | `RadiusNeighborsMixin | `UnsupervisedMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_radius_neighbors : t -> [`RadiusNeighborsMixin] Obj.t
val as_k_neighbors : t -> [`KNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val as_unsupervised : t -> [`UnsupervisedMixin] Obj.t
val create : ?n_neighbors:int -> ?radius:float -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?p:int -> ?metric_params:Dict.t -> ?n_jobs:int -> unit -> t
(**
Unsupervised learner for implementing neighbor searches.

Read more in the :ref:`User Guide <unsupervised_neighbors>`.

.. versionadded:: 0.9

Parameters
----------
n_neighbors : int, default=5
    Number of neighbors to use by default for :meth:`kneighbors` queries.

radius : float, default=1.0
    Range of parameter space to use by default for :meth:`radius_neighbors`
    queries.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

metric : str or callable, default='minkowski'
    the distance metric to use for the tree.  The default metric is
    minkowski, and with p=2 is equivalent to the standard Euclidean
    metric. See the documentation of :class:`DistanceMetric` for a
    list of available metrics.
    If metric is 'precomputed', X is assumed to be a distance matrix and
    must be square during fit. X may be a :term:`sparse graph`,
    in which case only 'nonzero' elements may be considered neighbors.

p : int, default=2
    Parameter for the Minkowski metric from
    sklearn.metrics.pairwise.pairwise_distances. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

Attributes
----------
effective_metric_ : str
    Metric used to compute distances to neighbors.

effective_metric_params_ : dict
    Parameters for the metric used to compute distances to neighbors.

Examples
--------
  >>> import numpy as np
  >>> from sklearn.neighbors import NearestNeighbors
  >>> samples = [[0, 0, 2], [1, 0, 0], [0, 0, 1]]

  >>> neigh = NearestNeighbors(n_neighbors=2, radius=0.4)
  >>> neigh.fit(samples)
  NearestNeighbors(...)

  >>> neigh.kneighbors([[0, 0, 1.3]], 2, return_distance=False)
  array([[2, 0]]...)

  >>> nbrs = neigh.radius_neighbors([[0, 0, 1.3]], 0.4, return_distance=False)
  >>> np.asarray(nbrs[0][0])
  array(2)

See also
--------
KNeighborsClassifier
RadiusNeighborsClassifier
KNeighborsRegressor
RadiusNeighborsRegressor
BallTree

Notes
-----
See :ref:`Nearest Neighbors <neighbors>` in the online documentation
for a discussion of the choice of ``algorithm`` and ``leaf_size``.

https://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm
*)

val fit : ?y:Py.Object.t -> x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> [> tag] Obj.t -> t
(**
Fit the model using X as training data

Parameters
----------
X : {array-like, sparse matrix, BallTree, KDTree}
    Training data. If array or matrix, shape [n_samples, n_features],
    or [n_samples, n_samples] if metric='precomputed'.
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

val kneighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> [> tag] Obj.t -> ([>`ArrayLike] Np.Obj.t * [>`ArrayLike] Np.Obj.t)
(**
Finds the K-neighbors of a point.
Returns indices of and distances to the neighbors of each point.

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors to get (default is the value
    passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned

Returns
-------
neigh_dist : array, shape (n_queries, n_neighbors)
    Array representing the lengths to points, only present if
    return_distance=True

neigh_ind : array, shape (n_queries, n_neighbors)
    Indices of the nearest points in the population matrix.

Examples
--------
In the following example, we construct a NearestNeighbors
class from an array representing our data set and ask who's
the closest point to [1,1,1]

>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=1)
>>> neigh.fit(samples)
NearestNeighbors(n_neighbors=1)
>>> print(neigh.kneighbors([[1., 1., 1.]]))
(array([[0.5]]), array([[2]]))

As you can see, it returns [[0.5]], and [[2]], which means that the
element is at distance 0.5 and is the third element of samples
(indexes start at 0). You can also query for multiple points:

>>> X = [[0., 1., 0.], [1., 0., 1.]]
>>> neigh.kneighbors(X, return_distance=False)
array([[1],
       [2]]...)
*)

val kneighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?n_neighbors:int -> ?mode:[`Connectivity | `Distance] -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of k-Neighbors for points in X

Parameters
----------
X : array-like, shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

n_neighbors : int
    Number of neighbors for each sample.
    (default is value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(n_neighbors=2)
>>> neigh.fit(X)
NearestNeighbors(n_neighbors=2)
>>> A = neigh.kneighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 1.],
       [1., 0., 1.]])

See also
--------
NearestNeighbors.radius_neighbors_graph
*)

val radius_neighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?sort_results:bool -> [> tag] Obj.t -> (Np.Numpy.Ndarray.List.t * Np.Numpy.Ndarray.List.t)
(**
Finds the neighbors within a given radius of a point or points.

Return the indices and distances of each point from the dataset
lying in a ball with size ``radius`` around the points of the query
array. Points lying on the boundary are included in the results.

The result points are *not* necessarily sorted by distance to their
query point.

Parameters
----------
X : array-like, (n_samples, n_features), optional
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Limiting distance of neighbors to return.
    (default is the value passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted. If
    return_distance == False, setting sort_results = True will
    result in an error.

    .. versionadded:: 0.22

Returns
-------
neigh_dist : array, shape (n_samples,) of arrays
    Array representing the distances to each point, only present if
    return_distance=True. The distance values are computed according
    to the ``metric`` constructor parameter.

neigh_ind : array, shape (n_samples,) of arrays
    An array of arrays of indices of the approximate nearest points
    from the population matrix that lie within a ball of size
    ``radius`` around the query points.

Examples
--------
In the following example, we construct a NeighborsClassifier
class from an array representing our data set and ask who's
the closest point to [1, 1, 1]:

>>> import numpy as np
>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.6)
>>> neigh.fit(samples)
NearestNeighbors(radius=1.6)
>>> rng = neigh.radius_neighbors([[1., 1., 1.]])
>>> print(np.asarray(rng[0][0]))
[1.5 0.5]
>>> print(np.asarray(rng[1][0]))
[1 2]

The first array returned contains the distances to all points which
are closer than 1.6, while the second array returned contains their
indices.  In general, multiple points can be queried at the same time.

Notes
-----
Because the number of neighbors of each point is not necessarily
equal, the results for multiple query points cannot be fit in a
standard data array.
For efficiency, `radius_neighbors` returns arrays of objects, where
each object is a 1D array of indices or distances.
*)

val radius_neighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?mode:[`Connectivity | `Distance] -> ?sort_results:bool -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Neighborhoods are restricted the points at a distance lower than
radius.

Parameters
----------
X : array-like of shape (n_samples, n_features), default=None
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Radius of neighborhoods.
    (default is the value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted.
    Only used with mode='distance'.

    .. versionadded:: 0.22

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.5)
>>> neigh.fit(X)
NearestNeighbors(radius=1.5)
>>> A = neigh.radius_neighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 0.],
       [1., 0., 1.]])

See also
--------
kneighbors_graph
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


(** Attribute effective_metric_: get value or raise Not_found if None.*)
val effective_metric_ : t -> string

(** Attribute effective_metric_: get value as an option. *)
val effective_metric_opt : t -> (string) option


(** Attribute effective_metric_params_: get value or raise Not_found if None.*)
val effective_metric_params_ : t -> Dict.t

(** Attribute effective_metric_params_: get value as an option. *)
val effective_metric_params_opt : t -> (Dict.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module NeighborhoodComponentsAnalysis : sig
type tag = [`NeighborhoodComponentsAnalysis]
type t = [`BaseEstimator | `NeighborhoodComponentsAnalysis | `Object | `TransformerMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_transformer : t -> [`TransformerMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val create : ?n_components:int -> ?init:[`Random | `Auto | `Arr of [>`ArrayLike] Np.Obj.t | `Pca | `Identity | `Lda] -> ?warm_start:bool -> ?max_iter:int -> ?tol:float -> ?callback:Py.Object.t -> ?verbose:int -> ?random_state:int -> unit -> t
(**
Neighborhood Components Analysis

Neighborhood Component Analysis (NCA) is a machine learning algorithm for
metric learning. It learns a linear transformation in a supervised fashion
to improve the classification accuracy of a stochastic nearest neighbors
rule in the transformed space.

Read more in the :ref:`User Guide <nca>`.

Parameters
----------
n_components : int, default=None
    Preferred dimensionality of the projected space.
    If None it will be set to ``n_features``.

init : {'auto', 'pca', 'lda', 'identity', 'random'} or ndarray of shape             (n_features_a, n_features_b), default='auto'
    Initialization of the linear transformation. Possible options are
    'auto', 'pca', 'lda', 'identity', 'random', and a numpy array of shape
    (n_features_a, n_features_b).

    'auto'
        Depending on ``n_components``, the most reasonable initialization
        will be chosen. If ``n_components <= n_classes`` we use 'lda', as
        it uses labels information. If not, but
        ``n_components < min(n_features, n_samples)``, we use 'pca', as
        it projects data in meaningful directions (those of higher
        variance). Otherwise, we just use 'identity'.

    'pca'
        ``n_components`` principal components of the inputs passed
        to :meth:`fit` will be used to initialize the transformation.
        (See :class:`~sklearn.decomposition.PCA`)

    'lda'
        ``min(n_components, n_classes)`` most discriminative
        components of the inputs passed to :meth:`fit` will be used to
        initialize the transformation. (If ``n_components > n_classes``,
        the rest of the components will be zero.) (See
        :class:`~sklearn.discriminant_analysis.LinearDiscriminantAnalysis`)

    'identity'
        If ``n_components`` is strictly smaller than the
        dimensionality of the inputs passed to :meth:`fit`, the identity
        matrix will be truncated to the first ``n_components`` rows.

    'random'
        The initial transformation will be a random array of shape
        `(n_components, n_features)`. Each value is sampled from the
        standard normal distribution.

    numpy array
        n_features_b must match the dimensionality of the inputs passed to
        :meth:`fit` and n_features_a must be less than or equal to that.
        If ``n_components`` is not None, n_features_a must match it.

warm_start : bool, default=False
    If True and :meth:`fit` has been called before, the solution of the
    previous call to :meth:`fit` is used as the initial linear
    transformation (``n_components`` and ``init`` will be ignored).

max_iter : int, default=50
    Maximum number of iterations in the optimization.

tol : float, default=1e-5
    Convergence tolerance for the optimization.

callback : callable, default=None
    If not None, this function is called after every iteration of the
    optimizer, taking as arguments the current solution (flattened
    transformation matrix) and the number of iterations. This might be
    useful in case one wants to examine or store the transformation
    found after each iteration.

verbose : int, default=0
    If 0, no progress messages will be printed.
    If 1, progress messages will be printed to stdout.
    If > 1, progress messages will be printed and the ``disp``
    parameter of :func:`scipy.optimize.minimize` will be set to
    ``verbose - 2``.

random_state : int or numpy.RandomState, default=None
    A pseudo random number generator object or a seed for it if int. If
    ``init='random'``, ``random_state`` is used to initialize the random
    transformation. If ``init='pca'``, ``random_state`` is passed as an
    argument to PCA when initializing the transformation. Pass an int
    for reproducible results across multiple function calls.
    See :term: `Glossary <random_state>`.

Attributes
----------
components_ : ndarray of shape (n_components, n_features)
    The linear transformation learned during fitting.

n_iter_ : int
    Counts the number of iterations performed by the optimizer.

random_state_ : numpy.RandomState
    Pseudo random number generator object used during initialization.

Examples
--------
>>> from sklearn.neighbors import NeighborhoodComponentsAnalysis
>>> from sklearn.neighbors import KNeighborsClassifier
>>> from sklearn.datasets import load_iris
>>> from sklearn.model_selection import train_test_split
>>> X, y = load_iris(return_X_y=True)
>>> X_train, X_test, y_train, y_test = train_test_split(X, y,
... stratify=y, test_size=0.7, random_state=42)
>>> nca = NeighborhoodComponentsAnalysis(random_state=42)
>>> nca.fit(X_train, y_train)
NeighborhoodComponentsAnalysis(...)
>>> knn = KNeighborsClassifier(n_neighbors=3)
>>> knn.fit(X_train, y_train)
KNeighborsClassifier(...)
>>> print(knn.score(X_test, y_test))
0.933333...
>>> knn.fit(nca.transform(X_train), y_train)
KNeighborsClassifier(...)
>>> print(knn.score(nca.transform(X_test), y_test))
0.961904...

References
----------
.. [1] J. Goldberger, G. Hinton, S. Roweis, R. Salakhutdinov.
       'Neighbourhood Components Analysis'. Advances in Neural Information
       Processing Systems. 17, 513-520, 2005.
       http://www.cs.nyu.edu/~roweis/papers/ncanips.pdf

.. [2] Wikipedia entry on Neighborhood Components Analysis
       https://en.wikipedia.org/wiki/Neighbourhood_components_analysis
*)

val fit : x:[>`ArrayLike] Np.Obj.t -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the model according to the given training data.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    The training samples.

y : array-like of shape (n_samples,)
    The corresponding training labels.

Returns
-------
self : object
    returns a trained NeighborhoodComponentsAnalysis model.
*)

val fit_transform : ?y:[>`ArrayLike] Np.Obj.t -> ?fit_params:(string * Py.Object.t) list -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Fit to data, then transform it.

Fits transformer to X and y with optional parameters fit_params
and returns a transformed version of X.

Parameters
----------
X : {array-like, sparse matrix, dataframe} of shape                 (n_samples, n_features)

y : ndarray of shape (n_samples,), default=None
    Target values.

**fit_params : dict
    Additional fit parameters.

Returns
-------
X_new : ndarray array of shape (n_samples, n_features_new)
    Transformed array.
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

val transform : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Applies the learned transformation to the given data.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Data samples.

Returns
-------
X_embedded: ndarray of shape (n_samples, n_components)
    The data samples transformed.

Raises
------
NotFittedError
    If :meth:`fit` has not been called before.
*)


(** Attribute components_: get value or raise Not_found if None.*)
val components_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute components_: get value as an option. *)
val components_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Attribute n_iter_: get value or raise Not_found if None.*)
val n_iter_ : t -> int

(** Attribute n_iter_: get value as an option. *)
val n_iter_opt : t -> (int) option


(** Attribute random_state_: get value or raise Not_found if None.*)
val random_state_ : t -> Py.Object.t

(** Attribute random_state_: get value as an option. *)
val random_state_opt : t -> (Py.Object.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module RadiusNeighborsClassifier : sig
type tag = [`RadiusNeighborsClassifier]
type t = [`BaseEstimator | `ClassifierMixin | `MultiOutputMixin | `NeighborsBase | `Object | `RadiusNeighborsClassifier | `RadiusNeighborsMixin | `SupervisedIntegerMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_radius_neighbors : t -> [`RadiusNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val as_classifier : t -> [`ClassifierMixin] Obj.t
val as_supervised_integer : t -> [`SupervisedIntegerMixin] Obj.t
val create : ?radius:float -> ?weights:[`Uniform | `Callable of Py.Object.t | `Distance] -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?p:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?outlier_label:[`Manual_label of Py.Object.t | `Most_frequent] -> ?metric_params:Dict.t -> ?n_jobs:int -> ?kwargs:(string * Py.Object.t) list -> unit -> t
(**
Classifier implementing a vote among neighbors within a given radius

Read more in the :ref:`User Guide <classification>`.

Parameters
----------
radius : float, default=1.0
    Range of parameter space to use by default for :meth:`radius_neighbors`
    queries.

weights : {'uniform', 'distance'} or callable, default='uniform'
    weight function used in prediction.  Possible values:

    - 'uniform' : uniform weights.  All points in each neighborhood
      are weighted equally.
    - 'distance' : weight points by the inverse of their distance.
      in this case, closer neighbors of a query point will have a
      greater influence than neighbors which are further away.
    - [callable] : a user-defined function which accepts an
      array of distances, and returns an array of the same shape
      containing the weights.

    Uniform weights are used by default.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

p : int, default=2
    Power parameter for the Minkowski metric. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric : str or callable, default='minkowski'
    the distance metric to use for the tree.  The default metric is
    minkowski, and with p=2 is equivalent to the standard Euclidean
    metric. See the documentation of :class:`DistanceMetric` for a
    list of available metrics.
    If metric is 'precomputed', X is assumed to be a distance matrix and
    must be square during fit. X may be a :term:`sparse graph`,
    in which case only 'nonzero' elements may be considered neighbors.

outlier_label : {manual label, 'most_frequent'}, default=None
    label for outlier samples (samples with no neighbors in given radius).

    - manual label: str or int label (should be the same type as y)
      or list of manual labels if multi-output is used.
    - 'most_frequent' : assign the most frequent label of y to outliers.
    - None : when any outlier is detected, ValueError will be raised.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

Attributes
----------
classes_ : ndarray of shape (n_classes,)
    Class labels known to the classifier.

effective_metric_ : str or callble
    The distance metric used. It will be same as the `metric` parameter
    or a synonym of it, e.g. 'euclidean' if the `metric` parameter set to
    'minkowski' and `p` parameter set to 2.

effective_metric_params_ : dict
    Additional keyword arguments for the metric function. For most metrics
    will be same with `metric_params` parameter, but may also contain the
    `p` parameter value if the `effective_metric_` attribute is set to
    'minkowski'.

outputs_2d_ : bool
    False when `y`'s shape is (n_samples, ) or (n_samples, 1) during fit
    otherwise True.

Examples
--------
>>> X = [[0], [1], [2], [3]]
>>> y = [0, 0, 1, 1]
>>> from sklearn.neighbors import RadiusNeighborsClassifier
>>> neigh = RadiusNeighborsClassifier(radius=1.0)
>>> neigh.fit(X, y)
RadiusNeighborsClassifier(...)
>>> print(neigh.predict([[1.5]]))
[0]
>>> print(neigh.predict_proba([[1.0]]))
[[0.66666667 0.33333333]]

See also
--------
KNeighborsClassifier
RadiusNeighborsRegressor
KNeighborsRegressor
NearestNeighbors

Notes
-----
See :ref:`Nearest Neighbors <neighbors>` in the online documentation
for a discussion of the choice of ``algorithm`` and ``leaf_size``.

https://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm
*)

val fit : x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the model using X as training data and y as target values

Parameters
----------
X : BallTree, KDTree or {array-like, sparse matrix} of shape                 (n_samples, n_features) or (n_samples, n_samples)
    Training data. If array or matrix, the shape is (n_samples,
    n_features), or (n_samples, n_samples) if metric='precomputed'.

y : {array-like, sparse matrix} of shape (n_samples,) or                 (n_samples, n_output)
    Target values.
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
Predict the class labels for the provided data.

Parameters
----------
X : array-like of shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    Test samples.

Returns
-------
y : ndarray of shape (n_queries,) or (n_queries, n_outputs)
    Class labels for each data sample.
*)

val predict_proba : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Return probability estimates for the test data X.

Parameters
----------
X : array-like of shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    Test samples.

Returns
-------
p : ndarray of shape (n_queries, n_classes), or a list of n_outputs
    of such arrays if n_outputs > 1.
    The class probabilities of the input samples. Classes are ordered
    by lexicographic order.
*)

val radius_neighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?sort_results:bool -> [> tag] Obj.t -> (Np.Numpy.Ndarray.List.t * Np.Numpy.Ndarray.List.t)
(**
Finds the neighbors within a given radius of a point or points.

Return the indices and distances of each point from the dataset
lying in a ball with size ``radius`` around the points of the query
array. Points lying on the boundary are included in the results.

The result points are *not* necessarily sorted by distance to their
query point.

Parameters
----------
X : array-like, (n_samples, n_features), optional
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Limiting distance of neighbors to return.
    (default is the value passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted. If
    return_distance == False, setting sort_results = True will
    result in an error.

    .. versionadded:: 0.22

Returns
-------
neigh_dist : array, shape (n_samples,) of arrays
    Array representing the distances to each point, only present if
    return_distance=True. The distance values are computed according
    to the ``metric`` constructor parameter.

neigh_ind : array, shape (n_samples,) of arrays
    An array of arrays of indices of the approximate nearest points
    from the population matrix that lie within a ball of size
    ``radius`` around the query points.

Examples
--------
In the following example, we construct a NeighborsClassifier
class from an array representing our data set and ask who's
the closest point to [1, 1, 1]:

>>> import numpy as np
>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.6)
>>> neigh.fit(samples)
NearestNeighbors(radius=1.6)
>>> rng = neigh.radius_neighbors([[1., 1., 1.]])
>>> print(np.asarray(rng[0][0]))
[1.5 0.5]
>>> print(np.asarray(rng[1][0]))
[1 2]

The first array returned contains the distances to all points which
are closer than 1.6, while the second array returned contains their
indices.  In general, multiple points can be queried at the same time.

Notes
-----
Because the number of neighbors of each point is not necessarily
equal, the results for multiple query points cannot be fit in a
standard data array.
For efficiency, `radius_neighbors` returns arrays of objects, where
each object is a 1D array of indices or distances.
*)

val radius_neighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?mode:[`Connectivity | `Distance] -> ?sort_results:bool -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Neighborhoods are restricted the points at a distance lower than
radius.

Parameters
----------
X : array-like of shape (n_samples, n_features), default=None
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Radius of neighborhoods.
    (default is the value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted.
    Only used with mode='distance'.

    .. versionadded:: 0.22

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.5)
>>> neigh.fit(X)
NearestNeighbors(radius=1.5)
>>> A = neigh.radius_neighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 0.],
       [1., 0., 1.]])

See also
--------
kneighbors_graph
*)

val score : ?sample_weight:[>`ArrayLike] Np.Obj.t -> x:[>`ArrayLike] Np.Obj.t -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> float
(**
Return the mean accuracy on the given test data and labels.

In multi-label classification, this is the subset accuracy
which is a harsh metric since you require for each sample that
each label set be correctly predicted.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Test samples.

y : array-like of shape (n_samples,) or (n_samples, n_outputs)
    True labels for X.

sample_weight : array-like of shape (n_samples,), default=None
    Sample weights.

Returns
-------
score : float
    Mean accuracy of self.predict(X) wrt. y.
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


(** Attribute classes_: get value or raise Not_found if None.*)
val classes_ : t -> [>`ArrayLike] Np.Obj.t

(** Attribute classes_: get value as an option. *)
val classes_opt : t -> ([>`ArrayLike] Np.Obj.t) option


(** Attribute effective_metric_: get value or raise Not_found if None.*)
val effective_metric_ : t -> Py.Object.t

(** Attribute effective_metric_: get value as an option. *)
val effective_metric_opt : t -> (Py.Object.t) option


(** Attribute effective_metric_params_: get value or raise Not_found if None.*)
val effective_metric_params_ : t -> Dict.t

(** Attribute effective_metric_params_: get value as an option. *)
val effective_metric_params_opt : t -> (Dict.t) option


(** Attribute outputs_2d_: get value or raise Not_found if None.*)
val outputs_2d_ : t -> bool

(** Attribute outputs_2d_: get value as an option. *)
val outputs_2d_opt : t -> (bool) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module RadiusNeighborsRegressor : sig
type tag = [`RadiusNeighborsRegressor]
type t = [`BaseEstimator | `MultiOutputMixin | `NeighborsBase | `Object | `RadiusNeighborsMixin | `RadiusNeighborsRegressor | `RegressorMixin | `SupervisedFloatMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_supervised_float : t -> [`SupervisedFloatMixin] Obj.t
val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_radius_neighbors : t -> [`RadiusNeighborsMixin] Obj.t
val as_regressor : t -> [`RegressorMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val create : ?radius:float -> ?weights:[`Uniform | `Callable of Py.Object.t | `Distance] -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?p:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?metric_params:Dict.t -> ?n_jobs:int -> ?kwargs:(string * Py.Object.t) list -> unit -> t
(**
Regression based on neighbors within a fixed radius.

The target is predicted by local interpolation of the targets
associated of the nearest neighbors in the training set.

Read more in the :ref:`User Guide <regression>`.

.. versionadded:: 0.9

Parameters
----------
radius : float, default=1.0
    Range of parameter space to use by default for :meth:`radius_neighbors`
    queries.

weights : {'uniform', 'distance'} or callable, default='uniform'
    weight function used in prediction.  Possible values:

    - 'uniform' : uniform weights.  All points in each neighborhood
      are weighted equally.
    - 'distance' : weight points by the inverse of their distance.
      in this case, closer neighbors of a query point will have a
      greater influence than neighbors which are further away.
    - [callable] : a user-defined function which accepts an
      array of distances, and returns an array of the same shape
      containing the weights.

    Uniform weights are used by default.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

p : int, default=2
    Power parameter for the Minkowski metric. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric : str or callable, default='minkowski'
    the distance metric to use for the tree.  The default metric is
    minkowski, and with p=2 is equivalent to the standard Euclidean
    metric. See the documentation of :class:`DistanceMetric` for a
    list of available metrics.
    If metric is 'precomputed', X is assumed to be a distance matrix and
    must be square during fit. X may be a :term:`sparse graph`,
    in which case only 'nonzero' elements may be considered neighbors.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

Attributes
----------
effective_metric_ : str or callable
    The distance metric to use. It will be same as the `metric` parameter
    or a synonym of it, e.g. 'euclidean' if the `metric` parameter set to
    'minkowski' and `p` parameter set to 2.

effective_metric_params_ : dict
    Additional keyword arguments for the metric function. For most metrics
    will be same with `metric_params` parameter, but may also contain the
    `p` parameter value if the `effective_metric_` attribute is set to
    'minkowski'.

Examples
--------
>>> X = [[0], [1], [2], [3]]
>>> y = [0, 0, 1, 1]
>>> from sklearn.neighbors import RadiusNeighborsRegressor
>>> neigh = RadiusNeighborsRegressor(radius=1.0)
>>> neigh.fit(X, y)
RadiusNeighborsRegressor(...)
>>> print(neigh.predict([[1.5]]))
[0.5]

See also
--------
NearestNeighbors
KNeighborsRegressor
KNeighborsClassifier
RadiusNeighborsClassifier

Notes
-----
See :ref:`Nearest Neighbors <neighbors>` in the online documentation
for a discussion of the choice of ``algorithm`` and ``leaf_size``.

https://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm
*)

val fit : x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> y:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> t
(**
Fit the model using X as training data and y as target values

Parameters
----------
X : {array-like, sparse matrix, BallTree, KDTree}
    Training data. If array or matrix, shape [n_samples, n_features],
    or [n_samples, n_samples] if metric='precomputed'.

y : {array-like, sparse matrix}
    Target values, array of float values, shape = [n_samples]
     or [n_samples, n_outputs]
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
Predict the target for the provided data

Parameters
----------
X : array-like of shape (n_queries, n_features),                 or (n_queries, n_indexed) if metric == 'precomputed'
    Test samples.

Returns
-------
y : ndarray of shape (n_queries,) or (n_queries, n_outputs),                 dtype=double
    Target values.
*)

val radius_neighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?sort_results:bool -> [> tag] Obj.t -> (Np.Numpy.Ndarray.List.t * Np.Numpy.Ndarray.List.t)
(**
Finds the neighbors within a given radius of a point or points.

Return the indices and distances of each point from the dataset
lying in a ball with size ``radius`` around the points of the query
array. Points lying on the boundary are included in the results.

The result points are *not* necessarily sorted by distance to their
query point.

Parameters
----------
X : array-like, (n_samples, n_features), optional
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Limiting distance of neighbors to return.
    (default is the value passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted. If
    return_distance == False, setting sort_results = True will
    result in an error.

    .. versionadded:: 0.22

Returns
-------
neigh_dist : array, shape (n_samples,) of arrays
    Array representing the distances to each point, only present if
    return_distance=True. The distance values are computed according
    to the ``metric`` constructor parameter.

neigh_ind : array, shape (n_samples,) of arrays
    An array of arrays of indices of the approximate nearest points
    from the population matrix that lie within a ball of size
    ``radius`` around the query points.

Examples
--------
In the following example, we construct a NeighborsClassifier
class from an array representing our data set and ask who's
the closest point to [1, 1, 1]:

>>> import numpy as np
>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.6)
>>> neigh.fit(samples)
NearestNeighbors(radius=1.6)
>>> rng = neigh.radius_neighbors([[1., 1., 1.]])
>>> print(np.asarray(rng[0][0]))
[1.5 0.5]
>>> print(np.asarray(rng[1][0]))
[1 2]

The first array returned contains the distances to all points which
are closer than 1.6, while the second array returned contains their
indices.  In general, multiple points can be queried at the same time.

Notes
-----
Because the number of neighbors of each point is not necessarily
equal, the results for multiple query points cannot be fit in a
standard data array.
For efficiency, `radius_neighbors` returns arrays of objects, where
each object is a 1D array of indices or distances.
*)

val radius_neighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?mode:[`Connectivity | `Distance] -> ?sort_results:bool -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Neighborhoods are restricted the points at a distance lower than
radius.

Parameters
----------
X : array-like of shape (n_samples, n_features), default=None
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Radius of neighborhoods.
    (default is the value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted.
    Only used with mode='distance'.

    .. versionadded:: 0.22

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.5)
>>> neigh.fit(X)
NearestNeighbors(radius=1.5)
>>> A = neigh.radius_neighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 0.],
       [1., 0., 1.]])

See also
--------
kneighbors_graph
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


(** Attribute effective_metric_: get value or raise Not_found if None.*)
val effective_metric_ : t -> Py.Object.t

(** Attribute effective_metric_: get value as an option. *)
val effective_metric_opt : t -> (Py.Object.t) option


(** Attribute effective_metric_params_: get value or raise Not_found if None.*)
val effective_metric_params_ : t -> Dict.t

(** Attribute effective_metric_params_: get value as an option. *)
val effective_metric_params_opt : t -> (Dict.t) option


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

module RadiusNeighborsTransformer : sig
type tag = [`RadiusNeighborsTransformer]
type t = [`BaseEstimator | `MultiOutputMixin | `NeighborsBase | `Object | `RadiusNeighborsMixin | `RadiusNeighborsTransformer | `TransformerMixin | `UnsupervisedMixin] Obj.t
val of_pyobject : Py.Object.t -> t
val to_pyobject : [> tag] Obj.t -> Py.Object.t

val as_multi_output : t -> [`MultiOutputMixin] Obj.t
val as_radius_neighbors : t -> [`RadiusNeighborsMixin] Obj.t
val as_estimator : t -> [`BaseEstimator] Obj.t
val as_neighbors : t -> [`NeighborsBase] Obj.t
val as_transformer : t -> [`TransformerMixin] Obj.t
val as_unsupervised : t -> [`UnsupervisedMixin] Obj.t
val create : ?mode:[`Distance | `Connectivity] -> ?radius:float -> ?algorithm:[`Auto | `Ball_tree | `Kd_tree | `Brute] -> ?leaf_size:int -> ?metric:[`S of string | `Callable of Py.Object.t] -> ?p:int -> ?metric_params:Dict.t -> ?n_jobs:int -> unit -> t
(**
Transform X into a (weighted) graph of neighbors nearer than a radius

The transformed data is a sparse graph as returned by
radius_neighbors_graph.

Read more in the :ref:`User Guide <neighbors_transformer>`.

.. versionadded:: 0.22

Parameters
----------
mode : {'distance', 'connectivity'}, default='distance'
    Type of returned matrix: 'connectivity' will return the connectivity
    matrix with ones and zeros, and 'distance' will return the distances
    between neighbors according to the given metric.

radius : float, default=1.
    Radius of neighborhood in the transformed sparse graph.

algorithm : {'auto', 'ball_tree', 'kd_tree', 'brute'}, default='auto'
    Algorithm used to compute the nearest neighbors:

    - 'ball_tree' will use :class:`BallTree`
    - 'kd_tree' will use :class:`KDTree`
    - 'brute' will use a brute-force search.
    - 'auto' will attempt to decide the most appropriate algorithm
      based on the values passed to :meth:`fit` method.

    Note: fitting on sparse input will override the setting of
    this parameter, using brute force.

leaf_size : int, default=30
    Leaf size passed to BallTree or KDTree.  This can affect the
    speed of the construction and query, as well as the memory
    required to store the tree.  The optimal value depends on the
    nature of the problem.

metric : str or callable, default='minkowski'
    metric to use for distance computation. Any metric from scikit-learn
    or scipy.spatial.distance can be used.

    If metric is a callable function, it is called on each
    pair of instances (rows) and the resulting value recorded. The callable
    should take two arrays as input and return one value indicating the
    distance between them. This works for Scipy's metrics, but is less
    efficient than passing the metric name as a string.

    Distance matrices are not supported.

    Valid values for metric are:

    - from scikit-learn: ['cityblock', 'cosine', 'euclidean', 'l1', 'l2',
      'manhattan']

    - from scipy.spatial.distance: ['braycurtis', 'canberra', 'chebyshev',
      'correlation', 'dice', 'hamming', 'jaccard', 'kulsinski',
      'mahalanobis', 'minkowski', 'rogerstanimoto', 'russellrao',
      'seuclidean', 'sokalmichener', 'sokalsneath', 'sqeuclidean',
      'yule']

    See the documentation for scipy.spatial.distance for details on these
    metrics.

p : int, default=2
    Parameter for the Minkowski metric from
    sklearn.metrics.pairwise.pairwise_distances. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric_params : dict, default=None
    Additional keyword arguments for the metric function.

n_jobs : int, default=1
    The number of parallel jobs to run for neighbors search.
    If ``-1``, then the number of jobs is set to the number of CPU cores.

Examples
--------
>>> from sklearn.cluster import DBSCAN
>>> from sklearn.neighbors import RadiusNeighborsTransformer
>>> from sklearn.pipeline import make_pipeline
>>> estimator = make_pipeline(
...     RadiusNeighborsTransformer(radius=42.0, mode='distance'),
...     DBSCAN(min_samples=30, metric='precomputed'))
*)

val fit : ?y:Py.Object.t -> x:[`Arr of [>`ArrayLike] Np.Obj.t | `PyObject of Py.Object.t] -> [> tag] Obj.t -> t
(**
Fit the model using X as training data

Parameters
----------
X : {array-like, sparse matrix, BallTree, KDTree}
    Training data. If array or matrix, shape [n_samples, n_features],
    or [n_samples, n_samples] if metric='precomputed'.
*)

val fit_transform : ?y:Py.Object.t -> x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Fit to data, then transform it.

Fits transformer to X and y with optional parameters fit_params
and returns a transformed version of X.

Parameters
----------
X : array-like of shape (n_samples, n_features)
    Training set.

y : ignored

Returns
-------
Xt : sparse matrix of shape (n_samples, n_samples)
    Xt[i, j] is assigned the weight of edge that connects i to j.
    Only the neighbors have an explicit value.
    The diagonal is always explicit.
    The matrix is of CSR format.
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

val radius_neighbors : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?sort_results:bool -> [> tag] Obj.t -> (Np.Numpy.Ndarray.List.t * Np.Numpy.Ndarray.List.t)
(**
Finds the neighbors within a given radius of a point or points.

Return the indices and distances of each point from the dataset
lying in a ball with size ``radius`` around the points of the query
array. Points lying on the boundary are included in the results.

The result points are *not* necessarily sorted by distance to their
query point.

Parameters
----------
X : array-like, (n_samples, n_features), optional
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Limiting distance of neighbors to return.
    (default is the value passed to the constructor).

return_distance : boolean, optional. Defaults to True.
    If False, distances will not be returned.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted. If
    return_distance == False, setting sort_results = True will
    result in an error.

    .. versionadded:: 0.22

Returns
-------
neigh_dist : array, shape (n_samples,) of arrays
    Array representing the distances to each point, only present if
    return_distance=True. The distance values are computed according
    to the ``metric`` constructor parameter.

neigh_ind : array, shape (n_samples,) of arrays
    An array of arrays of indices of the approximate nearest points
    from the population matrix that lie within a ball of size
    ``radius`` around the query points.

Examples
--------
In the following example, we construct a NeighborsClassifier
class from an array representing our data set and ask who's
the closest point to [1, 1, 1]:

>>> import numpy as np
>>> samples = [[0., 0., 0.], [0., .5, 0.], [1., 1., .5]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.6)
>>> neigh.fit(samples)
NearestNeighbors(radius=1.6)
>>> rng = neigh.radius_neighbors([[1., 1., 1.]])
>>> print(np.asarray(rng[0][0]))
[1.5 0.5]
>>> print(np.asarray(rng[1][0]))
[1 2]

The first array returned contains the distances to all points which
are closer than 1.6, while the second array returned contains their
indices.  In general, multiple points can be queried at the same time.

Notes
-----
Because the number of neighbors of each point is not necessarily
equal, the results for multiple query points cannot be fit in a
standard data array.
For efficiency, `radius_neighbors` returns arrays of objects, where
each object is a 1D array of indices or distances.
*)

val radius_neighbors_graph : ?x:[>`ArrayLike] Np.Obj.t -> ?radius:float -> ?mode:[`Connectivity | `Distance] -> ?sort_results:bool -> [> tag] Obj.t -> [`ArrayLike|`Csr_matrix|`IndexMixin|`Object] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Neighborhoods are restricted the points at a distance lower than
radius.

Parameters
----------
X : array-like of shape (n_samples, n_features), default=None
    The query point or points.
    If not provided, neighbors of each indexed point are returned.
    In this case, the query point is not considered its own neighbor.

radius : float
    Radius of neighborhoods.
    (default is the value passed to the constructor).

mode : {'connectivity', 'distance'}, optional
    Type of returned matrix: 'connectivity' will return the
    connectivity matrix with ones and zeros, in 'distance' the
    edges are Euclidean distance between points.

sort_results : boolean, optional. Defaults to False.
    If True, the distances and indices will be sorted before being
    returned. If False, the results will not be sorted.
    Only used with mode='distance'.

    .. versionadded:: 0.22

Returns
-------
A : sparse graph in CSR format, shape = [n_queries, n_samples_fit]
    n_samples_fit is the number of samples in the fitted data
    A[i, j] is assigned the weight of edge that connects i to j.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import NearestNeighbors
>>> neigh = NearestNeighbors(radius=1.5)
>>> neigh.fit(X)
NearestNeighbors(radius=1.5)
>>> A = neigh.radius_neighbors_graph(X)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 0.],
       [1., 0., 1.]])

See also
--------
kneighbors_graph
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

val transform : x:[>`ArrayLike] Np.Obj.t -> [> tag] Obj.t -> [>`ArrayLike] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Parameters
----------
X : array-like of shape (n_samples_transform, n_features)
    Sample data

Returns
-------
Xt : sparse matrix of shape (n_samples_transform, n_samples_fit)
    Xt[i, j] is assigned the weight of edge that connects i to j.
    Only the neighbors have an explicit value.
    The diagonal is always explicit.
    The matrix is of CSR format.
*)


(** Print the object to a human-readable representation. *)
val to_string : t -> string


(** Print the object to a human-readable representation. *)
val show : t -> string

(** Pretty-print the object to a formatter. *)
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]


end

val kneighbors_graph : ?mode:[`Connectivity | `Distance] -> ?metric:string -> ?p:int -> ?metric_params:Dict.t -> ?include_self:[`Auto | `Bool of bool] -> ?n_jobs:int -> x:[`BallTree of Py.Object.t | `Arr of [>`ArrayLike] Np.Obj.t] -> n_neighbors:int -> unit -> [`ArrayLike|`Object|`Spmatrix] Np.Obj.t
(**
Computes the (weighted) graph of k-Neighbors for points in X

Read more in the :ref:`User Guide <unsupervised_neighbors>`.

Parameters
----------
X : array-like of shape (n_samples, n_features) or BallTree
    Sample data, in the form of a numpy array or a precomputed
    :class:`BallTree`.

n_neighbors : int
    Number of neighbors for each sample.

mode : {'connectivity', 'distance'}, default='connectivity'
    Type of returned matrix: 'connectivity' will return the connectivity
    matrix with ones and zeros, and 'distance' will return the distances
    between neighbors according to the given metric.

metric : str, default='minkowski'
    The distance metric used to calculate the k-Neighbors for each sample
    point. The DistanceMetric class gives a list of available metrics.
    The default distance is 'euclidean' ('minkowski' metric with the p
    param equal to 2.)

p : int, default=2
    Power parameter for the Minkowski metric. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric_params : dict, default=None
    additional keyword arguments for the metric function.

include_self : bool or 'auto', default=False
    Whether or not to mark each sample as the first nearest neighbor to
    itself. If 'auto', then True is used for mode='connectivity' and False
    for mode='distance'.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

Returns
-------
A : sparse matrix of shape (n_samples, n_samples)
    Graph where A[i, j] is assigned the weight of edge that
    connects i to j. The matrix is of CSR format.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import kneighbors_graph
>>> A = kneighbors_graph(X, 2, mode='connectivity', include_self=True)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 1.],
       [1., 0., 1.]])

See also
--------
radius_neighbors_graph
*)

val radius_neighbors_graph : ?mode:[`Connectivity | `Distance] -> ?metric:string -> ?p:int -> ?metric_params:Dict.t -> ?include_self:[`Auto | `Bool of bool] -> ?n_jobs:int -> x:[`BallTree of Py.Object.t | `Arr of [>`ArrayLike] Np.Obj.t] -> radius:float -> unit -> [`ArrayLike|`Object|`Spmatrix] Np.Obj.t
(**
Computes the (weighted) graph of Neighbors for points in X

Neighborhoods are restricted the points at a distance lower than
radius.

Read more in the :ref:`User Guide <unsupervised_neighbors>`.

Parameters
----------
X : array-like of shape (n_samples, n_features) or BallTree
    Sample data, in the form of a numpy array or a precomputed
    :class:`BallTree`.

radius : float
    Radius of neighborhoods.

mode : {'connectivity', 'distance'}, default='connectivity'
    Type of returned matrix: 'connectivity' will return the connectivity
    matrix with ones and zeros, and 'distance' will return the distances
    between neighbors according to the given metric.

metric : str, default='minkowski'
    The distance metric used to calculate the neighbors within a
    given radius for each sample point. The DistanceMetric class
    gives a list of available metrics. The default distance is
    'euclidean' ('minkowski' metric with the param equal to 2.)

p : int, default=2
    Power parameter for the Minkowski metric. When p = 1, this is
    equivalent to using manhattan_distance (l1), and euclidean_distance
    (l2) for p = 2. For arbitrary p, minkowski_distance (l_p) is used.

metric_params : dict, default=None
    additional keyword arguments for the metric function.

include_self : bool or 'auto', default=False
    Whether or not to mark each sample as the first nearest neighbor to
    itself. If 'auto', then True is used for mode='connectivity' and False
    for mode='distance'.

n_jobs : int, default=None
    The number of parallel jobs to run for neighbors search.
    ``None`` means 1 unless in a :obj:`joblib.parallel_backend` context.
    ``-1`` means using all processors. See :term:`Glossary <n_jobs>`
    for more details.

Returns
-------
A : sparse matrix of shape (n_samples, n_samples)
    Graph where A[i, j] is assigned the weight of edge that connects
    i to j. The matrix is of CSR format.

Examples
--------
>>> X = [[0], [3], [1]]
>>> from sklearn.neighbors import radius_neighbors_graph
>>> A = radius_neighbors_graph(X, 1.5, mode='connectivity',
...                            include_self=True)
>>> A.toarray()
array([[1., 0., 1.],
       [0., 1., 0.],
       [1., 0., 1.]])

See also
--------
kneighbors_graph
*)

