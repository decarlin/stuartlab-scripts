\name{parseFloat}
\alias{parseString}
\alias{parseFloat}
\alias{parseInteger}
\alias{parseFloatList}
\alias{parseIntegerList}
\alias{parseStringList}
\alias{parseStringListSpace}
\alias{parseReadableFile}
\alias{parseWriteableFile}
\title{ Parse individual arguments into the appropriate type }
\description{
Parse individual arguments into the appropriate type
}
\usage{
parseString(string)
parseFloat(string)
parseInteger(string)
parseFloatList(string)
parseIntegerList(string)
parseStringList(string)
parseStringListSpace(string)
parseReadableFile(string)
parseWriteableFile(string)
}

\arguments{
  \item{string}{ The command line argument value }
}
\details{
  These functions convert a string to the desired type.

  Integer, float, and string lists sholud be separated by commas.
  Numeric ranges can be specified with colons.

  Files can be anything by R's \code{\link{file}}, including HTTP URLs
  and pipes.
}
\value{
  The desired conversion, or \code{NULL} if the conversion was not possible.
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\keyword{ utilities }
