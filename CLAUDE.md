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

The test pier is running at http://localhost:80, with its dojo
attached to the tmux target `oxal:ship`.

Helper scripts (all wrap `.dojo.sh`, which sends a command to the
tmux dojo and returns its output):

- `sh .commit.sh` — rsync the source tree into the dev desk and
  `|commit %oxal`. Run after editing any file in the repo.
- `sh .run.sh "<dojo-command>"` — run an arbitrary dojo command on
  the test ship without syncing (e.g. `sh .run.sh "|hi ~zod"`).
- `sh .doctest.sh` — `.commit.sh` plus a GET to `/oxal/doctest` to
  run the doctest suite and print its response.
- `sh .dojo.sh <session:window> <timeout> <cmd> [--sync=<pier>]` —
  the underlying primitive; reach for it only when the wrappers
  don't fit (different ship, custom timeout, etc.).

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
