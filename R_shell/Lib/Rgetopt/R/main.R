parseString <- function(string) string

parseInteger <- function(string) {
  i <- suppressWarnings(as.integer(string))
  if (!is.na(i) && i == string) return(as.integer(string))
  else return(NULL)
}

parseFloat <- function(string) {
  if (!is.na(suppressWarnings(as.double(string)))) return(as.double(string))
  else return(NULL)
}

parseIntegerList <- function(string) {
  l <- try(eval(parse(text=paste("c(",string,")"))), silent=TRUE)
  if ("try-error" %in% class(l)) return(NULL)
  if (!is.numeric(l)) return(NULL)
  if (any(as.integer(l) != l, na.rm=T)) return(NULL)
  return(as.integer(l))
}

parseFloatList <- function(string) {
  l <- try(eval(parse(text=paste("c(",string,")"))), silent=TRUE)
  if ("try-error" %in% class(l)) return(NULL)
  if (is.numeric(l)) return(l)
  else return(NULL)
}

parseStringList <- function(string) {
  return(unlist(strsplit(string, ",")))
}

parseStringListSpace <- function(string) {
  return(unlist(strsplit(string, " ")))
}

parseReadableFile <- function(string) {
  if (string == '-') return(file("stdin"))
  f <- try(file(string, open="r"))
  if ("try-error" %in% class(f)) return(NULL)
  return(f)
}

parseWriteableFile <- function(string) {
  if (string == '-') return(stdout())
  f <- try(file(string, open="w"))
  if ("try-error" %in% class(f)) return(NULL)
  return(f)
}

defaultArgValueMap <- function(...) {
  extra <- list(...)
  m <- list(s=list(parse=parseString,desc="<string>"),
            i=list(parse=parseInteger, desc="<integer>"),
            f=list(parse=parseFloat, desc="<float>"),
            li=list(parse=parseIntegerList, desc="<integer list>"),
            lf=list(parse=parseFloatList, desc="<float list>"),
            ls=list(parse=parseStringList, desc="<string list>"),
            lss=list(parse=parseStringListSpace,
              desc="<space delimited string list>"),
            rfile=list(parse=parseReadableFile,
              desc="<readable file or pipe>"),
            wfile=list(parse=parseWriteableFile,
              desc="<writable file or pipe>"))
  if (length(extra) > 0) {
    if (is.null(names(extra)) || any(is.na(extra))
        || any(nchar(names(extra)) == 0)) {
      stop("names not set for extra argument values")
    }
    m[names(extra)] <- extra
  }
  for (a in names(extra)) {
    stopifnot(all(names(extra[[a]]) == c("parse", "desc")))
    stopifnot(is.function(extra[[a]]$parse))
    stopifnot(is.character(extra[[a]]$desc))
    stopifnot(length(extra[[a]]$desc) == 1)
  }
  return(m)
}

Rgetopt <- function(...,
                    argspec=c(...),
                    argv=RgetArgvEnvironment()[-1],
                    argMap=parseArgMap(argspec),
                    onerror=function(x) usage(x,argspec=argspec,argMap=argMap),
                    argValMap=defaultArgValueMap(),
                    defaults) {
  description <- argspec[1]
  options <- vector(length(argMap$description), mode="list")
  names(options) <- names(argMap$description)
  if (!missing(defaults)) options[names(defaults)] <- defaults

  i <- 1
  while (i <= length(argv)) {
    if (argv[i] %in% c('--help')) usage('', argspec=argspec, argMap=argMap)
    if (argv[i] == '--') {
      # stop parsing arguments
      i <- i + 1
      break
    }
    flag <- sub("^--?", "", argv[i])
    if (argv[i] == '-' || flag == argv[i]) {
      # encountered a non-argument, time to stop parsing
      break
    }
    flag <- argMap$map[flag]
    if (is.null(flag) || is.na(flag)) {
      onerror(paste("Unknown flag:", argv[i]))
    }
    if (argMap$value[flag] != "") {
      i <- i + 1
      if (i > length(argv)) {
        onerror(paste("Need an argument for option", argv[i-1]))
      }
      valtype <- argValMap[[match.arg(argMap$value[flag], names(argValMap))]]
      val <- valtype$parse(argv[i])
      if (is.null(val)) {
        onerror(paste("Couldn't parse a", valtype$desc, "from", argv[i]))
      }
      options[[flag]] <- val
    } else {
      options[[flag]] <- TRUE
    }
    i <- i + 1
  }
  options$argv <- if (i > 1) argv[-(1:(i-1))] else argv
  return(options)
}
parseArgMap <- function(argspec) {
  # return a list with two elements
  #   map - a vector that's a mapping from alias to primary argument name
  #   value - a vector that's a mapping from primary argument to
  #   aliases - a list map from primary to alias names
  #   description - the description of the argument
  #   usage - the first entry in argspec, a general description of the command
  u <- argspec[1]
  argspec <- argspec[-1]
  d <- sub("[^ ]*[ ]*", "", argspec)
  spec <- sub(" .*$", "", argspec)
  value <- sub("[^=]*=?", "", spec)
  aliases <- strsplit(sub("=.*", "", spec), "\\|")
  primary <- sapply(aliases, "[", 1)

  names(d) <- primary
  names(value) <- primary
  names(aliases) <- primary

  map <- vector("character")
  for (i in seq(from=1, length.out=length(aliases))) {
    map[aliases[[i]]] <- primary[i]
  }
  return(list(map=map, value=value, aliases=aliases, description=d, usage=u))
}

usage <- function(reason, argspec, argMap=parseArgMap(argspec),
                  argValMap=defaultArgValueMap(), finish=q()) {
  if (!is.null(reason) && !is.na(reason) && nchar(reason) > 0) {
    cat(reason, "\n", sep='')
  }
  if (!missing(argspec) && !is.null(argMap)) {
    cat(argMap$usage, "\n", sep='')
    for(a in names(argMap$aliases)) {
      aliases <- argMap$aliases[[a]]
      prefix <- c('-', '--')[(nchar(aliases) > 1) + 1]
      v <- argMap$value[a]
      if (v != "") {
        v <- argValMap[[v]]$desc
      }
      v <- if (is.null(v)) "" else paste("", v)
      d <- argMap$description[a]
      cat("\n  ", paste(prefix, aliases, sep='', collapse=", "), v, "\n", sep='')
      if (nchar(d) > 0) {cat("      ", d, "\n", sep='')}
    }
  }
  finish()
}

RgetArgvEnvironment <- function() {
  argc <- as.integer(Sys.getenv("RGETOPT_ARGC"))
  if(is.na(argc) || argc < 1)
    stop("Invalid getopt setup: RGETOPT_ARGC not there")
  return(Sys.getenv(paste("RGETOPT_ARGV", 1:argc, sep="_")))
}

stdoutIsTTY <- function() {
  return(Sys.getenv("RGETOPT_ISATTY") == "1")
}

deferredStdOutFile <- function() {
  return(Sys.getenv("RGETOPT_STDOUTONEXIT"))
}
