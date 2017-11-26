# smalltt

Small type theory implementation. 

Currently, we have
  - Type-in-type
  - Higher-order unification
  - Bidirectional elaboration
  - Positional & named implicit arguments
  - Some control over metavariable insertion
  
Missing things which I'll perhaps add:

  - Acceptable number of examples
  - Acceptable docs
  - Acceptable error messages
  - Named holes which cause goal & assumption types to be displayed on file load
  - Type-annotated lambdas
  - Sigmas
  - More unification: pruning, intersections, eta-contractions, dependency erasure
  - Acceptable pretty printing with at least toggleable implcit args
  - Unreduced "glued" elaboration contexts, and what it enables: approximate conversion checks + better printed terms
  - Inductive-inductive types via eliminators
  
Non-goals
  - Noteworthy time/space optimizations for elaboration
  - Performant implementation & data structures
  - Universes
  - Modules
