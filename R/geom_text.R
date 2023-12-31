##' geom_text2 support aes(subset) via setup_data
##'
##'
##' @title geom_text2
##' @param mapping the aesthetic mapping
##' @param data A layer specific dataset -
##'             only needed if you want to override he plot defaults.
##' @param ... other arguments passed on to 'layer'
##' @param stat Name of stat to modify data
##' @param position The position adjustment to use for overlapping points on this layer
##' @param family sans by default, can be any supported font
##' @param parse if TRUE, the labels will be passd into expressions
##' @param na.rm logical
##' @param show.legend logical
##' @param inherit.aes logical
##' @param nudge_x horizontal adjustment
##' @param nudge_y vertical adjustment
##' @param check_overlap if TRUE, text that overlaps previous text in the same layer will not be plotted
##' @return text layer
##' @importFrom ggplot2 layer
##' @importFrom ggplot2 position_nudge
##' @importFrom ggplot2 aes_string
##' @importFrom ggfun get_aes_var
##' @export
##' @seealso
##' [geom_text][ggplot2::geom_text]
##' @author Guangchuang Yu
geom_text2 <- function(mapping = NULL, data = NULL,
                       ...,
                       stat = "identity",
                       position = "identity",
                       family="sans",
                       parse = FALSE,
                       na.rm=TRUE,
                       show.legend = NA,
                       inherit.aes = TRUE,
                       nudge_x = 0,
                       nudge_y = 0,
                       check_overlap = FALSE) {

    if (!missing(nudge_x) || !missing(nudge_y)) {
        if (!missing(position)) {
            stop("Specify either `position` or `nudge_x`/`nudge_y`", call. = FALSE)
        }

        position <- position_nudge(nudge_x, nudge_y)
    }

    default_aes <- aes_() #node=~node)
    if (is.null(mapping)) {
        mapping <- default_aes
    } else {
        mapping <- modifyList(mapping, default_aes)
    }

    if (parse == "emoji") {
        check_installed('emojifont', "for `geom_text2()` with parse = 'emoji'.")
        emoji <- get_fun_from_pkg("emojifont", "emoji")
        parse <- FALSE
        family <- "EmojiOne"
        ## label_aes <- aes_string(label=paste0("suppressMessages(emoji(", as.list(mapping)$label,"))"))
        label_aes <- aes_string(label=paste0("suppressMessages(emoji(", get_aes_var(mapping, "label"), "))"))
        ## mapping <- modifyList(mapping, aes(label=emoji(!!mapping$label))) ## ggplot2 >= 2.3.0
        mapping <- modifyList(mapping, label_aes)
    }

    layer(
        data = data,
        mapping = mapping,
        stat = stat, #StatTreeData,
        geom = GeomTextGGtree,
        position = position,
        show.legend = show.legend,
        inherit.aes = inherit.aes,
        params = list(
            parse = parse,
            family = family,
            check_overlap = check_overlap,
            na.rm = na.rm,
            ...
        ),
        check.aes = FALSE
    )
}


##' @importFrom ggplot2 GeomText
##' @importFrom ggplot2 draw_key_text
GeomTextGGtree <- ggproto("GeomTextGGtree", GeomText,
                          setup_data = function(data, params) {
                              if (is.null(data$subset))
                                  return(data)
                              data[which(data$subset),] ## use `which` makes it compatible with NA
                          },
                          ## compute_group = function(data, params) {
                          ##     data
                          ## },
                          draw_panel = function(data, panel_scales, coord, parse = FALSE,
                              na.rm = TRUE, check_overlap = FALSE) {
                              GeomText$draw_panel(data, panel_scales, coord, parse,
                                                  na.rm, check_overlap)
                          },
                          required_aes = c("x", "y", "label"),

                          default_aes = aes(colour = "black", size = 3.88, angle = 0, hjust = 0.5,
                              vjust = 0.5, alpha = NA, family = "", fontface = 1, lineheight = 1.2),

                          draw_key = draw_key_text
                          )

StatTreeData <-  ggproto("StatTreeLabel", Stat,
                         required_aes = "node",
                         compute_group = function(data, scales) {
                             setup_tree_data(data)
                         }
                         )


