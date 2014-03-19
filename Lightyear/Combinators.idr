module Lightyear.Combinators

-- This code is distributed under the BSD 2-clause license.
-- See the file LICENSE in the root directory for its full text.

import Lightyear.Core

%access public

infixr 3 :::
private
(:::) : a -> List a -> List a
(:::) x xs = x :: xs

infixr 3 ::.
private
(::.) : a -> Vect n a -> Vect (S n) a
(::.) x xs = x :: xs

||| Run some parser as many times as possible, collecting a list of successes
many : Monad m => ParserT m str a -> ParserT m str (List a)
many p = (pure (:::) <$> p <$>| many p) <|> pure List.Nil

||| Run the specified parser precisely `n` times, returning a vector of successes
ntimes : Monad m => (n : Nat) -> ParserT m str a -> ParserT m str (Vect n a)
ntimes    Z  p = pure Vect.Nil
ntimes (S n) p = [| p ::. ntimes n p |]

||| Like `many`, but the parser must succeed at least once
some : Monad m => ParserT m str a -> ParserT m str (List a)
some p = [| p ::: many p |]

||| Parse repeated instances of at least one `p`, separated by `s`, returning a list of successes
||| @ p the parser for items
||| @ s the parser for separators
sepBy1 : Monad m => (p : ParserT m str a) -> (s : ParserT m str b) -> ParserT m str (List a)
sepBy1 p s = [| p ::: many (s $> p) |]

||| Parse zero or more `p`s, separated by `s`s, returning a list of successes
||| @ p the parser for items
||| @ s the parser for separators
sepBy : Monad m => (p : ParserT m str a) -> (s : ParserT m str b) -> ParserT m str (List a)
sepBy p s = (p `sepBy1` s) <|> pure List.Nil

||| Parse precisely `n` `p`s, separated by `s`s, returning a vect of successes
||| @ n how many to parse
||| @ p the parser for items
||| @ s the parser for separators
sepByN : Monad m => (n : Nat) ->
         (p : ParserT m str a) ->
         (s : ParserT m str b) ->
         ParserT m str (Vect n a)
sepByN    Z  p s = pure Vect.Nil
sepByN (S n) p s = [| p ::. ntimes n (s $> p) |]

||| Alternate between matches of `p` and `s`, returning a list of successes from both.
||| Start with `p`.
alternating : Monad m => (p : ParserT m str a) -> (s : ParserT m str a) -> ParserT m str (List a)
alternating p s = (pure (:::) <$> p <$>| alternating s p) <|> pure List.Nil

||| Throw away the result from a parser
skip : Monad m => ParserT m str a -> ParserT m str ()
skip = map (const ())

||| Attempt to parse `p`. If it succeeds, then return the value. If it fails, continue parsing.
opt : Monad m => (p : ParserT m str a) -> ParserT m str (Maybe a)
opt p = map Just p <|> pure Nothing

-- the following names are inspired by the cut operator from Prolog

-- Monad-like operators

infixr 5 >!=
||| Committing bind
(>!=) : Monad m => ParserT m str a -> (a -> ParserT m str b) -> ParserT m str b
x >!= f = x >>= commitTo . f

infixr 5 >!
||| Committing sequencing
(>!) : Monad m => ParserT m str a -> ParserT m str b -> ParserT m str b
x >! y = x >>= \_ => commitTo y

-- Applicative-like operators

infixl 2 <$!>
||| Committing application
(<$!>) : Monad m => ParserT m str (a -> b) -> ParserT m str a -> ParserT m str b
f <$!> x = f <$> commitTo x

infixl 2 <$!
(<$!) : Monad m => ParserT m str a -> ParserT m str b -> ParserT m str a
x <$! y = x <$ commitTo y

infixl 2 $!>
($!>) : Monad m => ParserT m str a -> ParserT m str b -> ParserT m str b
x $!> y = x $> commitTo y
