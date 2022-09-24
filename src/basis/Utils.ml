let with_mutex m f =
  Mutex.lock m; Fun.protect ~finally:(fun () -> Mutex.unlock m) f
