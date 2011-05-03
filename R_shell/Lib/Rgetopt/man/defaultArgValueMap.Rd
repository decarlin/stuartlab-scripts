\name{defaultArgValueMap}
\alias{defaultArgValueMap}
\title{ Construct and add to the default argument value map }
\description{
  This provides the default argument value parsing and description
  map. This function can also add to or change the default values by
  specifying additional named pairs.
}
\usage{
defaultArgValueMap(...)
}

\arguments{
  \item{...}{ additional value types}
}
\details{
  This provides the default argument value parsing and description.
}
\value{
  A list, each element specifying the function for parsing an argument
  value type, and the description of that value type.  The string in the
  arg spec is the name of that element in the list.

  Very unclear, but value should be somewhat self documenting.  I'll
  gladly expand on this description if you write to me.
}
\author{
Charles Vaske <cvaske@soe.ucsc.edu>

Maintainer: Charles Vaske <cvaske@soe.ucsc.edu>
}
\keyword{ utilities }
