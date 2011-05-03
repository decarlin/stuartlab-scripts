\name{Rgetopt-package}
\alias{Rgetopt-package}
\alias{Rgetopt}
\docType{package}
\title{
Parse command line options
}
\description{
Parse command line options, taken from environment variables or
elsewhere.  The library can correctly identify strings, numbers, files,
lists of numbers, and lists of files.  Additionally, this library will
print out usage statements.
}
\details{
\tabular{ll}{
Package: \tab Rgetopt\cr
Type: \tab Package\cr
Version: \tab 1.0\cr
Date: \tab 2008-02-24\cr
}
This package reads command line arguments from environment variables in
conjunction with the script \code{Rgetopt.py}.  It was modelled very
roughly on Perl's \code{Getopt::Long}.  It includes self-documenting
parameters, however, and by default will exit with a usage statement if
it encounters a problem while parsing the options.

See \code{\link{Rgetopt}} for documentation.
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\seealso{
\code{\link{Rgetopt}}, \code{\link[RCommandArgs]{RCommandArgs-package}}
}
\examples{

#!/usr/bin/env Rgetopt.py
#library(Rgetopt)

}
\keyword{ utilities }
