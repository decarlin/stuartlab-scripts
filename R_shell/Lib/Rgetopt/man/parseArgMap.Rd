\name{parseArgMap}
\alias{parseArgMap}
\title{Convert argument specification to a data structure }
\description{
  This converts a programmer-specified argument list to the data
  structure used internally for parsing arguments.
}
\usage{
parseArgMap(argspec)
}

\arguments{
  \item{argspec}{ The programmer specified argument list. }
}
\value{
  A list of the parsed argument specification.  It contains:
  \item{map}{character vector map from parameter aliases to the primary
  parameter name}
\item{value}{The expected value for each primary argument}
\item{aliases}{A list map from each primary argument name to all known
  aliases}
\item{description}{A character vector map from each primary argument
  name to the description of the parameter}
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\keyword{ utilities }
