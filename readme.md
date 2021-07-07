# Fleuri

This generates identifiers. But the identifiers:
 - have a fixed length
 - are uniformly spread in the available space while remaining random

I started doing this because I was wondering how YouTube generated video IDs.

My approach is to model each ID as a tree.
Let's say we are generating 2-character long IDs made of the characters
`a` and `b`. We can draw a decision tree for generating that ID:

```
          ┌──────┐
      ┌───┤ root ├───┐
      │   └──────┘   │
    ┌─┴─┐          ┌─┴─┐
  ┌─┤ a ├─┐      ┌─┤ b ├─┐
  │ └───┘ │      │ └───┘ │
┌─┴─┐   ┌─┴─┐  ┌─┴─┐   ┌─┴─┐
│ a │   │ b │  │ a │   │ b │
└───┘   └───┘  └───┘   └───┘
```

To generate random IDs, we take a random branch at each node.

Now, to avoid generating the same ID twice, we can simply mark leaf nodes as
already used.

This means that branch nodes can know how many free IDs are under themselves by
simply querying their child nodes.

So, if we weight the random branch selection process using this data, we can favour
the branches that have the most free IDs, thus getting a uniform distribution of IDs.

## Usage

This is a D library.

Instanciate a `IdentGenerator` and call `generate()` from it.

I define some character sets under the `LetterSet` enum.

## Implementation

### Model

Instead of having "pure" leaf nodes as in above, the last branch nodes (which
therefore are the leaf nodes) host the set of leaves that depend on them.

### Eagerness

I have set the program to lazy initialization by default, which means the tree
won't really exist until you start requesting values from it. Here is a comparison
with 6-character lower-case alphabetic IDs:

```
lazy,        init                                  3 μs and 6 hnsecs
lazy,    generate                                  11 μs
lazy,   traversal                                  403 μs
eager,       init                                  5 secs, 437 μs, and 2 hnsecs
eager,   generate                                  6 μs and 3 hnsecs
eager,  traversal                                  680 ms, 164 μs, and 8 hnsecs
```

### Other notes 

- There is a single shared list of possible characters.
- I make full use of the GC because I am weak.