---
name: Mimic
description: "Guidance on using Mimic in tests"
---

# Using Mimic for testing

## Setup

`use Mimic` should be added to the Case modules of the project to have mimic
available in all tests. This also adds some setup that makes sure mocks are
actually checked at the end of a test.

## Using Mimic

- We always want to use Mimic.expect to make sure we actually need the mocks.
- We don't want to use Mimic.stub because it hides problems
