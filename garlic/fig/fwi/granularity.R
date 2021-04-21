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
    config.blocksize,
    config.gitBranch,
    time) %>%

	rename(blocksize=config.blocksize,
    gitBranch=config.gitBranch) %>%

  # Remove the "garlic/" prefix from the gitBranch
  mutate(branch = str_replace(gitBranch, "garlic/", "")) %>%

  mutate(unit = as.factor(unit)) %>%
  mutate(gitBranch = as.factor(gitBranch)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(blocksize = as.factor(blocksize)) %>%

  group_by(unit) %>%
  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  ungroup()


dpi = 300
h = 6
w = 6

main_title = "FWI granularity"

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=normalized.time)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  facet_wrap(branch ~ .) +
  labs(y="Normalized time",
    title=sprintf("%s: normalized time", main_title), 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=blocksize, y=time, color=branch)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(y=median.time, group=branch)) +
  theme_bw() +
  labs(y="Time (s)",
    title=sprintf("%s: time", main_title), 
    subtitle=output) + 
  theme(legend.position="bottom") +
  theme(plot.subtitle=element_text(size=8))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
