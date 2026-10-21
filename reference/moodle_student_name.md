# Student name from a Moodle submission folder

Moodle's "Download all submissions" names each folder
`<Full name>_<id>_assignsubmission_file`. This keeps the full name. With
blind marking every folder starts with "Participant", so names clash and
[`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
falls back to the folder names.

## Usage

``` r
moodle_student_name(folder)
```

## Arguments

- folder:

  Character. Submission folder name.

## Value

Character. Display name.

## Examples

``` r
moodle_student_name("Juan Perez_123456_assignsubmission_file")
#> [1] "Juan Perez"
```
