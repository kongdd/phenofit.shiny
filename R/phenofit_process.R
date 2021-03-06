#' @name phenofit_process
#' @title phenofit_process
NULL

# Select the data of specific site. Only those variables \code{c('t', 'y', 'w')} selected.
#' @param df data.table of vegetation time-series. At least with the columns of
#' `t, y, w`.
#' @param sitename character
#'
#' @rdname phenofit_process
#' @export
getsite_data  <- function(df, sitename, dateRange = NULL){
    d <- dplyr::select(df[site == sitename, ], dplyr::matches("t|y|w|QC_flag"))
    # if has no \code{QC_flag}, it will be generated by \code{w}.

    # filter dateRange
    if (!(missing(dateRange) || is.null(dateRange))) {
        bandname <- intersect(c("t", "date"), colnames(d))[1]
        dates    <- d[[bandname]]
        I <- dates >= dateRange[1] & dates <= dateRange[2]
        d <- d[I, ]
    }
    d
    #%T>% plot_input(365)
}

#' @param st data.table of site information, e.g. `site`, `lat`.
#' @inheritParams phenofit::check_input
#'
#' @rdname phenofit_process
#' @export
getsite_INPUT <- function(df, st, sitename, nptperyear, dateRange = NULL){
    if (is.null(df) || is.null(st)) return(NULL)

    sp_point <- st[site == sitename, ]
    south    <- sp_point$lat < 0
    name     <- sp_point$name %>% {ifelse(is.null(.), "", paste0(", ", .))}
    IGBP     <- sp_point$IGBP %>% {ifelse(is.null(.), "", paste0(., ", "))}

    titlestr <- sprintf("[%s%s] %s lat = %.2f", sitename, name, IGBP, sp_point$lat)
    d <- getsite_data(df, sitename, dateRange)

    dnew     <- add_HeadTail(d, south = south, nptperyear = nptperyear)
    INPUT    <- check_input(dnew$t, dnew$y, dnew$w, QC_flag = dnew$QC_flag,
        nptperyear = nptperyear, south = south,
        maxgap = nptperyear/4, alpha = 0.02,
        wmin = 0.6, ymin = 0.1)

    INPUT$titlestr <- titlestr
    INPUT
}

#' phenofit_season
#'
#' @description
#' * `phenofit_season`: Calculate growing season dividing information
#' * `phenofit_finefit`: Fine fitting
#'
#' @param INPUT An object returned by `check_input`
#' @param options options of phenofit
#' @param IsPlot whether to plot season dividing procedure?
#' @param verbose boolean. Whether print parameters of `season_mov` or `season`?
#' @param ... other parameters to [season_mov()] or [season()]
#'
#' @return same object returned by [season_mov()] and [season()]
#'
#' @importFrom utils str
#' @export
phenofit_season <- function(INPUT, options, IsPlot = FALSE, verbose = TRUE, ...)
{
    param <- list(
        FUN_season     = options$FUN_season,
        rFUN           = options$FUN_rough,
        wFUN           = options$wFUN_rough,
        iters          = options$iters_rough,
        lambda         = options$lambda,
        nf             = options$nf,
        frame          = options$frame,
        maxExtendMonth = options$max_extend_month_rough,
        rtrough_max    = options$rtrough_max,
        r_max          = options$r_max,
        r_min          = options$r_min,
        calendarYear   = options$calendarYear,
        # caution about the following parameters
        minpeakdistance   = INPUT$nptperyear/6,
        MaxPeaksPerYear   = 3,
        MaxTroughsPerYear = 4,
        IsPlot            = FALSE,
        IsPlot.OnlyBad    = FALSE,
        ypeak_min         = 0.1,
        print             = FALSE,
        ...
    )

    if (verbose){
        fprintf("----------------------------------\n")
        fprintf("Growing season dividing parameters:\n")
        fprintf("----------------------------------\n")
        print(str(param, 1))
    }

    FUN_season <- get(param$FUN_season)
    param <- param[-1]

    if (!is.function(param$rFUN)) param$rFUN %<>% get()
    if (!is.function(param$wFUN)) param$wFUN %<>% get()

    # print(sprintf('nptperyear = %d', INPUT$nptperyear))
    # param <- lapply(varnames, function(var) input[[var]])
    param <- c(list(INPUT = INPUT), param)
    brks <- do.call(FUN_season, param) # brk return

    if (IsPlot){
        abline(h = 1, col = "red")
        title(INPUT$titlestr)
    }
    return(brks)
}

