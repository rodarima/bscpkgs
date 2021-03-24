library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)

# Load the arguments (argv)
args = commandArgs(trailingOnly=TRUE)
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
  jsonlite::flatten() %>%
  select(config.blocksize, config.gitBranch, unit, time) %>%
  rename(blocksize=config.blocksize, branch=config.gitBranch) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

dpi = 300
h = 5
w = 8

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=median.time, color=branch)) +
  geom_point() +
  geom_line(aes(group=branch)) +
  theme_bw() +
  labs(x="Blocksize", y="Median time (s)", title="NBody Granularity: Median Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("median.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("median.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=normalized.time, color=branch)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  facet_wrap(~ branch) +
  theme_bw() +
  labs(x="Blocksize", y="Normalized Time", title="NBody Granularity: Normalized Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=time, color=branch)) +
  geom_point(shape=21, size=3) +
  theme_bw() +
  labs(x="Blocksize", y="Time (s)", title="NBody Granularity: Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)


# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=branch, fill=median.time)) +
  geom_raster() + 
  scale_fill_viridis(option="plasma") +
  coord_fixed() +
  theme_bw() +
  labs(x="Blocksize", y="Branch", title="NBody Granularity: Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("time.heatmap.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.heatmap.pdf", plot=p, width=w, height=h, dpi=dpi)
