# Image for grade_submissions(engine = "container"). Build it once:
#
#   docker build -t corrector-runner "$(Rscript -e 'cat(system.file("container", package = "corrector"))')"
#
# Add any package the students or the tests need to the install2.r line,
# because the container has no network while it grades.
FROM rocker/r-ver:4.4.1

RUN install2.r --error --skipinstalled callr testthat \
 && rm -rf /tmp/downloaded_packages
