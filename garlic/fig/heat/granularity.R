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
    config.cbs,
    config.rbs,
    time,
    total_time) %>%

  rename(cbs=config.cbs,
    rbs=config.rbs) %>%

  # Convert to factors
  mutate(cbs = as.factor(cbs)) %>%
  mutate(rbs = as.factor(rbs)) %>%
  mutate(unit = as.factor(unit)) %>%

  # Compute median times
  group_by(unit) %>%
  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%
  ungroup()

dpi = 300
h = 6
w = 6

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=cbs, y=normalized.time)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  labs(y="Normalized time",
       title="Heat granularity: normalized time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# ---------------------------------------------------------------------

p = ggplot(df, aes(x=cbs, y=time)) +
  geom_point(shape=21, size=3) +
  geom_line(aes(y=median.time, group=0)) +
  theme_bw() +
  labs(y="Time (s)", title="Heat granularity: time", 
    subtitle=output) + 
  theme(plot.subtitle=element_text(size=8))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
