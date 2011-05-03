\name{deferredStdOutFile}
\alias{deferredStdOutFile}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ Where to write output that is sent to standard out after exiting }
\description{
  This provides a file name, that, when the script has completed, will
  have it's contents sent to stdout.  This is useful for sending binary
  output through a pipeline, as R can not natively write binary data to
  stdout().  
}
\usage{
deferredStdOutFile()
}
%- maybe also 'usage' for other objects documented here.
\details{
  The wrapper script Rgetopt.py creates a temorary file which will be
  sent to stdoud() after the completion of the executed script.
}
\value{
  A single element character variable with the name of the temporary file.
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\keyword{ utilities }
