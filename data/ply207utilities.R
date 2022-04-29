## function guarding against missing responses
.setupProfiles <- function(profile, stim) {
    ppt_table <- NULL
    ## create table with rare response counts
    for (k in unique(stim)) {
        rare <- profile[stim == k & abresp == "rare"]$success # extract rare counts
        if (length(rare) == 0) rare <- 0                      # if missing, set to 0
        ppt_table <- rbind(ppt_table, data.table(stim = k, success = rare))
    }
    return(ppt_table)
}


## it takes data.table x with the following columns: ppt, stim, success [count]
## and outputs an inequality matrix
imacHuman <- function(x, stimuli, thresholds = c(0.20, -0.20), total = 12) {

    ## setup profiles
    ppt_table <- .setupProfiles(profile = x, stim = stimuli)
    ppt_table <- ppt_table[order(c(stim), decreasing = FALSE), ]
    ## add midpoint
    ppt_table <-  rbind(cbind(stim = "∅", success = 6), ppt_table)

    ## create comparisons
    comparison <- t(combn(ppt_table$stim, m = 2))

    ## set up output matrix
    out <- data.frame(matrix(0, nrow = nrow(ppt_table), ncol = nrow(ppt_table)))
    names <- c(as.character(stimuli), "∅")
    rownames(out) <- names[order(names)]
    colnames(out) <- names[order(names)]

    ## create inequality matrix
    for (m in seq(nrow(comparison))) {
        pair <- comparison[m, ]
        one <- as.numeric(ppt_table[stim == pair[1]]$success)
        two <- as.numeric(ppt_table[stim == pair[2]]$success)
        ## find the location of current comparison in matrix and insert result
        irow = which(colnames(out) == pair[1])
        icol = which(colnames(out) == pair[2])
        out[irow, icol] <- (one - two) / total
    }
    # if larger, set to 1
    out[out >= thresholds[1]] <- 1
    ## if smaller, set to 2
    out[out <= thresholds[2] & out != 0] <- -1
    ## if same, set to 0
    out[between(out, lower = thresholds[2], upper = thresholds[1],
                incbounds = FALSE)] <- 0
    ## remove lower triangular matrix including diagonal 
    out[!upper.tri(out)] <- NA
    return(out)
}
