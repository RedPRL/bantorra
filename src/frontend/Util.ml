let protect_cwd f =
  let dir = Sys.getcwd () in
  match f dir with
  | ans -> Sys.chdir dir; ans
  | exception ext -> Sys.chdir dir; raise ext
