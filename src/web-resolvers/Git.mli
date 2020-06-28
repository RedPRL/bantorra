(** {1 Introduction}

    The git resolver takes an URL that the [git] tool can understand, clones the repository and return the library root within the repository.

    The resolver argument in YAML can use one of the following formats:
    {v
url: "git@github.com:favonia/bantorra.git"
ref: master
path: [src, library]
    v}
    {v
url: "git@github.com:favonia/bantorra.git"
ref: master
    v}
    {v
url: "git@github.com:favonia/bantorra.git"
path: [src, library]
    v}
    {v
url: "git@github.com:favonia/bantorra.git"
    v}
    The [ref] field can be a commit ID, a branch name, a tag name, or anything accepted by your [git fetch] command. (The old [git] before 2015 would not accept commit IDs, but please upgrade it already.) The field [path] is the relative path pointing to the root of the library. If the [path] field is missing, then the tool assumes the library is at the root of the repository. If [ref] is missing, then ["HEAD"] is used, which should point to the tip of the default branch in the remote repository.

    Different URLs pointing to the "same" git repository are treated as different libraries. Therefore, [git@github.com:favonia/bantorra.git] and [https://github.com/favonia/bantorra.git] are treated as two different git repositories. The resolver cannot identify a remote git repository and any local copy not managed by it, either. A proper solution to this problem is a global mapping table from package names to repositories, as employed by many programming language tools.

    Given the same URL, the commit IDs in use must be identical during the lifespan of the library manager. One can use different branch names or tag names, but they all need to point to the same commit ID. The resolution would fail if there is an attempt to use different commits of the same repository. Otherwise, the semantics of importing would be broken. As a result, it is a good idea to use stable tags in larger developments, unless the latest commit is absolutely needed. One common case would be two libraries in the same repository depending on each other, but then one should local, relative references such as {e waypoints} implemented by [BantorraResolvers.Waypoint].

    {1 The Builder}
*)

val resolver : crate_root:string -> Bantorra.Resolver.t
