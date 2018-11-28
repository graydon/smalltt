
module Data.Array.Dynamic.Unlifted (
    empty
  , Array
  , clear
  , push
  , Data.Array.Dynamic.Unlifted.read
  , showArray
  , size
  , unsafeRead
  , unsafeWrite
  , write
  , unsafeLast
  , Data.Array.Dynamic.Unlifted.last
  , isEmpty
  ) where

import qualified Data.Primitive.PrimArray     as PA

import           Data.Primitive.UnliftedArray (PrimUnlifted, MutableUnliftedArray)
import qualified Data.Primitive.UnliftedArray as UA

import GHC.Prim

type role Array representational
data Array (a :: *) = Array (MutableUnliftedArray RealWorld
                            (MutableUnliftedArray RealWorld a))

instance PrimUnlifted (Array a) where
  toArrayArray# (Array arr) = unsafeCoerce# arr
  {-# inline toArrayArray# #-}
  fromArrayArray# arr = Array (unsafeCoerce# arr)
  {-# inline fromArrayArray# #-}

defaultCapacity :: Int
defaultCapacity = 5
{-# inline defaultCapacity #-}

undefinedElement :: a
undefinedElement = error "Data.Array.Dynamic.Unlifted: undefined element"
{-# noinline undefinedElement #-}

empty :: forall a. PrimUnlifted a => IO (Array a)
empty = do
  (sizeRef :: PA.MutablePrimArray _ Int) <- PA.newPrimArray 1
  PA.writePrimArray sizeRef 0 0
  elems <- UA.unsafeNewUnliftedArray defaultCapacity
  struct <- UA.newUnliftedArray 2 (unsafeCoerce# sizeRef)
  UA.writeUnliftedArray struct 1 elems
  pure (Array struct)
{-# inlinable empty #-}

unsafeRead :: PrimUnlifted a => Array a -> Int -> IO a
unsafeRead (Array arr) i = do
  elems <- UA.readUnliftedArray arr 1
  UA.readUnliftedArray elems i
{-# inline unsafeRead #-}

read :: PrimUnlifted a => Array a -> Int -> IO a
read arr i = do
  s <- size arr
  if i < s
    then unsafeRead arr i
    else error "Data.Array.Dynamic.Unlifted.read: out of bounds"
{-# inline read #-}

unsafeWrite :: PrimUnlifted a => Array a -> Int -> a -> IO ()
unsafeWrite (Array arr) i ~a = do
  elems <- UA.readUnliftedArray arr 1
  UA.writeUnliftedArray elems i a
{-# inline unsafeWrite #-}

write :: PrimUnlifted a => Array a -> Int -> a -> IO ()
write arr i ~a = do
  s <- size arr
  if i < s
    then unsafeWrite arr i a
    else error "Data.Array.Dynamic.Unlifted.write: out of bounds"
{-#  inline write #-}

getSizeRef ::
          PrimUnlifted a
       => MutableUnliftedArray RealWorld (MutableUnliftedArray RealWorld a)
       -> IO (PA.MutablePrimArray RealWorld Int)
getSizeRef arr = do
  x <- UA.readUnliftedArray arr 0
  pure (unsafeCoerce# x)
{-# inline getSizeRef #-}

getElems :: MutableUnliftedArray RealWorld (MutableUnliftedArray RealWorld a)
       -> IO (MutableUnliftedArray RealWorld a)
getElems arr = UA.readUnliftedArray arr 1
{-# inline getElems #-}

push :: PrimUnlifted a => Array a -> a -> IO ()
push (Array arr) ~a = do
  sizeRef <- getSizeRef arr
  elems <- getElems arr
  size <- PA.readPrimArray sizeRef 0
  let cap = UA.sizeofMutableUnliftedArray elems
  PA.writePrimArray sizeRef 0 (size + 1)
  if (size == cap) then do
    let cap' = 2 * cap
    elems' <- UA.newUnliftedArray cap' (undefinedElement :: a)
    UA.copyMutableUnliftedArray elems' 0 elems 0 size
    UA.writeUnliftedArray elems' size a
    UA.writeUnliftedArray arr 1 elems'
  else do
    UA.writeUnliftedArray elems size a
{-# inlinable push #-}

clear :: PrimUnlifted a => Array a -> IO ()
clear (Array arr) = do
  (sizeRef :: PA.MutablePrimArray _ Int) <- PA.newPrimArray 1
  PA.writePrimArray sizeRef 0 0
  elems <- UA.newUnliftedArray defaultCapacity (undefinedElement :: a)
  UA.writeUnliftedArray arr 0 (unsafeCoerce# sizeRef)
  UA.writeUnliftedArray arr 1 elems
{-# inlinable clear #-}

size :: PrimUnlifted a => Array a -> IO Int
size (Array arr) = do
  sizeRef <- getSizeRef arr
  PA.readPrimArray sizeRef 0
{-# inline size #-}

unsafeLast :: PrimUnlifted a => Array a -> IO a
unsafeLast arr = do
  i <- size arr
  unsafeRead arr (i - 1)
{-# inline unsafeLast #-}

isEmpty :: PrimUnlifted a => Array a -> IO Bool
isEmpty arr = (==0) <$> size arr
{-# inline isEmpty #-}

last :: PrimUnlifted a => Array a -> IO a
last arr = do
  i <- size arr
  isEmpty arr >>= \case
    True -> error "Data.Array.Dynamic.Unlifted.last: empty array"
    _    -> unsafeRead arr (i - 1)
{-# inline last #-}

showArray :: (Show a, PrimUnlifted a) => Array a -> IO String
showArray (Array arr) = do
  elems   <- getElems arr
  sizeRef <- getSizeRef arr
  size    <- PA.readPrimArray sizeRef 0
  elems'  <- UA.freezeUnliftedArray elems 0 size
  pure (show elems')
{-# inlinable showArray #-}
