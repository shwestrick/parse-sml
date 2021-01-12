(** Copyright (c) 2020 Sam Westrick
  *
  * See the file LICENSE for details.
  *)

structure PrettyPrintAst:
sig
  val pretty: Ast.t -> string
end =
struct

  structure PD = PrettySimpleDoc
  open PD

  infix 2 ++ $$
  fun x ++ y = beside (x, y)
  fun x $$ y = above (x, y)

  fun spaces n = List.foldl op++ empty (List.tabulate (n, fn _ => space))

  fun parensAround (x: doc) =
    text "(" ++ x ++ text ")"

  fun sequence delim (xs: PD.t Seq.t) =
    let
      val n = Seq.length xs

      fun get i =
        delim ++ space ++ Seq.nth xs i
    in
      Seq.iterate op++ (Seq.nth xs 0) (Seq.tabulate (fn i => get (i+1)) (n-1))
    end


  fun pretty ast =
    let
      fun showSyntaxSeq s f =
        case s of
          Ast.SyntaxSeq.Empty => empty
        | Ast.SyntaxSeq.One x => text (f x)
        | Ast.SyntaxSeq.Many {elems, ...} =>
            parensAround (sequence (PD.text ",") (Seq.map (PD.text o f) elems))

      fun showDec dec =
        let
          open Ast.Exp
        in
          case dec of
            DecVal {vall, tyvars, elems, delims} =>
              let
                val {recc, pat, eq, exp} = Seq.nth elems 0
              in
                group (
                  group (text "val" ++ space
                  ++ showSyntaxSeq tyvars Token.toString ++ space
                  ++ (if Option.isSome recc then text "rec" else empty) ++ space
                  ++ showPat pat ++ space
                  ++ text "=" ++ space)
                  $$
                  (spaces 2 ++ showExp exp))
              end

          | DecMultiple {elems, ...} =>
              let
                val elems = Seq.map showDec elems
              in
                Seq.iterate op$$ (Seq.nth elems 0) (Seq.drop elems 1)
              end

          | DecEmpty =>
              empty

          | _ =>
              text "<dec>"
        end

      and showPat pat =
        let
          open Ast.Pat
        in
          case pat of
            Atpat (Wild _) =>
              text "_"
          | Atpat (Const tok) =>
              text (Token.toString tok)
          | Atpat (Unit _) =>
              text "()"
          | Atpat (Ident {opp, id}) =>
              (if Option.isSome opp then text "op" else empty)
              ++ text (Token.toString (Ast.MaybeLong.getToken id))
          | Atpat (Parens {pat, ...}) =>
              parensAround (showPat pat)
          | _ =>
              text "<pat>"
        end


      and showExp exp =
        let
          open Ast.Exp
        in
          case exp of
            Const tok =>
              text (Token.toString tok)
          | Unit _ =>
              text "()"
          | Ident {opp, id} =>
              (if Option.isSome opp then text "op" else empty)
              ++ text (Token.toString (Ast.MaybeLong.getToken id))
          | Parens {exp, ...} =>
              parensAround (showExp exp)
          | LetInEnd {dec, exps, ...} =>
              let
                val prettyDec = showDec dec
                val prettyExp = showExp (Seq.nth exps 0)
              in
                group (
                  group (text "let"
                  $$
                  (spaces 2 ++ prettyDec)
                  $$
                  text "in")
                  $$
                  (spaces 2 ++ prettyExp)
                  $$
                  text "end"
                )
              end

          | _ =>
              text "<exp>"
        end

    in
      case ast of Ast.Dec d => PrettySimpleDoc.toString (showDec d)
    end

end