\name{stdoutIsTTY}
\alias{stdoutIsTTY}
\title{ Determine if stdout is attached to a terminal device }
\description{
Determine if stdout is attached to a terminal device
}
\usage{
stdoutIsTTY()
}
\details{
  This variable requires the use of Rgetopt.py to set the environment
  variable RGETOPT\_ISATTY with the results of the system call.
}
\value{
  Returns \code{TRUE} if stdout() is a terminal, \code{FALSE} otherwise.
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\keyword{ utilities }
