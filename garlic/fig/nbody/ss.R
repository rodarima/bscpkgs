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
  select(config.blocksize, config.gitBranch, config.nodes, unit, time) %>%
  rename(nodes = config.nodes, blocksize=config.blocksize, branch=config.gitBranch) %>%

  mutate(time.nodes = time * nodes) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(nodes = as.factor(nodes)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(median.time.nodes = median(time.nodes)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

dpi = 300
h = 5
w = 8

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=normalized.time, color=branch)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  facet_wrap(~ branch) +
  theme_bw() +
  labs(x="Nodes", y="Normalized time (s)", title="NBody Scaling: Normalized Time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=time.nodes, color=branch)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(y=median.time.nodes, group=branch)) +
  theme_bw() +
  labs(x="Nodes", y="Time * nodes (s)", title="NBody Scaling: Time * nodes", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  theme(legend.text = element_text(size=7))

ggsave("time.nodes.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.nodes.pdf", plot=p, width=w, height=h, dpi=dpi)
