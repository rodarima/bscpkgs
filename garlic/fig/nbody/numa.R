library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)
library(stringr)

# Load the arguments (argv)
args = commandArgs(trailingOnly=TRUE)
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
  jsonlite::flatten() %>%
  select(unit,
    config.blocksize,
    config.gitBranch,
    config.attachToSocket,
    config.interleaveMem,
    config.nodes,
    unit,
    time) %>%

  rename(blocksize=config.blocksize,
    gitBranch=config.gitBranch,
    nodes=config.nodes,
    attachToSocket=config.attachToSocket,
    interleaveMem=config.interleaveMem) %>%

  # Remove the "garlic/" prefix from the gitBranch
  mutate(branch = str_replace(gitBranch, "garlic/", "")) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(attachToSocket = as.factor(attachToSocket)) %>%
  mutate(interleaveMem = as.factor(interleaveMem)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

branch = unique(df$branch)
nodes = unique(df$nodes)

dpi = 300
h = 5
w = 8

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=normalized.time, color=interleaveMem)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  facet_wrap(~ attachToSocket, labeller=label_both) +
  labs(x="Blocksize", y="Normalized time",
    title=sprintf("NBody NUMA (%s | %d Nodes): Normalized time",
      branch, nodes), 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position="bottom")

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=time, color=interleaveMem)) +
  geom_boxplot() +
  geom_line(aes(y=median.time)) +
  theme_bw() +
  facet_wrap(~ attachToSocket, labeller=label_both) +
  labs(x="Blocksize", y="Time (s)",
    title=sprintf("NBody NUMA (%s | %d Nodes): Time",
      branch, nodes), 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position="bottom")

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
