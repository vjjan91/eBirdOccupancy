#### code to get landcover proportion by elevation ####

# load libs
library(data.table); library(raster)
library(stars)
# get data
elevData <- raster("data/elevationHills.tif")
lc <- raster("data/spatial/landcover100m.tif")
elevData <- projectRaster(from = elevData, to = lc, res = res(lc))


# get coords of elev and extract lc
combdata <- coordinates(elevData)
lc_at_coords <- raster::extract(lc, combdata)
combdata <- cbind(combdata, elev = getValues(elevData))
combdata <- cbind(combdata, lc_at_coords)

# set data table and round values
combdata <- data.table(combdata)
combdata[,elev_round:=plyr::round_any(elev, 100)]
combdata <- combdata[!is.na(lc_at_coords) & !is.na(elev_round),.N, 
                     by = list(lc_at_coords, elev_round)
                     ][,prop:=N/sum(N), by = "elev_round"][lc_at_coords > 0,]

# plot in ggplot
library(ggplot2)

ggplot(combdata)+
  geom_tile(aes(x=elev_round, y=factor(lc_at_coords), fill=factor(lc_at_coords), alpha=prop), col="white")+
  scale_fill_manual(values = pals::kovesi.rainbow(7))+
  labs(x = "elevation (100m interval)", y = "landcover", title = "landcover proportion ~ elevation",
       caption = Sys.time(), fill = "landcover", alpha="prop.")+
  ggthemes::theme_few()

ggsave(filename = "figs/fig_lc_elev.png", device = png())

#### checklists per elevation ####
chkdata <- fread("data/eBirdChecklistVars.csv")
# re-read elev instead of reproj
elevData <- raster("data/elevationHills.tif")
chkdata[,elev:=extract(elevData, chkdata[,c("longitude", "latitude")])]
nchk_elev <- chkdata[,elev_round:=plyr::round_any(elev, 100)
        ][!is.na(elev_round),][,.N, by=c("longitude","latitude", "elev_round")]

# plot and export
ggplot(chkdata)+
  geom_histogram(aes(x = elev), fill = "grey", col = 1, lwd = 0.2)+
  ggthemes::theme_few()+
  labs(x = "elevation (100m interval)", y = "count", title = "N checklists ~ elevation",
       caption = Sys.time())
ggsave(filename = "figs/fig_nchk_elev.png", device = png())

#### localities per elevation ####
library(dplyr)
nloc_elev <- setDT(distinct(chkdata, latitude, longitude, .keep_all = T))[,elev_round:=plyr::round_any(elev, 100)
                                                                          ][,.N, by="elev_round"][!is.na(elev_round),]

# plot figure 
ggplot(data = nloc_elev)+
  geom_col(aes(x = elev_round, y=N), fill = "grey", col = 1, lwd = 0.2)+
  geom_boxplot(data = nchk_elev, aes(x=elev_round, y = N*500, group=elev_round), 
               alpha=0.2, outlier.colour = "grey", outlier.size = 0.2, lwd=0.3)+
  
  scale_y_continuous(sec.axis = dup_axis(trans = ~./500, name = "number of checklists"))+
  ggthemes::theme_few()+
  coord_cartesian(ylim=c(0,1e4))+
  labs(x = "elevation (100m interval)", y = "number of localities", title = "N localities -- N checklists -- elevation",
       caption = Sys.time())

ggsave(filename = "figs/fig_locals_nchk_elev.png", device = png())
