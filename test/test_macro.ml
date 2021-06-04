open Rresult

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let test01 =
  Alcotest.test_case "rfc7208" `Quick @@ fun () ->
  let ctx =
    Spf.empty
    |> Spf.with_sender (`HELO (Domain_name.of_string_exn "mx.example.org"))
    |> Spf.with_sender
         (`MAILFROM
           (Colombe.Path.of_string_exn "<strong-bad@email.example.com>")) in
  Alcotest.(check (result string msg))
    "01"
    (Spf.Macro.expand_string ctx "%{s}" >>| Domain_name.to_string)
    (Ok "strong-bad@email.example.com") ;
  Alcotest.(check (result string msg))
    "02"
    (Spf.Macro.expand_string ctx "%{o}" >>| Domain_name.to_string)
    (Ok "email.example.com") ;
  Alcotest.(check (result string msg))
    "03"
    (Spf.Macro.expand_string ctx "%{d}" >>| Domain_name.to_string)
    (Ok "email.example.com") ;
  Alcotest.(check (result string msg))
    "04"
    (Spf.Macro.expand_string ctx "%{d4}" >>| Domain_name.to_string)
    (Ok "email.example.com") ;
  Alcotest.(check (result string msg))
    "05"
    (Spf.Macro.expand_string ctx "%{d3}" >>| Domain_name.to_string)
    (Ok "email.example.com") ;
  Alcotest.(check (result string msg))
    "06"
    (Spf.Macro.expand_string ctx "%{d2}" >>| Domain_name.to_string)
    (Ok "example.com") ;
  Alcotest.(check (result string msg))
    "07"
    (Spf.Macro.expand_string ctx "%{d1}" >>| Domain_name.to_string)
    (Ok "com") ;
  Alcotest.(check (result string msg))
    "08"
    (Spf.Macro.expand_string ctx "%{dr}" >>| Domain_name.to_string)
    (Ok "com.example.email") ;
  Alcotest.(check (result string msg))
    "09"
    (Spf.Macro.expand_string ctx "%{d2r}" >>| Domain_name.to_string)
    (Ok "example.email") ;
  Alcotest.(check (result string msg))
    "10"
    (Spf.Macro.expand_string ctx "%{l}" >>| Domain_name.to_string)
    (Ok "strong-bad") ;
  Alcotest.(check (result string msg))
    "11"
    (Spf.Macro.expand_string ctx "%{l-}" >>| Domain_name.to_string)
    (Ok "strong.bad") ;
  Alcotest.(check (result string msg))
    "12"
    (Spf.Macro.expand_string ctx "%{lr}" >>| Domain_name.to_string)
    (Ok "strong-bad") ;
  Alcotest.(check (result string msg))
    "13"
    (Spf.Macro.expand_string ctx "%{lr-}" >>| Domain_name.to_string)
    (Ok "bad.strong") ;
  Alcotest.(check (result string msg))
    "14"
    (Spf.Macro.expand_string ctx "%{l1r-}" >>| Domain_name.to_string)
    (Ok "strong")

let test02 =
  Alcotest.test_case "rfc7208" `Quick @@ fun () ->
  let ctx =
    Spf.empty
    |> Spf.with_ip (Ipaddr.of_string_exn "192.0.2.3")
    |> Spf.with_sender (`HELO (Domain_name.of_string_exn "mx.example.org"))
    |> Spf.with_sender
         (`MAILFROM
           (Colombe.Path.of_string_exn "<strong-bad@email.example.com>")) in
  Alcotest.(check (result string msg))
    "01"
    (Spf.Macro.expand_string ctx "%{ir}.%{v}._spf.%{d2}"
    >>| Domain_name.to_string)
    (Ok "3.2.0.192.in-addr._spf.example.com") ;
  Alcotest.(check (result string msg))
    "02"
    (Spf.Macro.expand_string ctx "%{lr-}.lp._spf.%{d2}"
    >>| Domain_name.to_string)
    (Ok "bad.strong.lp._spf.example.com") ;
  Alcotest.(check (result string msg))
    "03"
    (Spf.Macro.expand_string ctx "%{ir}.%{v}.%{l1r-}.lp._spf.%{d2}"
    >>| Domain_name.to_string)
    (Ok "3.2.0.192.in-addr.strong.lp._spf.example.com") ;
  Alcotest.(check (result string msg))
    "04"
    (Spf.Macro.expand_string ctx "%{d2}.trusted-domains.example.net"
    >>| Domain_name.to_string)
    (Ok "example.com.trusted-domains.example.net") ;
  let ctx = Spf.with_ip (Ipaddr.of_string_exn "2001:db8::cb01") ctx in
  Alcotest.(check (result string msg))
    "05"
    (Spf.Macro.expand_string ctx "%{ir}.%{v}._spf.%{d2}"
    >>| Domain_name.to_string)
    (Ok
       "1.0.b.c.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6._spf.example.com")

let test03 =
  Alcotest.test_case "record" `Quick @@ fun () ->
  let record =
    "v=spf1 ip4:184.104.202.128/27 ip4:184.104.202.96/27 ip4:216.218.159.0/27 \
     ip4:216.218.240.64/26 ip4:64.71.168.192/26 ip4:65.19.128.64/26 \
     ip4:66.220.12.128/27 ip4:72.52.80.0/26 ip4:64.62.250.96/27 \
     ip6:2001:470:1:235::/64 ip6:2001:470:1:258::/64 ip6:2001:470:1:3a8::/64 \
     ip6:2001:470:1:59e::/64 ip6:2001:470:1:669::/64 ip6:2001:470:1:791::/64 \
     ip6:2001:470:1:9a5::/64 ip6:2001:470:1:9f1::/64 \
     ip6:2602:fd3f:0000:ff06::/64 include:mailgun.org mx ptr ~all" in
  match Spf.Term.parse_record record with
  | Ok _ -> ()
  | Error (`Msg err) -> Alcotest.failf "%s." err

let () =
  Alcotest.run "decoding"
    [ ("macro", [ test01; test02 ]); ("record", [ test03 ]) ]
