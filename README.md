# R Submissions Pilot 5 ECTD Package

2025-08-22T12:35:29+00:00

> Do not include `README.md` and `.gitignore` files into the final
> submission.

## Overview

The objective of the R Consortium R Submission Pilot 3 Project is to
test the concept that an R-language based submission package can meet
the needs and the expectations of the FDA reviewers, including assessing
code review and analyses reproducibility. All submission materials and
communications from this pilot are publicly available, with the aim of
providing a working example for future R-language based FDA submissions.
This is an FDA-industry collaboration through the non-profit
organization R Consortium.

The
[RConsortium.submissions-pilot5-datasetjson-to-fda](https://github.com/RConsortium/submissions-pilot5-datasetjson-to-fda)
repository demonstrates the eCTD submission package based on the
[RConsortium.submissions-pilot5-datasetjson](https://github.com/RConsortium/submissions-pilot5-datasetjson)
repository.

The
[RConsortium.submissions-pilot5-datasetjson](https://github.com/RConsortium/submissions-pilot5-datasetjson)
repository demonstrates an approach to organized an R-language based
submission, including JSON data files as ADaM/SDTM data sets, tables,
and figures.

To learn more about other pilots, visit the [R Consortium R Submission
Working Group website](https://rconsortium.github.io/submissions-wg/)
and the [R Consortium Working Groups
webpage](https://www.r-consortium.org/all-projects/isc-working-groups).

## FDA Response

- Initial submission
  - version: \[v0.1.0\] (**link TBC**)
  - [Cover
    letter](https://github.com/RConsortium/submissions-pilot5-datasetjson-to-fda/blob/main/m1/us/cover-letter.pdf)
    (**Draft version**)

## Folder Structure

The folder is organized as a demo eCTD package following ICH guidance.

eCTD package:

- `m1/`: module 1 of the eCTD package

<!-- -->

    m1
    └── us
        ├── cover-letter.pdf  # Submission cover letter

- `m5/`: module 5 of the eCTD package

<!-- -->

    m5
    └── datasets
        └── rconsortiumpilot5
            ├── analysis
            │   └── adam
            │       ├── datasets
            │       │   ├── adadas.json
            │       │   ├── adae.json
            │       │   ├── adlbc.json
            │       │   ├── adrg.pdf
            │       │   ├── adsl.json
            │       │   └── adtte.json
            │       └── programs
            │           ├── adadas.r
            │           ├── adae.r
            │           ├── adlbc.r
            │           ├── adsl.r
            │           ├── adtte.r
            │           ├── pilot5-helper-fcns.r
            │           ├── renv-lock.txt
            │           ├── tlf-demographic.r
            │           ├── tlf-efficacy.r
            │           ├── tlf-kmplot.r
            │           └── tlf-primary.r
            └── tabulations
                └── sdtm
                    ├── ae.json
                    ├── cm.json
                    ├── dm.json
                    ├── ds.json
                    ├── ex.json
                    ├── lb.json
                    ├── mh.json
                    ├── qs.json
                    ├── relrec.json
                    ├── sc.json
                    ├── se.json
                    ├── suppae.json
                    ├── suppdm.json
                    ├── suppds.json
                    ├── supplb.json
                    ├── sv.json
                    ├── ta.json
                    ├── te.json
                    ├── ti.json
                    ├── tv.json
                    └── vs.json

Other files: (**Do not include in eCTD package**)

- `.gitignore`: git ignore file
- `README.md`: readme file for github repo

## News

The ECTD bundle and associated compiled application archive were last
rendered on 2025-08-22T12:35:29+00:00 .

## Questions

Report issues in
<https://github.com/RConsortium/submissions-pilot5-datasetjson/issues>
