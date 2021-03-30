library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)
library(stringr)

args = commandArgs(trailingOnly=TRUE)

# Set the input dataset if given in argv[1], or use "input" as default
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

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
  mutate(time.iter = time / iterations) %>%

  # Convert to factors
  mutate(unit = as.factor(unit)) %>%
  mutate(nodesFactor = as.factor(nodes)) %>%
  mutate(gitBranch = as.factor(gitBranch)) %>%
  mutate(granul = as.factor(granul)) %>%
  mutate(iterations = as.factor(iterations)) %>%
  mutate(unit = as.factor(unit)) %>%

  # Compute median times
  group_by(unit) %>%
  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%
  mutate(median.time.iter = median(time.iter)) %>%
  ungroup()

dpi = 300
h = 6
w = 6

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=granul, y=normalized.time)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  facet_wrap(branch ~ .) +
  labs(x="granul", y="Normalized time",
       title="Creams granularity: normalized time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=granul, y=time, color=branch)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(y=median.time, group=branch)) +
  theme_bw() +
  labs(x="granul", y="Time (s)", title="Creams granularity: time", 
    subtitle=input_file) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
