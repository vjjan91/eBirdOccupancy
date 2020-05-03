#' Plot interactions among occupancy predictors.
#'
#' @param A data frame with the columns predictor, modulator, m_group, seq_x, mean and ci.
#'
#' @return A ggplot object.
make_interaction_plot <- function(data, predictor, modulator){
  
  # make the actual ggplot here
  
  fig_subplot <- ggplot(data)+
    geom_point(aes(seq_x, mean,
                   ymin = mean-ci,
                   ymax = mean+ci,
                   col = factor(m_group)),
               shape = 1, size = 0.3)+
    geom_errorbar(aes(seq_x, mean,
                      ymin = mean-ci,
                      ymax = mean+ci,
                      col = factor(m_group)),
                  size = 0.2)+
    geom_smooth(aes(seq_x, mean,
                    col = factor(m_group)),
                method = "glm",
                size = 0.3,
                se = F)+
    scale_colour_manual(values = c("black", "black"))+
    scale_y_continuous(breaks = c(0,0.5,1))+
    
    # coord_fixed(xlim=c(0,1),ylim = c(0,1.2), ratio = 0.8)+
    coord_cartesian(ylim = c(0,1.2))+
    theme_test(base_size = 6)+
    theme(legend.position = "none",
          # plot.background = element_rect(colour = "grey"),
          legend.key = element_blank(),
          legend.title = element_text(size = 6),
          legend.text = element_text(size = 6))+
    labs(x = glue::glue('{predictor}'),
         y = "occupancy")
  
  # if there is a modulator
  
  if(!is.na(modulator)){
    # a dataframe of where to place the labels
    label_data <-  group_by(data, m_group) %>% 
      summarise(label_y = mean(mean),
                max_x = max(seq_x)) %>% 
      mutate(label_x = seq(0, max(max_x), length.out = length(label_y)))
    
    fig_subplot <- fig_subplot+
      geom_text(data = label_data,
                aes(x = label_x, y = 1.2, 
                    label = glue::glue('{modulator}\n{m_group}'),
                    col = factor(m_group)),
                hjust = "inward",
                vjust = "inward",
                size = 1.5)+
      # overwrite palette
      scale_colour_brewer(palette = "Dark2")
  }
  
  return(fig_subplot)
  
}
