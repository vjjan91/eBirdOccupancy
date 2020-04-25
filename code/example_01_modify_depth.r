library(tidyverse)
data = mtcars %>% 
  split(mtcars$carb) %>% 
  map(function(df){
    split(df, df$gear)
  })

# get the range of mpg at the second level
modify_depth(data, .depth = 2, .f = function(df) range(df$mpg))