#' @param INPUT An object returned by `check_input`
#' @param brks object returned by [season_mov()] and [season()]
#' @inheritParams phenofit::get_pheno
#'
#' @rdname phenofit_process
#' @export
phenofit_finefit <- function(INPUT, brks, options,
    TRS = c(0.2, 0.5, 0.6), ...)
{
    param <- list(
        INPUT, brks,
        iters          = options$iters_fine,
        methods        = options$FUN_fine, #c("AG", "zhang", "beck", "elmore", 'Gu'), #,"klos",
        verbose        = FALSE,
        wFUN           = options$wFUN_fine,
        nextend        = options$nextend_fine,
        maxExtendMonth = options$max_extend_month_fine,
        minExtendMonth = 1,
        minPercValid   = 0.2,
        print          = FALSE,
        use.rough      = options$use.rough
    )
    if (!is.function(param$wFUN)) param$wFUN %<>% get()

    fit  <- do.call(curvefits, param)

    params <- get_param(fit)
    stat   <- get_GOF(fit)                   # Goodness-Of-Fit
    pheno  <- get_pheno(fit, TRS = TRS, IsPlot=FALSE)   # Phenological metrics

    list(fit = fit, INPUT = INPUT, seasons = brks,
        param = params, stat = stat, pheno = pheno)
}

#' phenofit_process
#'
#' @inheritParams setting
#' @param dateRange Date vector, `[date_begin, date_end]`. filter input in the
#' range of `dateRange`
#' @param nsite the max number of sites to process. `-1` means all sites.
#' @param .progress boolean
#' @param .parallel boolean
#' @param ... ignored
#'
#' @rdname phenofit_process
#' @examples
#' \dontrun{
#' file_json <- system.file('shiny/phenofit/perference/phenofit_setting.json', package = "phenofit")
#' options <- setting.read(file_json)
#' r <- phenofit_process(options, nsite=2)
#' }
#' @export
phenofit_process <- function(
    options,
    dateRange = c(as.Date('2010-01-01'), as.Date('2014-12-31')),
    nsite = -1,
    .progress = NULL, .parallel = FALSE,
    ...)
{
    showProgress <- !is.null(.progress) # this for shinyapp progress
    if (showProgress){
        on.exit(.progress$close())
        .progress$set(message = sprintf("phenofit (n=%d) | running ", n), value = 0)
    }

    rv    <- phenofit_loaddata(options, ...)
    sites <- rv$sites

    n     <- length(sites)
    if (nsite > 0) n <- pmin(n, nsite)

    FUN <- ifelse(.parallel, `%dopar%`, `%do%`)
    res <- FUN(foreach(i = 1:n, sitename = sites), {
        # sitename <- rv$sites[i]
        if (showProgress){
            .progress$set(i, detail = paste("Doing part", i))
        }
        fprintf("phenofit (n = %d) | running %03d ... \n", i, n)

        tryCatch({
            INPUT <- with(rv, getsite_INPUT(df, st, sitename, nptperyear, dateRange))
            brks  <- phenofit_season(INPUT, options, IsPlot = FALSE)
            fits  <- phenofit_finefit(INPUT, brks, options) # multiple methods
            fits
        }, error = function(e){
            message(sprintf('[e] phenofit_process, site=%s: %s', sitename, e$message))
        }, warning = function(w){
            message(sprintf('[w] phenofit_process, site=%s: %s', sitename, w$message))
        })
    })

    ############################# CALCULATION FINISHED #####################
    set_names(res, sites[1:n])
}

#' get_date_AVHRR
#'
#' Generate image dates from `year_begin` to `year_end`.
#' This function is only for AVHRR satellites.
#'
#' @param year_begin integer
#' @param year_end integer
#'
#' @importFrom lubridate days_in_month
#' @export
#'
#' @examples
#' date_AVHRR <- get_date_AVHRR()
get_date_AVHRR <- function(year_begin = 1982, year_end = 2015){
    dates <- seq(ymd(year_begin*1e4 + 0101), ymd(year_end*1e4 + 1231), "month")
    days  <- dates %>% days_in_month()

    dates_a <- dates + ddays(floor(days/4))
    dates_b <- dates + ddays(floor(days/4*3))
    dates <- c(dates_a, dates_b) %>% sort()

    d_dates <- data.table(I = seq_along(dates),
        date = dates, month = month(dates), dom = day(dates), doy = yday(dates))
    d_dates
}
