let get ?(follow_redirects=true) url =
  let args = if follow_redirects then ["-L"] else [] in
  Logger.tracef "When calling Web.get(%s)" url @@ fun () ->
  match Curly.get ~args url with
  | Ok {code = 200; body; _} -> body
  | Ok {code; _} -> Logger.fatalf `Web "Got code %d" code
  | Error err -> Logger.fatalf `Web "%a" Curly.Error.pp err

(* See https://firefox-source-docs.mozilla.org/networking/captive_portals.html *)
let online =
  lazy begin
    Logger.try_with ~emit:(fun _ -> ()) ~fatal:(fun _ -> false) @@ fun () ->
    String.equal
      (get "http://detectportal.firefox.com/canonical.html")
      "<meta http-equiv=\"refresh\" content=\"0;url=https://support.mozilla.org/kb/captive-portal\"/>"
  end

let is_online () = Lazy.force online
