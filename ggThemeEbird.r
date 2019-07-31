#### gpglot theme for ebird maps ####
library(ggplot2)

themeEbird <- function(base_size=10) {
  library(grid)
  #require(lemon)
  (theme_bw(base_size=base_size)+
      theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            panel.border = element_rect(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust = 4),
            axis.title.x = element_text(vjust = -2),
            axis.text.x = element_text(vjust = 1),
            axis.text.y = element_text(angle=90, vjust = 2, hjust = 0.5),
            axis.ticks = element_line(size = 0.3),
            axis.ticks.length = unit(0.2, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "none",
            panel.grid.minor = element_blank(),
            plot.margin=unit(c(10,5,5,5),"mm"),
            plot.background = element_rect(fill = "white", colour = "transparent"),
            strip.background=element_blank(),
            strip.text = element_text(face="bold", hjust = 0),
            panel.spacing = unit(1, "lines")
      ))

}

themeEbirdMap <- function(base_size=10) {
  library(grid)
  #require(lemon)
  (theme_bw(base_size=base_size)+
      theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            panel.border = element_blank(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust = 4),
            axis.title.x = element_text(vjust = -2),
            axis.text.x = element_text(vjust = -1, size = 4),
            axis.text.y = element_text(angle=90, vjust = 2, hjust = 0.5, size = 4),
            axis.ticks = element_line(size = 0.3),
            axis.ticks.length = unit(-0.1, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "none",
            panel.grid.minor = element_blank(),
            plot.margin=unit(c(10,5,5,5),"mm"),
            plot.background = element_rect(fill = "white", colour = "transparent"),
            strip.background=element_blank(),
            strip.text = element_text(face="bold", hjust = 0),
            panel.spacing = unit(1, "lines")
      ))

}
