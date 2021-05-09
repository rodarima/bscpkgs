library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)
library(stringr)

args = commandArgs(trailingOnly=TRUE)

# Set the input dataset if given in argv[1], or use "input" as default
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }
if (length(args)>1) { output = args[2] } else { output = "?" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%

  jsonlite::flatten() %>%

  select(unit,
    config.nodes,
    config.gitBranch,
    config.granul,
    config.iterations,
    config.sizeFactor,
    config.nz,
    time,
    total_time) %>%

  rename(nodes=config.nodes,
    gitBranch=config.gitBranch,
    granul=config.granul,
    sizeFactor=config.sizeFactor,
    nz=config.nz,
    iterations=config.iterations) %>%

  # Remove the "garlic/" prefix from the gitBranch
  mutate(branch = str_replace(gitBranch, "garlic/", "")) %>%

  # Computations  before converting to factor
  mutate(time.nodes = time * nodes) %>%
  mutate(time.elem = time / sizeFactor) %>%
  mutate(time.nodes.iter = time.nodes / iterations) %>%

  # Convert to factors
  mutate(unit = as.factor(unit)) %>%
  mutate(nodes = as.factor(nodes)) %>%
  mutate(gitBranch = as.factor(gitBranch)) %>%
  mutate(granul = as.factor(granul)) %>%
  mutate(iterations = as.factor(iterations)) %>%
  mutate(sizeFactor = as.factor(sizeFactor)) %>%
  mutate(nz = as.factor(nz)) %>%
  mutate(unit = as.factor(unit)) %>%

  # Compute median times
  group_by(unit) %>%
  mutate(median.time = median(time)) %>%
  mutate(median.time.nodes = median(time.nodes)) %>%
  mutate(median.time.elem = median(time.elem)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%
  mutate(log.median.time.elem = log(median.time.elem)) %>%
  mutate(median.time.nodes.iter = median(time.nodes.iter)) %>%
  ungroup() %>%
  group_by(sizeFactor) %>%
  mutate(optimal.granul = (median.time.elem == min(median.time.elem))) %>%
  ungroup()

dfopt = df %>% filter(optimal.granul == TRUE)

dpi = 300
h = 4
w = 10

# ---------------------------------------------------------------------

#p = ggplot(df, aes(x=sizeFactor, y=normalized.time, fill=granul, color=iterations)) +
#  geom_boxplot() +
#  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
#  theme_bw() +
#  facet_wrap(branch ~ .) +
#  labs(x="nodes", y="Normalized time",
#    title="Creams strong scaling: normalized time", 
#    subtitle=output) + 
#  theme(plot.subtitle=element_text(size=8))
#
#ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
#ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=granul, y=time.elem, color=branch)) +
  geom_point(shape=21, size=3) +
#  geom_line(aes(y=median.time, group=gitBranch)) +
  theme_bw() +
  facet_wrap(sizeFactor ~ ., labeller=label_both, nrow=1) +
  labs(x="Granularity", y="Time / k (s)",
    #title="Creams size: time per object", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8, family="mono"),
    legend.position="bottom")

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=granul, y=median.time.elem, color=sizeFactor)) +
  geom_line(aes(group=sizeFactor)) +
  geom_point(data=dfopt, aes(x=granul, y=median.time.elem)) +
  theme_bw() +
  labs(x="Granularity", y="Time / k (s)",
    color="Size factor k",
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8, family="mono"),
    legend.position="bottom")

ggsave("median.time.png", plot=p, width=5, height=5, dpi=dpi)
ggsave("median.time.pdf", plot=p, width=5, height=5, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=granul, y=sizeFactor, fill=log.median.time.elem)) +
  geom_raster() +
  scale_fill_viridis(option="plasma") +
  coord_fixed() +
  theme_bw() +
  theme(axis.text.x=element_text(angle = -45, hjust = 0)) +
  theme(plot.subtitle=element_text(size=8)) +
  #guides(fill = guide_colorbar(barwidth=15, title.position="top")) +
  guides(fill = guide_colorbar(barwidth=12, title.vjust=0.8)) +
  labs(x="Granularity", y="Size factor", fill="Time / k (s)", subtitle=output) +
  theme(plot.subtitle=element_text(size=8, family="mono"),
    legend.position="bottom")

k=1
ggsave("heatmap.png", plot=p, width=4.8*k, height=5*k, dpi=300)
ggsave("heatmap.pdf", plot=p, width=4.8*k, height=5*k, dpi=300)
