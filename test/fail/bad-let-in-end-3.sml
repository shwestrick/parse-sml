val _ =
  let
    val x = let val y = "hello" in () end
    val y = let in (1, 2) end end
  in
    10000.0
  end
