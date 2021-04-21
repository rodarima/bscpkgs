library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)

# Load the arguments (argv)
args = commandArgs(trailingOnly=TRUE)
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }
if (length(args)>1) { output = args[2] } else { output = "?" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
  jsonlite::flatten() %>%
  select(config.blocksize, config.gitBranch, config.particles, unit, time) %>%
  rename(blocksize=config.blocksize, particles=config.particles, branch=config.gitBranch) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(particles = as.factor(particles)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

dpi = 300
h = 5
w = 5

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=normalized.time, color=branch)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  facet_wrap(~ branch) +
  theme_bw() +
  labs(x="Blocksize", y="Normalized Time", title="NBody Granularity: Normalized Time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=time)) +
  geom_boxplot() +
  theme_bw() +
  labs(x="Blocksize", y="Time (s)", title="NBody Granularity: Time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
