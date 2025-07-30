


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Create a grob to represetnt the given string in flex font
#' 
#' @param txt chracter string. May contain newlines. Only letters A-Z are
#'        rendered
#' @param w,h the size of each letter
#' @param hgap,vgap the gap between each letter
#' @param scale A scaling factor applied to the letter size. Default: 1
#' @param x,y location of text on page. Default: centre
#' @param hjust,vjust justificaiton for this block of text. Default 0.5 (middle)
#' @param default.units default units for grid rendering. Default: 'npc'
#' @param gp graphics parameters e.g. lwd, color, linetype
#' @inheritParams flex_coords
#' @return grid graphics object
#' @examples
#' g <- flextextGrob("hello")
#' grid::grid.draw(g)
#' @import grid
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
flextextGrob <- function(txt, 
                         w = 1, h = 1, scale = 1, hgap = 0.1, vgap = 0.1,
                         x = unit(0.5, 'npc'), y = unit(0.5, 'npc'),
                         hjust = 0.5, vjust = 0.5, default.units = 'npc',
                         gp = grid::gpar(), npoints = 10) {
  
  if (!is.unit(x)) x <- grid::unit(x, default.units)
  if (!is.unit(y)) y <- grid::unit(y, default.units)
  
  lwd <- gp$lwd %||% 1
  
  coords <- flex_coords(
    txt, 
    w    = as.numeric(w), 
    h    = as.numeric(h), 
    sw   = lwd, 
    hgap = as.numeric(hgap), 
    vgap = as.numeric(vgap),
    npoints = npoints
  ) 
  
  chrs   <- strsplit(txt, "")[[1]]
  
  xrange     <- range(coords$x)
  yrange     <- range(coords$y)
  txt_width  <- abs(diff(xrange))
  txt_height <- abs(diff(yrange))
  
  xs <- coords$x
  ys <- coords$y
  
  xs <- xs - hjust * txt_width
  ys <- ys + (1 - vjust) * txt_height
  
  xs <- xs * scale
  ys <- ys * scale
  
  xs <- grid::unit(xs, default.units) + x
  ys <- grid::unit(ys, default.units) + y
  
  coords$id <- as.integer(with(coords, interaction(chr_idx, stroke_idx)))
  
  grid::polylineGrob(
    x  = xs, 
    y  = ys, 
    id = coords$id,
    gp = gp
  )
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Internal function to return the data.frame for a single path element
#' 
#' @param elem character string representing a single path element
#' @param state environment to track x,y coordinates over multiple calls
#' @return data.frame
#' @noRd
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
elem_to_df <- function(elem, state) {
  bits <- strsplit(elem, "\\s+")[[1]]
  cmd  <- bits[ 1]
  arg  <- bits[-1] |> as.numeric()
  
  switch(
    cmd, 
    M = {
      state$stroke_idx <- state$stroke_idx + 1L
      state$x <- arg[1]
      state$y <- arg[2]
      df <- data.frame(
        stroke_idx = state$stroke_idx,
        x          = arg[1],
        y          = arg[2]
      )
    },
    L = {
      df <- data.frame(
        stroke_idx = state$stroke_idx,
        x          = arg[1],
        y          = arg[2]
      )
      
      state$x <- arg[1]
      state$y <- arg[2]
    },
    A = {
      df <- arc_to_df(state$x, state$y, arg, npoints = state$npoints)
      state$x <- df$x[length(df$x)]
      state$y <- df$y[length(df$y)]
      df <- df[-1, , drop = FALSE]
      df <- cbind(stroke_idx = state$stroke_idx, df)
    },
    {
      stop("Unknown element path command: ", cmd)
    }
  )
  
  
  df
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a character vector of path elements to a data.frame
#' @param elems character vector of SVG path elements
#' @return data.frame
#' @noRd
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
path_to_df <- function(path, npoints) {
  state <- new.env()
  state$x <- 0
  state$y <- 0
  state$stroke_idx <- 0L
  state$npoints    <- npoints
  
  dfs <- lapply(path, elem_to_df, state = state)
  dfs <- do.call(rbind, dfs)
  rownames(dfs) <- NULL
  dfs
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Create a data.frame of text coordiantes for the given text
#' 
#' @param s string. May include newlines
#' @param w,h character width and height
#' @param sw stroke width. Used to adjust some character forms. Default: 1
#' @param hgap,vgap the gap between each letter
#' @param npoints the number of points to render for each arc.  Default: 10.
#'        Higher numbers will give a smoother appearance to the curves.
#' @return data.frame of coordinates
#' @examples
#' flex_coords('x')
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
flex_coords <- function(s, w = 1, h = 1, sw = 1, hgap = 0.1, vgap = 0.1, npoints = 10) {
  
  chrs <- strsplit(s, "")[[1]]
  
  yoff <- 0
  xoff <- 0
  
  df <- lapply(seq_along(chrs), \(chr_idx) {
    chr    <- chrs[[chr_idx]]
    if (chr == "\n") {
      yoff <<- yoff + h + vgap;
      xoff <<- 0
      NULL
    } else {
      path  <- chr_to_path(chr, w = w, h = h , sw = sw)
      chr_df <- path_to_df(path, npoints = npoints)  
      chr_df$x <- chr_df$x + xoff
      chr_df$y <- chr_df$y + yoff
      chr_df <- cbind(data.frame(chr_idx = chr_idx, chr = chr), chr_df)
      
      xoff <<- xoff + w + hgap
      
      chr_df
    }
  })
  
  df <- do.call(rbind, df)
  df$y <- yoff - df$y - h - vgap
  
  df
}


