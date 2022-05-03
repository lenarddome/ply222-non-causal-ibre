library(data.table)
library(BEST)
library(BayesianFirstAid)
library(doSNOW)
library(doParallel)
library(igraph)
library(ggplot2)
library(ggthemes)
source("ply207utilities.R")

## import data

fname <- list.files("raw", "*.csv", full.names = TRUE)

## combine data

foo <- lapply(fname, fread) # import all
dta <- do.call(plyr::rbind.fill, foo)

## decode responses

dta$abstim <- NULL
dta$abstim <- as.factor(paste(dta$symptom1, dta$symptom2, dta$symptom3, sep = ""))

decode <- c("A", "AB", "ABD", "AC", "ACE",
            "ABD", "ACE", "B", "AB", "ABD",
            "BC", "ABD", "C", "AC", "ACE",
            "BC", "ACE", "ABD", "ABD", "ACE",
            "ACE")

print("Visually inspect that everything is in order! Below:")
print(cbind(levels(dta$abstim), decode))
levels(dta$abstim) <- decode

## double check stim dist during test
table(dta$abstim[dta$phase == "training"])
table(dta$abstim[dta$phase == "test"])

## exlclude the first participant
dta <- dta[dta$ppt %in%  unique(dta$ppt)[-1], ]
dta <- as.data.table(dta)

## training accuracy
dta[, blk := as.integer((trial - 1) / 8) + 1]

## test phase
tdta <- dta[phase == "test", .N, by = .(ppt, abstim, abresp)]
tdta[, prob := N / 20]

group <- tdta[abresp != "none",
              list(prob = sum(prob) / length(unique(dta$ppt))),
              by = .(abstim, abresp)][order(abstim, abresp)]
colnames(group) <-  c("stim", "resp", "prob")
knitr::kable(dcast(formula = stim ~ resp, data = data.table(group)),
             format = "pipe")

## IBRE
bc <- tdta[abstim == "BC" & abresp != "none"]
# long to wide conversion
bc <- merge(x = bc[abresp == "rare", c(1, 2, 5)],
            y = bc[abresp == "common", c(1, 2, 5)],
            by = c("ppt", "abstim"), all = TRUE,
            suffixes = c(".rare", ".common"))

# no responses are turned to NA, so swap it to 0
bc[is.na(bc)] <- 0

# find posterior distribution for the difference
bc_bayes <- BESTmcmc(y1 = bc$prob.rare,
                     y2 = bc$prob.common)

# check summary table for mcmc
bayes_table <- summary(bc_bayes, ROPEm = c(-0.1, 0.1), ROPEsd = c(-0.15, 0.15))
knitr::kable(data.frame(bayes_table)[],
             format = "markdown", digits = 2)

# predictive cues are judged faster
# ambiguous stimuli takes longer to sort on average
dta$rt <- as.numeric(dta$rt)
dta$ppt <- as.factor(dta$ppt)

wbetwe <- dta[abresp != "none" & phase == "test", .(rt, abresp, ppt, abstim)]

wbetwe[, .(mean = mean(rt)), by = .(abstim, abresp)][order(mean)]

## ORDINAL ANALYSIS

## calculate difference threshold
diff_test <- expand.grid(one = 0:20, two = 0:20)
diff_test <- data.table(diff_test)
diff_test[, difference := one - two]

.BayesOut <- function(one, two) {
    bf <- data.frame(bayes.prop.test(x = c(one, two),
                                     n = c(20, 20))$stats)[5, ]
    out <- bf$X..comp.1[1]
    return(out)
}

## check probability of one is larger than two
diff_test[, different := .BayesOut(one, two), by = row.names(diff_test)]
diff_mean <-
    diff_test[, round(mean(different), 2), by = difference][order(difference)]

## set lower and upper bounds for the mean probability of posterior
diff_mean[, bool := !between(V1, 0.10, 0.90)]

## do a meaningless graph
ggplot(diff_mean, aes(x = difference, y = V1, colour = bool)) +
    geom_point() +
    theme_few()

## carry out analysis with set threshold
ibre <- tdta[abstim %in% c("A", "B", "C", "BC", "AC", "AB") &
               abresp %in% c("common", "rare")]
ibre[, total := 20]
ibre$abstim <- factor(ibre$abstim)

colnames(ibre) <- c("ppt", "stim", "abresp", "success", "prob", "total")


stimuli <- list(c("BC"),
                c("BC", "A"),
                c("BC", "B", "C"),
                c("BC", "B", "C", "A"))

levels <- c("HUMAN_1", "HUMAN_2", "HUMAN_3", "HUMAN_4")

output <- NULL

n_iter <- length(unique(ibre$ppt))

## setup parallel environment
core_numbers <- detectCores() - 2
cl <- makeCluster(core_numbers)
registerDoSNOW(cl)

export_packages <- c("data.table", "BayesianFirstAid")

