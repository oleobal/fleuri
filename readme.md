# Fluri

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

So if we weight the random branch selection process using this data, we can favour
the branches that have the most free IDs.