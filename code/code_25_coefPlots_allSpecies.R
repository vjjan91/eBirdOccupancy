#### Making coefficient plots for different species from occupancy models #### 
### Useful link: https://gist.github.com/dsparks/4332698

library(openxlsx)
library(dplyr)
library(tidyselect)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)

# Load the individual model estimates 
modEstSheets <- getSheetNames("data/results/lc-clim-modelEst.xlsx")
modEst <-lapply(modEstSheets,openxlsx::read.xlsx, xlsxFile = "data/results/lc-clim-modelEst.xlsx")
names(modEst) <- modEstSheets

# Making all plots
for(i in 1:length(modEst)){
    names(modEst[[i]]) <- c("Predictor","Coefficient" ,"SE" ,"lowerCI" , "upperCI" ,"z_value"  ,"Pr_z")
    plot <-  modEst[[i]] %>% filter(Pr_z<0.05)
    if(dim(plot)[1]==0){
      next
    } else {
    model <- data.frame(Predictor = plot$Predictor,
                        Coefficient = plot$Coefficient,
                        SE = plot$SE,
                        lowerCI = plot$lowerCI,
                        upperCI = plot$upperCI,
                        Species = names(modEst)[i])
    
    p1 <- ggplot(model, aes(colour = Species)) +
      geom_hline(yintercept = 0, colour = gray(1/2), lty = 2) +
      geom_linerange(aes(x = Predictor, ymin = lowerCI,ymax = upperCI),
                     lwd = 1, position = position_dodge(width = 1/2)) +
      geom_pointrange(aes(x = Predictor, y = Coefficient, ymin = lowerCI,ymax = upperCI),
                      lwd = 1/2, position = position_dodge(width = 1/2),
                      shape = 21, fill = "WHITE") + theme_bw() + coord_flip()
    
    dirname <- "C:\\Users\\vr235\\Downloads\\coefPlots\\"
    
    ggsave(filename="",
           plot=p1, device="png", dpi=300,path = paste(dirname, paste(names(modEst)[i], ".png", sep=""), sep=""))
    }
}
