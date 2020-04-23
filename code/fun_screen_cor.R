# screen a data set for strong correlations to find redundant variables...
# e.g. find all corrs with ABS(r)>0.7.
# reports row & col name and the correlation for r>rmax.
screen.cor <- function(data, thin=TRUE, threshold=0.7) {
  # data, a frame of numeric variables
  nv <- dim(data)[[2]]
  nc <- nv*(nv-1)/2
  v1 <- rep(NA,nc)
  v2 <- rep(NA,nc)
  r <- rep(NA,nc)
  k <- 0
  for (i in 2:nv) {
    for (j in 1:(i-1)) {
        k <- k+1
        v1[k] <- names(data)[i]
        v2[k] <- names(data)[j]
        r[k] <- cor.test(data[,i],data[,j])$estimate
    }
  }
  out <- data.frame(cbind(v1,v2,r))
  if (thin) {
    out <- out[abs(r)>=threshold,]
  }
  out
}