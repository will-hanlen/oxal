# %oxal

## Specification

%oxal is a networked other than tests
reactive database.

There is a single tree of data.

An overlay tree stores metadata and defines cached transformations on other parts of the tree.

Each transformation is called a $view.
A $view is a pure function over the changelog of another location.

Like spreadsheets, $views chain together to create increasingly complex
transformations.


## Structure

- app/oxal.hoon - main agent
- lib/zozo.hoon - all zozo
- lib/zozo-0.hoon - types, tree engine, data engine, pith engine, parsers, printers
- lib/zozo-1.hoon - web utilities
- lib/zozo-2.hoon — file engine (`+fe`)
- lib/zozo-3.hoon — acer engine (`+ae`)


## Development Setup

The test pier is running at http://localhost:80.

After making a change to the source code, you can apply the change by
running: `sh .commit.sh`

To run an arbitrary dojo command on the test ship, run something
like: `sh .run.sh "|hi ~zod"`

## Style

- 2-space indent
- arm descriptions go below the arm name
  ```
  ++  some-arm
    ::
    ::  comment describing what the arm does
    ::
    %the-body-of-the-arm
    ::
  ```
