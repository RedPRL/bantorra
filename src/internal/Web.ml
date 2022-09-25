let online =
  lazy begin
    match Curly.get "http://detectportal.firefox.com/canonical.html" with
    | Ok {code = 200; body = "<meta http-equiv=\"refresh\" content=\"0;url=https://support.mozilla.org/kb/captive-portal\"/>"; _} -> true
    | _ -> false
  end

let is_online () = Lazy.force online

let get url =
  Error.tracef "Web.get(%s)" url @@ fun () ->
  match Curly.get url with
  | Ok {code = 200; body; _} -> body
  | Ok {code; _} -> Error.fatalf `Web "Got code %d" code
  | Error err -> Error.fatalf `Web "%a" Curly.Error.pp err
