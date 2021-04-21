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
    config.nblx,
    config.nbly,
    config.nblz,
    config.gitBranch,
    config.blocksPerCpu,
    config.sizex,
    time,
    total_time) %>%

  rename(nodes=config.nodes,
    nblx=config.nblx,
    nbly=config.nbly,
    nblz=config.nblz,
    gitBranch=config.gitBranch,
    blocksPerCpu=config.blocksPerCpu,
    sizex=config.sizex) %>%

  # Remove the "garlic/" prefix from the gitBranch
  mutate(branch = str_replace(gitBranch, "garlic/", "")) %>%

  # Computations before converting to factor
  mutate(time.nodes = time * nodes) %>%

  # Convert to factors
  mutate(unit = as.factor(unit)) %>%
  mutate(nodes = as.factor(nodes)) %>%
  mutate(gitBranch = as.factor(gitBranch)) %>%
  mutate(nblx = as.factor(nblx)) %>%
  mutate(nbly = as.factor(nbly)) %>%
  mutate(nblz = as.factor(nblz)) %>%
  mutate(sizex = as.factor(sizex)) %>%
  mutate(unit = as.factor(unit)) %>%

  # Compute median times
  group_by(unit) %>%
  mutate(median.time = median(time)) %>%
  mutate(median.time.nodes = median(time.nodes)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%
  ungroup()

dpi = 300
h = 5
w = 8

maintitle = "Saiph-Heat3D granularity"

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nbly, y=normalized.time, fill=sizex)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  facet_wrap(branch ~ .) +
  labs(y="Normalized time",
    title=sprintf("%s: normalized time", maintitle), 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksPerCpu, y=time, color=sizex)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(y=median.time, group=sizex)) +
  theme_bw() +
  scale_x_continuous(trans=log2_trans()) +
  labs(y="Time (s)",
    title=sprintf("%s: time", maintitle), 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