for (j in seq(4)) {
    ## print starting message
    print(
          paste("\n", Sys.time(), paste(stimuli[[j]], collapse = ", "),
                "and ∅ started")
    )

    ## setup progress bar
    pb <- txtProgressBar(max = length(unique(ibre$ppt)), style = 3)
    progress <- function(n) setTxtProgressBar(pb, n)
    opts <- list(progress = progress)

    ## setup environment
    stim <- as.factor(stimuli[[j]])
    tmp <- NULL
    ibre_out <- list()
    graph_order <- data.table()

    ## carry out statistical tests on subject-level test performance
    print(paste(Sys.time(), ": constructing inequality matrices.", sep = ""))

    ibre_out <- foreach(i = unique(ibre$ppt), .packages = export_packages,
                       .combine = "c", .options.snow = opts) %dopar% {
        tmp <- ibre[ppt == i & abresp == "rare", ]
        out <- imacHuman(x = tmp, stimuli = as.character(stim),
                         total = 20)
        out <- list(out)
        names(out) <- i
        out
    }
    ## assign to new object
    assign(levels[j], ibre_out)
    ## store ordinal pattern for ppt
    print(paste(Sys.time(), ": constructing graph order.", sep = ""))
    graph_order <- foreach(i = unique(ibre$ppt), .packages = export_packages,
                       .combine = "rbind", .options.snow = opts) %dopar% {
        tmp <- ibre[ppt == i, ]
        tmp <- .setupProfiles(tmp, stim = as.character(stim))
        tmp[, ppt := i]
        rbind(tmp, cbind(ppt = i, stim = "∅", success = 6))
    }
    ## assign graph order to new object
    assign(paste(levels[j], "order", sep = "_"), graph_order)
}

stopImplicitCluster()

## frequency plots

i1 <- match(HUMAN_1, unique(HUMAN_1))
tbl1 <- table(i1)
tbl1 <- data.table(tbl1)
tbl1[, pattern := paste(stimuli[[1]], collapse = ", ")]

i2 <- match(HUMAN_2, unique(HUMAN_2))
tbl2 <- table(i2)
tbl2 <- data.table(tbl2)
tbl2[, pattern := paste(stimuli[[2]], collapse = ", ")]

i3 <- match(HUMAN_3, unique(HUMAN_3))
tbl3 <- table(i3)
most3 <- HUMAN_3[as.integer(names(which(tbl3 == max(tbl3))))]
tbl3 <- data.table(tbl3)
tbl3[, pattern := paste(stimuli[[3]], collapse = ", ")]

i4 <- match(HUMAN_4, unique(HUMAN_4))
tbl4 <- table(i4)
most4 <- HUMAN_4[as.integer(names(which(tbl4 == max(tbl4))))]
tbl4 <- data.table(tbl4)
tbl4[, pattern := paste(stimuli[[4]], collapse = ", ")]


## ggplot histogram
freq_pat <- rbind(tbl1, tbl2, tbl3, tbl4, use.names = FALSE)
pfreq <- ggplot(freq_pat, aes(x = as.numeric(i1), y = N, fill = pattern)) +
    geom_col() +
    facet_wrap("pattern", nrow = 2, scales = "free", strip.position = "right") +
    theme_few() +
    xlab("Observed Pattern") +
    ylab("Counts of participants showing the pattern") +
    scale_fill_viridis_d(option = "A", end = 0.8) +
    theme(legend.position = "none")

ggsave(pfreq, filename = "freq.pdf", width = 12)

## undirected graph
dat <- melt(data.table(most3[[1]], keep.rownames = TRUE))
colnames(dat) <- c("from", "to", "weight")
adj_matrix <- graph.data.frame(dat[!is.na(weight)], directed = TRUE)

## specify weights and colours
weights <- E(adj_matrix)$weight    # specify weights
palette <- calc_pal()(12)
colors <- weights
colors[colors == 0] <- "#C1C7C9"
colors[colors == 1] <- palette[1]
colors[colors == -1] <- palette[2]

## very clumsy way of sorting vertex names
## convert it to factors then to numeric
sorting <- as.numeric(as.factor(HUMAN_3_order[ppt == names(most3)]$stim))
## sort based on numeric first
order <- HUMAN_3_order[ppt == names(most3)][sorting]
## order names according to successes and then convert factors to numeric
lay <- as.numeric(as.factor(order$stim[order(as.numeric(order$success))]))
CairoPDF("plot.pdf", 10, 10)
plot_directed <-
    plot(adj_matrix, layout = cbind(lay, 1),
         edge.curved = TRUE, edge.color = colors, edge.width = 3,
         edge.label = weights, vertex.label.cex = 1, vertex.size = 20,
         vertex.label.family = "DejaVu Sans Mono")
dev.off()

undirected_graph_wgt <- as.undirected(adj_matrix, mode = "collapse",
                                      edge.attr.comb = "sum")
plot(undirected_graph_wgt, layout = cbind(lay, 1),
     edge.color = colors, edge.width = 3, edge.label = weights,
     edge.curved = TRUE,
     vertex.label.cex = 1, vertex.size = 20,
     vertex.label.family = "DejaVu Sans Mono")


## save trial order

trial_order <- dta[, c("ppt", "abstim", "trial", "phase")]
fwrite(trial_order, "ply207trialorder.csv")
