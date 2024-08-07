#' Transform 'NCycDB' or 'PCycDB' metagenomic abundance to 'microtable' object.
#'
#' @description
#' Transform 'NCycDB' or 'PCycDB' metagenomic abundance to microtable object. 
#'   The function can identify the mapping database according to the gene names of input feature abundance table.
#'   Reference: Qichao et al. (2019) <doi: 10.1093/bioinformatics/bty741> and Zeng et al. (2022) <doi: 10.1186/s40168-022-01292-1>.
#' @param feature_table 'NCycDB' or 'PCycDB' output abundance table, see the example file.
#' @param sample_table default NULL; sample metadata table; If provided, must be one of the several types of formats: 
#'   1) comma seperated file with the suffix csv or tab seperated file with suffix tsv/txt; 
#'   2) Excel type file with the suffix xlsx or xls; require \code{readxl} package to be installed; 
#'   3) \code{data.frame} object from R.
#' A file path must be tab or comma seperated file, generally, a file with suffix "tsv" or "csv".
#' @param match_table default NULL; a two column table used to replace the sample names in abundance table; Must be two columns without column names;
#'    The first column must be raw sample names same with those in feature table, 
#'    the second column must be new sample names same with the rownames in sample_table; Please also see the example files.
#' A file path must be tab or comma seperated file, e.g. a file with suffix "tsv" or "csv".
#' @param ... parameter passed to microtable$new function of microeco package, such as auto_tidy parameter.
#' @return microtable object.
#' @examples
#' \donttest{
#' # NCycDB
#' abund_file_path <- system.file("extdata", "example_Ncyc_table.tsv", package="file2meco")
#' sample_file_path <- system.file("extdata", "example_metagenome_sample_info.tsv", 
#'   package="file2meco")
#' match_file_path <- system.file("extdata", "example_metagenome_match_table.tsv", package="file2meco")
#' library(microeco)
#' library(file2meco)
#' library(magrittr)
#' ncyc2meco(abund_file_path)
#' test <- ncyc2meco(abund_file_path, sample_table = sample_file_path, 
#'   match_table = match_file_path)
#' test$tidy_dataset()
#' # use split_group = TRUE to calculate the pathway abundance with multipe map correspondance
#' test$cal_abund(select_cols = 1, rel = TRUE, split_group = TRUE, split_column = "Pathway")
#' test$taxa_abund$Pathway %<>% .[!grepl("unclass", rownames(.)), ]
#' test1 <- trans_abund$new(test, taxrank = "Pathway")
#' test1$plot_bar(bar_full = FALSE)
#' # for gene abundance, no splitting on the Pathway
#' test$cal_abund(select_cols = 1:2, rel = TRUE, split_group = FALSE)
#' test$taxa_abund$Gene %<>% .[!grepl("unclass", rownames(.)), ]
#' test1 <- trans_abund$new(test, taxrank = "Gene")
#' test1$plot_bar(bar_full = FALSE)
#' 
#' # PCycDB
#' abund_file_path <- system.file("extdata", "example_Pcyc_table.tsv", package="file2meco")
#' test <- ncyc2meco(abund_file_path)
#' test$tidy_dataset()
#' # show pathway abundance
#' test$cal_abund(select_cols = 1, rel = TRUE, split_group = TRUE, split_by = "&&", 
#'     split_column = "Pathway")
#' test$taxa_abund$Pathway %<>% .[!grepl("unclass|Others", rownames(.)), ]
#' test1 <- trans_abund$new(test, taxrank = "Pathway")
#' test1$plot_bar(bar_full = FALSE)
#' # show gene abundance
#' test$cal_abund(select_cols = 2, rel = TRUE, split_group = FALSE)
#' test$taxa_abund$Gene %<>% .[!grepl("unclass", rownames(.)), ]
#' test1 <- trans_abund$new(test, taxrank = "Gene")
#' test1$plot_bar(bar_full = FALSE)
#' }
#' @export
ncyc2meco <- function(feature_table, sample_table = NULL, match_table = NULL, ...){
	# first check func_data file format.
	abund_raw <- read.delim(feature_table, row.names = 1, comment.char = "#", stringsAsFactors = FALSE, check.names = FALSE)
	feature_names <- rownames(abund_raw)
	
	seq_num <- readLines(feature_table)[1]
	seq_num <- as.numeric(gsub(".*\\s(\\d+).*$",  "\\1", seq_num))
	
	# recalculate the abundance for unclassified
	unclassified <- seq_num - apply(abund_raw, 2, sum)
	abund_new <- rbind.data.frame(abund_raw, unclassified = unclassified)

	# first check the match_table
	if(!is.null(match_table)){
		abund_new <- check_match_table(match_table = match_table, abund_new = abund_new)
	}
	# read sample metadata table
	if(!is.null(sample_table)){
		sample_table <- check_sample_table(sample_table = sample_table)
	}
	
	data("ncyc_map", envir = environment())
	if(any(feature_names %in% rownames(ncyc_map))){
		mapping_file <- ncyc_map
	}else{
		data("pcyc_map", envir = environment())
		if(any(feature_names %in% rownames(pcyc_map))){
			mapping_file <- pcyc_map
		}else{
			stop("Unknow input feature type! Neither NCycDB nor PCycDB!")
		}
	}
	
	dataset <- microtable$new(otu_table = abund_new, tax_table = mapping_file, sample_table = sample_table, ...)
	dataset
}
