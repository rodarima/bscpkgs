library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)

args = commandArgs(trailingOnly=TRUE)

if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%

  jsonlite::flatten() %>%

  select(config.nblocks,
    config.ncomms,
    config.hw.cpusPerSocket,
    config.blocksPerCpu,
    unit,
    time) %>%

  rename(nblocks=config.nblocks,
         ncomms=config.ncomms,
         blocksPerCpu=config.blocksPerCpu) %>%

  mutate(nblocks = as.factor(nblocks)) %>%
  mutate(blocksPerCpu = as.factor(blocksPerCpu)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

dpi=300
h=5
w=5

p = ggplot(df, aes(x=blocksPerCpu, y=normalized.time)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  theme_bw() +
  labs(x="Blocks per CPU", y="Normalized time", title="HPCG granularity: normalized time",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

p = ggplot(df, aes(x=blocksPerCpu, y=time)) +
  geom_point(shape=21, size=3) +
  theme_bw() +
  labs(x="Blocks per CPU", y="Time (s)", title="HPCG granularity: time",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8))

ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)

