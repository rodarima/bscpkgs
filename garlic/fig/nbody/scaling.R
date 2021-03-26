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
  select(config.blocksize, config.gitBranch, config.numNodes, unit, time) %>%
  rename(nodes = config.numNodes, blocksize=config.blocksize, branch=config.gitBranch) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(nodes = as.factor(nodes)) %>%
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

p = ggplot(df, aes(x=nodes, y=median.time, color=branch)) +
  geom_point() +
  geom_line(aes(group=branch)) +
  theme_bw() +
  labs(x="Nodes", y="Median time (s)", title="NBody Scaling: Median Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("median.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("median.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=normalized.time, color=branch)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  facet_wrap(~ branch) +
  theme_bw() +
  labs(x="Nodes", y="Normalized time (s)", title="NBody Scaling: Normalized Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=time, color=branch)) +
  geom_point(shape=21, size=3) +
  theme_bw() +
  labs(x="Nodes", y="Time (s)", title="NBody Scaling: Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)


# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=branch, fill=median.time)) +
  geom_raster() + 
  scale_fill_viridis(option="plasma") +
  coord_fixed() +
  theme_bw() +
  labs(x="Nodes", y="Branch", title="NBody Scaling: Time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("time.heatmap.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.heatmap.pdf", plot=p, width=w, height=h, dpi=dpi)
