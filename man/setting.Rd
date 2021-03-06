% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setting.R
\name{setting}
\alias{setting}
\alias{setting.get}
\alias{setting.read}
\alias{setting.write}
\alias{setting.update}
\title{setting}
\usage{
setting.get(options, others = NULL, ...)

setting.read(file = "phenofit_setting.json")

setting.write(options, file = "phenofit_setting.json")

setting.update(options)
}
\arguments{
\item{options}{options of phenofit needed to export.}

\item{others}{options in others will override \code{options}.}

\item{...}{ignored.}

\item{file}{file path of phenofit setting file (json).}
}
\description{
setting

get parameters of phenofit shinyapp
}
\examples{
\dontrun{
pars = get_setting(options)
print(str(pars))
write_json(setting, "phenofit_setting.json", pretty = TRUE)
}
}
