library(data.table)
library(BayesFactor)
library(BayesianFirstAid)
library(ggplot2)
library(ggthemes)
library(ggdist)

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

dta <- data.table(dta)

## exlclude the first participant
reaction <- dta[, .(rt = mean(as.numeric(rt), na.rm = TRUE),
                    sd = sd(as.numeric(rt),na.rm = TRUE)), by = ppt]
reaction[, .(mean(rt), sd(rt))]
reaction[, min(rt)]
exclusion <- reaction[order(rt) & rt < (mean(rt) - sd(rt))]

## test phase
tdta <- dta[phase == "test" & !(ppt %in% exclusion),
            .N, by = .(ppt, abstim, abresp)]
tdta[, prob := N / 20]


### determine threshold for exclusion on training items
# BayesFactor::proportionBF(y = 14, N = 20, p = 0.5)
BayesianFirstAid::bayes.prop.test(x = 12, n = 20)

inclusion_memory_common <-
    tdta[abstim == 'AB' & abresp == 'common', prob >= 0.75, by = ppt]
include <- inclusion_memory_common[V1 == TRUE]$ppt

inclusion_memory_rare <-
    tdta[abstim == 'AC' & abresp == 'rare', prob >= 0.75, by = ppt]
include2 <- inclusion_memory_rare[V1 == TRUE]$ppt


inclusion_memory <- include[include %in% include2]

group <- tdta[abresp != "none" & ppt %in% inclusion_memory,
              list(prob = sum(prob) / length(unique(inclusion_memory))),
              by = .(abstim, abresp)][order(abstim, abresp)]
colnames(group) <-  c("stim", "resp", "prob")
knitr::kable(dcast(formula = stim ~ resp, data = data.table(group)),
             format = "latex", digits = 2)

## IBRE
bc <- tdta[abstim == "BC" & abresp != "none" & (ppt %in% inclusion_memory)]
# long to wide conversion
bc <- merge(x = bc[abresp == "rare", c(1, 2, 5)],
            y = bc[abresp == "common", c(1, 2, 5)],
            by = c("ppt", "abstim"), all = TRUE,
            suffixes = c(".rare", ".common"))

# no responses are turned to NA, so swap it to 0
bc[is.na(bc)] <- 0

# find posterior distribution for the difference
bc_bayes <- ttestBF(x = bc$prob.rare, mu = 0.5)
papaja::apa_print(bc_bayes)$full_result

## stimuli A

## IBRE
aa <- tdta[abstim == "A" & abresp != "none" & (ppt %in% inclusion_memory)]
# long to wide conversion
aa <- merge(x = aa[abresp == "rare", c(1, 2, 5)],
            y = aa[abresp == "common", c(1, 2, 5)],
            by = c("ppt", "abstim"), all = TRUE,
            suffixes = c(".rare", ".common"))

# no responses are turned to NA, so swap it to 0
aa[is.na(aa)] <- 0

# find posterior distribution for the difference
aa_bayes <- ttestBF(x = aa$prob.common, mu = 0.5)
papaja::apa_print(aa_bayes)$full_result

# predictive cues are judged faster
# ambiguous stimuli takes longer to sort on average
dta$rt <- as.numeric(dta$rt)
dta$ppt <- as.factor(dta$ppt)

wbetwe <- dta[abresp != "none" & phase == "test", .(rt, abresp, ppt, abstim)]

wbetwe[, .(mean = mean(rt)), by = .(abstim, abresp)][order(mean)]

bc_group <- ggplot(tdta[abresp == 'rare'], aes(x = abstim, y = prob, fill = abstim)) +
    geom_jitter(alpha = 0.1, size = 0.8, width = 0.2) +
    stat_histinterval(p_limits = c(0, 1)) +
    geom_boxplot(aes(fill = NULL), outlier.colour = NA, width = 0.125) +
    #scale_fill_tq() +
    scale_fill_calc(name = "Stimuli") +
    theme_par() +
    labs(x = "Test Items", y = "P(R|Stimulus)") +
    theme(legend.position = "bottom")

ggsave(bc_group, width = 10, height = 5, units = "in", filename = "group.pdf")
