\name{RgetArgvEnvironment}
\alias{RgetArgvEnvironment}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ Get the command line arguments from the environment }
\description{
Reads the command line arguments from environment variables
}
\usage{
RgetArgvEnvironment()
}
\details{
  This requires tha the environment variables \code{RGETOPT_ARGC} and
  corresponding \code{RGETOPT_ARGV_N} have been set.
}
\value{
  A character vector with all the command line arguments
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\examples{
}
\keyword{ utilities }
