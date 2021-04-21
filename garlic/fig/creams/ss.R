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
    time,
    total_time) %>%

  rename(nodes=config.nodes,
    gitBranch=config.gitBranch,
    granul=config.granul,
    iterations=config.iterations) %>%

  # Remove the "garlic/" prefix from the gitBranch
  mutate(branch = str_replace(gitBranch, "garlic/", "")) %>%

  # Computations  before converting to factor
  mutate(time.nodes = time * nodes) %>%
  mutate(time.nodes.iter = time.nodes / iterations) %>%

  # Convert to factors
  mutate(unit = as.factor(unit)) %>%
  mutate(nodes = as.factor(nodes)) %>%
  mutate(gitBranch = as.factor(gitBranch)) %>%
  mutate(granul = as.factor(granul)) %>%
  mutate(iterations = as.factor(iterations)) %>%
  mutate(unit = as.factor(unit)) %>%

  # Compute median times
  group_by(unit) %>%
  mutate(median.time = median(time)) %>%
  mutate(median.time.nodes = median(time.nodes)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%
  mutate(median.time.nodes.iter = median(time.nodes.iter)) %>%
  ungroup()

dpi = 300
h = 5
w = 8

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=normalized.time, fill=granul, color=iterations)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  facet_wrap(branch ~ .) +
  labs(x="nodes", y="Normalized time",
    title="Creams strong scaling: normalized time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=time, color=gitBranch)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(y=median.time, group=gitBranch)) +
  theme_bw() +
#  facet_wrap(branch ~ .) +
  labs(x="nodes", y="Time (s)", title="Creams strong scaling: time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=median.time.nodes, color=branch)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(group=branch)) +
  theme_bw() +
  #facet_wrap(branch ~ .) +
  labs(x="nodes", y="Median time * nodes (s)", title="Creams strong scaling: median time * nodes", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("median.time.nodes.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("median.time.nodes.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=nodes, y=time.nodes, color=branch)) +
  geom_boxplot() +
  theme_bw() +
  facet_wrap(branch ~ .) +
  labs(x="nodes", y="Time * nodes (s)", title="Creams strong scaling: time * nodes", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("time.nodes.boxplot.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.nodes.boxplot.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

#p = ggplot(df, aes(x=nodes, y=time.nodes.iter, color=branch)) +
#  geom_point(shape=21, size=3) +
#  geom_line(aes(y=median.time.nodes.iter, group=interaction(granul,iterations))) +
#  theme_bw() +
#  #facet_wrap(branch ~ .) +
#  labs(x="nodes", y="Time * nodes / iterations (s)",
#    title="Creams strong scaling: time * nodes / iterations", 
#    subtitle=output) + 
#  theme(plot.subtitle=element_text(size=8))
#
#ggsave("time.nodes.iter.png", plot=p, width=w, height=h, dpi=dpi)
#ggsave("time.nodes.iter.pdf", plot=p, width=w, height=h, dpi=dpi)
