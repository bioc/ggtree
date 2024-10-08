##' drawing phylogenetic tree from phylo object
##'
##'
##' @title ggtree
##' @inheritParams geom_tree
##' @param tr phylo object
##' @param open.angle open angle, only for 'fan' layout
##' @param mrsd most recent sampling date
##' @param as.Date logical whether using Date class in time tree
##' @param yscale y scale
##' @param yscale_mapping yscale mapping for category variable
##' @param ladderize logical (default `TRUE`). Should the tree be re-organized to have a 'ladder'
##' aspect?
##' @param right logical. If `ladderize = TRUE`, should the ladder have the smallest clade on the
##' right-hand side? See [ape::ladderize()] for more information. 
##' @param branch.length variable for scaling branch, if 'none' draw cladogram
##' @param root.position position of the root node (default = 0)
##' @param xlim x limits, only works for 'inward_circular' layout
##' @param layout.params list, the parameters of layout, when layout is a function.
##' \code{as.graph=TRUE} and \code{layout} is a function, the coordinate will be re-calculated 
##' as a \code{igraph} object, if \code{as.graph=FALSE} and \code{layout}, the coordinate will be
##' re-calculated keep original object \code{phylo} or \code{treedata}. 
##' @param hang numeric The fraction of the tree plot height by which labels should hang 
##' below the rest of the plot. A negative value will cause the labels to hang down from 0. This
##' parameter only work with the 'dendrogram' layout for 'hclust' like class, default is 0.1.
##' @return tree
##' @importFrom ggplot2 ggplot
##' @importFrom ggplot2 xlab
##' @importFrom ggplot2 ylab
##' @importFrom ggplot2 annotate
##' @importFrom ggplot2 scale_x_reverse
##' @importFrom ggplot2 ylim
##' @importFrom ggplot2 coord_flip
##' @importFrom ggplot2 coord_polar
##' @export
##' @author Yu Guangchuang
##' @seealso [geom_tree()]
##' @references 1. G Yu, TTY Lam, H Zhu, Y Guan (2018). Two methods for mapping and visualizing associated data
##' on phylogeny using ggtree. Molecular Biology and Evolution, 35(2):3041-3043.
##' <https://doi.org/10.1093/molbev/msy194>
##'
##' 2. G Yu, DK Smith, H Zhu, Y Guan, TTY Lam (2017). ggtree: an R package for
##' visualization and annotation of phylogenetic trees with their covariates and
##' other associated data. Methods in Ecology and Evolution, 8(1):28-36.
##' <https://doi.org/10.1111/2041-210X.12628>
##'     
##' For more information, please refer to 
##' *Data Integration, Manipulation and Visualization of Phylogenetic Trees*
##' <http://yulab-smu.top/treedata-book/index.html> by Guangchuang Yu.
##' @examples
##' require(ape) 
##' tr <- rtree(10)
##' ggtree(tr)
ggtree <- function(tr,
                   mapping        = NULL,
                   layout         = "rectangular",
                   open.angle     = 0,
                   mrsd           = NULL,
                   as.Date        = FALSE,
                   yscale         = "none",
                   yscale_mapping = NULL,
                   ladderize      = TRUE,
                   right          = FALSE,
                   branch.length  = "branch.length",
                   root.position  = 0,
                   xlim = NULL,
                   layout.params = list(as.graph = TRUE),
                   hang = .1,
                   ...) {

    # Check if layout string is valid.
    trash <- try(silent = TRUE,
                 expr = {
                   layout %<>% match.arg(c("rectangular", "slanted", "fan", "circular", 'inward_circular',
                            "radial", "unrooted", "equal_angle", "daylight", "dendrogram",
                            "ape", "ellipse", "roundrect"))
                  }
             )

    dd <- .check.graph.layout(tr, trash, layout, layout.params)
    if (inherits(trash, "try-error") && !is.null(dd)){
        layout <- "rectangular"
    }

    if (layout == "unrooted") {
        layout <- "daylight"
        message('"daylight" method was used as default layout for unrooted tree.')
    }

    if(yscale != "none") {
        ## for 2d tree
        layout <- "slanted"
    }

    if (is.null(mapping)) {
        mapping <- aes_(~x, ~y)
    } else {
        mapping <- modifyList(aes_(~x, ~y), mapping)
    }

    p <- ggplot(tr,
                mapping       = mapping,
                layout        = layout,
                mrsd          = mrsd,
                as.Date       = as.Date,
                yscale        = yscale,
                yscale_mapping= yscale_mapping,
                ladderize     = ladderize,
                right         = right,
                branch.length = branch.length,
                root.position = root.position,
                hang          = hang,
                ...)

    if (!is.null(dd)){
        message_wrap("The tree object will be displayed with external layout function
                     since layout argument was specified the graph layout or other layout
                     function.")
        p$data <- dplyr::left_join(
                    p$data %>% select(-c("x", "y")), 
                    dd, 
                    by = "node"
        )
        layout <- "equal_angle"
    }

    if (is(tr, "multiPhylo")) {
        multiPhylo <- TRUE
    } else {
        multiPhylo <- FALSE
    }

    p <- p + geom_tree(layout=layout, multiPhylo=multiPhylo, ...)


    p <- p + theme_tree()

    if (layout == "circular" || layout == "radial") {
        p <- p + layout_circular()
    } else if (layout == 'inward_circular') {
        p <- p + layout_inward_circular(xlim = xlim)
    } else if (layout == "fan") {
        p <- p + layout_fan(open.angle)
    } else if (layout == "dendrogram") {
        p <- p + layout_dendrogram()
    } else if (layout %in% c("daylight", "equal_angle", "ape")) {
        p <- p + ggplot2::coord_fixed()
        d <- p$data
        pn <- d[d$parent, ]
        dy <- pn$y - d$y
        dx <- pn$x - d$x
        angle <- atan2(dy, dx) * 180 / pi + 180
        p$data$angle <- angle
    } else if (yscale == "none") {
        p <- p +
            scale_y_continuous(expand = expansion(0, 0.6))
    }

    class(p) <- c("ggtree", class(p))

    return(p)
}


ggtree_citations <- function() {
    paste0('1. ',
           "Guangchuang Yu. ",
           "Using ggtree to visualize data on tree-like structures. ",
           "Current Protocols in Bioinformatics. 2020, 69:e96. doi:10.1002/cpbi.96\n",
           
           '2. ',
           "Guangchuang Yu, Tommy Tsan-Yuk Lam, Huachen Zhu, Yi Guan. ",
           "Two methods for mapping and visualizing associated data on phylogeny using ggtree. ",
           "Molecular Biology and Evolution. 2018, 35(12):3041-3043. doi:10.1093/molbev/msy194\n",
           
           # '\033[36m', '-', '\033[39m ',
           "3. ",
           "Guangchuang Yu, David Smith, Huachen Zhu, Yi Guan, Tommy Tsan-Yuk Lam. ",
           "ggtree: an R package for visualization and annotation of phylogenetic trees with their covariates and other associated data. ",
           "Methods in Ecology and Evolution. 2017, 8(1):28-36. doi:10.1111/2041-210X.12628\n"
           )
}


ggtree_references <- function() {
    paste0(ggtree_citations(), "\n",
           "For more information, please refer to the online book:",
           "Data Integration, Manipulation and Visualization of Phylogenetic Trees.",
           "<http://yulab-smu.top/treedata-book/>\n"
           )
}

.check.graph.layout <- function(obj, trash, layout, layout.params){
    if (inherits(trash, "try-error")){
        if (!"as.graph" %in% names(layout.params)){
            layout.params$as.graph <- TRUE
        }
        if (layout.params$as.graph){
            obj <- ape::as.igraph.phylo(as.phylo(obj), use.labels = FALSE)
        }
        #dd <- ggraph::create_layout(gp, layout = layout)
        if (is.function(layout)){
            layout.params$as.graph <- NULL
            dd <- do.call(layout, c(list(obj), layout.params))
            if (!inherits(dd, "matrix")){
                if ("xy" %in% names(dd)){
                    dd <- dd$xx
                }else if ("layout" %in% names(dd)){
                    dd <- dd$layout
                }else if (inherits(dd, "data.frame") && nrow(dd)>2){
                    dd <- dd[,seq(2)]
                }else{
                    stop(trash, call. = FALSE)
                }
            }
            dd <- data.frame(dd)
            colnames(dd) <- c("x", "y")
            dd$node <- seq_len(nrow(dd))
        }else{
            stop(trash, call. = FALSE)
        }
    }else{
        dd <- NULL
    }
    return(dd)
}
