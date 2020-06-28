(** {1 Introduction}

    The git resolver takes an URL that the [git] tool can understand, clones the repository and return the library root within the repository.

    The resolver argument format in YAML is one of the following:
    {v
url: "git@github.com:favonia/bantorra.git"
ref: master
path: [src,library]
    v}
    {v
url: "git@github.com:favonia/bantorra.git"
ref: master
    v}
    {v
url: "git@github.com:favonia/bantorra.git"
path: [src,bantorra]
    v}
    {v
url: "git@github.com:favonia/bantorra.git"
    v}
    The [ref] can be a commit ID, a branch name, a tag name, or anything accepted by your [git fetch] command. (The old [git] before 2015 would not accept commit IDs, but please upgrade it already.) The field [path] is the relative path pointing to the root of the library. If the [path] field is missing, then the tool assumes the library is at the root of the repository. If [ref] is missing, then ["HEAD"] is used, which should point to the tip of the default branch in the remote repository.

    Different URLs pointing to the "same" git repository are treated as different libraries. Therefore, "git@github.com:favonia/bantorra.git" and "https://github.com/favonia/bantorra.git" are treated as two different get repositories. The resolver cannot identify a remote git repository and any local copy not managed by it, either. If there is a dependency between libraries within the same git repository, one should use {e waypoints} (implemented by [BantorraResolvers.Waypoint]) so that relative references can be correctly resolved.

    Given the same URL, the commit ID in use must be identical during the lifespan of the library manager. The resolution would fail if there is an attempt to use different commits of the same repository. Otherwise, the semantics of importing would be broken. As a result, it might be a good idea to use stable tags in larger developments unless the latest commit is absolutely needed. Please also consider the local waypoint resolution if multiple libraries are developed at the same time.

    {1 The Builder}
*)

val resolver : crate_root:string -> Bantorra.Resolver.t
