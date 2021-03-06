## 1. loading data table
# source('ui_tab_1_loading.R')
width_sidebar <- 3

tab_loading <- tabPanel("Load data",
    # 1.1 loading data
    fluidRow(
        column(width_sidebar + 2, 
            h3('1.1 load data'),         
            radioButtons("file_type", "file type:", 
                choices = c("text", "RData"), 
                selected = "text"),
            conditionalPanel(condition = "input.file_type == 'text'",
                shinyFilesButton('file_veg_text', 
                    label='File of vegetation time-series (file_veg_text):', 
                    "File of vegetation time-series (file_veg_text):", multiple=FALSE),
                br(),
                shinyFilesButton('file_site', 
                    label='File of site information (file_site):', 
                    "File of site information (file_site):",, multiple=FALSE)
            ),
            conditionalPanel(condition = "input.file_type == 'RData'",
                shinyFilesButton('file_veg_rda', label='File select', 
                    "RData of vegetation time-series and site information (file_veg_rda):",, multiple=FALSE)
            ),
            numericInput("nptperyear", "nptperyear:", options$nptperyear, 12, 366, 1),
            actionButton('load_data', 'Load Data'),

            ## 1.2 check_input
            h3('1.2 check_input'),
            selectInput("var_y", "vairable of vegetation index", 
                choices = options$var_y), #select_var_VI(df), 
                # selected = select_var_VI(df)[1]),
            checkboxInput("is_QC2w", "Convert QC to weight?", FALSE),
            conditionalPanel(condition = "input.is_QC2w", 
                textInput("var_qc", "vairable of QC:", options$var_qc),
                selectInput(
                    "qcFUN", "function of initializing weights according to QC (qcFUN):",
                    choices = c("qc_summary", "qc_5l", "qc_StateQA", "qc_NDVIv4"),
                    selected = "qc_summary"
                )
            ), 
            actionButton('pre_process', 'Pre-process')
        ),
        column(6, 
            # verbatimTextOutput("console_phenoMetrics", "help info")
            br(), br(),
            h3(em("If no input data assigned, the default is Eddy covariance daily GPP data.", 
                style="color:red")),
            br(), br(), br(), 
            conditionalPanel(condition = "input.file_type == 'text'", 
                strong("File of vegetation time-series:"),
                p(code('file_veg_text'), " should have the column of 'site', 'y', 't', and 'w' (optional).", tags$br(), 
                    "site is site name (string) or site id (numeric).", tags$br(),
                    "If w is missing, weights of all points are 1.0."),
                br(),
                strong("File of vegetation time-series:"),
                p(code('file_site'), " should have the column of ", 
                    "'site' (string or numeric), 'lat (double)'. ", tags$br(), 
                    "IGBPname (string), 'ID (numeric)' are optional.")
            ),
            conditionalPanel(condition = "input.file_type == '.rda | .RData'", 
                strong("RData of vegetation time-series and site information:"),
                p(code('file_veg_rda'), "should have the variable of ", 
                    code("df"), " (data.frame of vegetation time-series) and ",
                    code("st"), " (data.frame of site information)."), 
                br(),
                p(code('df'), " should have the column of 'site', 'y', 't', and 'w' (optional).", tags$br(),  
                    "If w is missing, weights of all points are 1.0."),
                p(code('st'), " should have the column of ", 
                    "'ID (numeric)', 'site (string)', 'lat (double)'. ", tags$br(), 
                    "IGBPname (string) is optional.")
            )
        )
    ), 

    br(), 
    fluidRow(
        # 2.3 preview input data
        hr(),
        h3("1.1 Vegetation time-series:"),
        DT::dataTableOutput("t_input_veg", width = "50%"), 
        
        h3("1.2 Site information:"),
        DT::dataTableOutput("t_input_site", width = "50%")
    )
)
