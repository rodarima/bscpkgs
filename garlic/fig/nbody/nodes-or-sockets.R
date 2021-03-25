library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)

# Load the arguments (argv)
args = commandArgs(trailingOnly=TRUE)
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

dfNuma = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
  jsonlite::flatten() %>%
  select(config.blocksize, config.gitBranch, config.socketAtt, config.useNumact, unit, time) %>%
  rename(blocksize=config.blocksize, branch=config.gitBranch, attachment=config.socketAtt, usenuma=config.useNumact) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(attachment = as.factor(attachment)) %>%
  mutate(usenuma = as.factor(usenuma)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  filter(usenuma == TRUE) %>%

  ungroup()

dfNonuma = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
  jsonlite::flatten() %>%
  select(config.blocksize, config.gitBranch, config.socketAtt, config.useNumact, unit, time) %>%
  rename(blocksize=config.blocksize, branch=config.gitBranch, attachment=config.socketAtt, usenuma=config.useNumact) %>%

  mutate(blocksize = as.factor(blocksize)) %>%
  mutate(branch = as.factor(branch)) %>%
  mutate(attachment = as.factor(attachment)) %>%
  mutate(usenuma = as.factor(usenuma)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  filter(usenuma == FALSE) %>%

  ungroup()

dpi = 300
h = 5
w = 8


# ---------------------------------------------------------------------

p = ggplot(dfNuma, aes(x=blocksize, y=median.time, color=attachment)) +
  geom_point() +
  geom_line(aes(group=attachment)) +
  theme_bw() +
  labs(x="Blocksize", y="Median time (s)", title="NBody Granularity (tampi+send+oss+task | numactl ON | 4 Nodes): Median Time", 
    subtitle=input_file, color="Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("median-numactl.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("median-numactl.time.pdf", plot=p, width=w, height=h, dpi=dpi)

p = ggplot(dfNonuma, aes(x=blocksize, y=median.time, color=attachment)) +
  geom_point() +
  geom_line(aes(group=attachment)) +
  theme_bw() +
  labs(x="Blocksize", y="Median time (s)", title="NBody Granularity (tampi+send+oss+task | numactl OFF | 4 Nodes): Median Time", 
    subtitle=input_file, color="Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("median.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("median.time.pdf", plot=p, width=w, height=h, dpi=dpi)
# ---------------------------------------------------------------------

p = ggplot(dfNuma, aes(x=blocksize, y=normalized.time, color=attachment)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  facet_wrap(~ attachment) +
  theme_bw() +
  labs(x="Blocksize", y="Normalized Time", title="NBody Granularity (tampi+send+oss+task | numactl ON | 4 Nodes): Normalized Time", 
    subtitle=input_file, color="Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("normalized-numactl.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized-numactl.time.pdf", plot=p, width=w, height=h, dpi=dpi)

p = ggplot(dfNonuma, aes(x=blocksize, y=normalized.time, color=attachment)) +
  geom_boxplot() +
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +
  facet_wrap(~ attachment) +
  theme_bw() +
  labs(x="Blocksize", y="Normalized Time", title="NBody Granularity (tampi+send+oss+task | 4 Nodes): Normalized Time", 
    subtitle=input_file, color="Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)
# ---------------------------------------------------------------------

p = ggplot(dfNuma, aes(x=blocksize, y=time, color=attachment)) +
  geom_point(shape=21, size=3) +
  theme_bw() +
  labs(x="Blocksize", y="Time (s)", title="NBody Granularity (tampi+send+oss+task | numactl ON | 4 Nodes): Time", 
    subtitle=input_file, color="Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("time-numactl.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time-numactl.pdf", plot=p, width=w, height=h, dpi=dpi)

p = ggplot(dfNonuma, aes(x=blocksize, y=time, color=attachment)) +
  geom_point(shape=21, size=3) +
  theme_bw() +
  labs(x="Blocksize", y="Time (s)", title="NBody Granularity (tampi+send+oss+task | 4 Nodes): Time", 
    subtitle=input_file, color="Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))


ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)
# ---------------------------------------------------------------------

p = ggplot(dfNuma, aes(x=blocksize, y=attachment, fill=median.time)) +
  geom_raster() + 
  scale_fill_viridis(option="plasma") +
  coord_fixed() +
  theme_bw() +
  labs(x="Blocksize", y="Attachment", title="NBody Granularity (tampi+send+oss+task | numactl ON | 4 Nodes): Time", 
    subtitle=input_file, color = "Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("time-numactl.heatmap.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time-numactl.heatmap.pdf", plot=p, width=w, height=h, dpi=dpi)

p = ggplot(dfNonuma, aes(x=blocksize, y=attachment, fill=median.time)) +
  geom_raster() + 
  scale_fill_viridis(option="plasma") +
  coord_fixed() +
  theme_bw() +
  labs(x="Blocksize", y="Attachment", title="NBody Granularity (tampi+send+oss+task | 4 Nodes): Time", 
    subtitle=input_file, color = "Rank Attachment") + 
  theme(plot.subtitle=element_text(size=5)) +
  theme(legend.position="bottom") +
  scale_color_manual(labels = c("RanksPerNode", "RanksPerSocket"), values=c("blue", "red"))

ggsave("time.heatmap.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.heatmap.pdf", plot=p, width=w, height=h, dpi=dpi)
