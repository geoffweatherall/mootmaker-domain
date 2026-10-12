# mootmaker-domain

DNS and mail identity for `mootmaker.com`: the Route 53 hosted zone and its query logging, the apex
redirect, and the SES identity for `mail.mootmaker.com`.

**Read [README.md](README.md) first.** Keep it true in the same pull request as any change that affects it.

## Working here

- **There is one deployment, serving every environment.** `deploy.sh` takes no environment argument.
- **A change here reaches production immediately**, including the public demo, and there is no copy to try
  it on. Read `terraform plan` before deploying.
- **Every environment depends on this zone and this mail identity.** Breaking either breaks sign-in email,
  certificates or DNS everywhere at once.
- **`undeploy.sh` takes down DNS for the whole project.** Never run it without being asked.
- **Other repositories find these resources with `data` sources by name**, not by reading this
  repository's state. Renaming the zone or the mail domain breaks them.

---

## Project-wide rules

This repository is part of **Mootmaker**. The hub repository, checked out as a sibling at
`../mootmaker`, holds what applies everywhere:

- How work is done: [`../mootmaker/docs/process/README.md`](https://github.com/geoffweatherall/mootmaker/blob/main/docs/process/README.md).
  Read it before any non-trivial work.
- How the system fits together: [`../mootmaker/docs/overview/`](https://github.com/geoffweatherall/mootmaker/tree/main/docs/overview).
- What to do when something is wrong: [`../mootmaker/docs/runbooks/`](https://github.com/geoffweatherall/mootmaker/blob/main/docs/runbooks/README.md).

The short version:

- Work of any real size starts with a **design** (`../mootmaker/designs/`); a bug or small change starts
  with a **GitHub issue in this repository**, so `Closes #N` works.
- Everything lands on a **branch** through a **pull request**. Reading the diff is the review; merging is
  the approval.
- **A green acceptance run against a real deployed environment** is the definition of working.
- **`test` and `production` change only through a release** (`release.yml` in mootmaker-release). Use an
  ephemeral environment for your own work, and tear it down when you finish.
- **Say what something costs in AWS before creating it.** Under NZ$1 one-off, go ahead and state it;
  more, or anything recurring, ask first.
- **Keep documentation and comments true and current.** If a change makes a document wrong, fixing it is
  part of the change. Describe what is, not how it got here; a comment says what and why.
- **Verify against reality, not your own output**, and **say what actually happened**, including
  failures and skipped steps.

Something not installed? [`../mootmaker/tools/workstation/check.sh`](https://github.com/geoffweatherall/mootmaker/blob/main/tools/workstation/check.sh).

`CLAUDE.md` in this repository is a symlink to this file.
