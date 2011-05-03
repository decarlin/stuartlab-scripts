\name{usage}
\alias{usage}
\title{ Prints a usage statement }
\description{
  Prints a usage statement, given an argument specification and a
  function to explain the argument types.
}
\usage{
usage(reason, argspec, argMap=parseArgMap(argspec), argValMap = defaultArgValueMap(), finish = q())
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{reason}{ The reason for printing usage (i.e. parse error) }
  \item{argspec}{ The full argument specification }
  \item{argMap}{ A parsed argument specification }
  \item{argValMap}{ The mapping of argument value types to descriptions}
  \item{finish}{ What to do when finished }
}
\details{
  This prints out a usage statement, and by default, exits.
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu
}
\keyword{ utilities }
