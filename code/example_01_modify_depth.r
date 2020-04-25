library(tidyverse)
# dataframe represents single species
data = mtcars %>% 
  split(mtcars$carb) %>% # represents the hypothesis
  map(function(df){
    split(df, df$gear) # represents the top models
  })

# represents getting AIC
data_range = modify_depth(data, .depth = 2, .f = function(tm) {
  min(tm$mpg)
})

# represents getting AIC range
data_range = modify_depth(data_range, .depth = 1, .f = function(tm) {
  diff(range(unlist(tm)))
})

# now select the top level object with the min range
# in this case, the first instance of 0 is selected
data = data[which.min(unlist(data_range))]
