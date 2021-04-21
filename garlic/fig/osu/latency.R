library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(stringr)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }
if (length(args)>1) { output = args[2] } else { output = "?" }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.unitName, config.nodes, config.ntasksPerNode, config.cpusPerTask, size, latency) %>%
	rename(unitName=config.unitName) %>%
  mutate(unitName=str_replace(unitName, "osu-latency-", ""))

nodes = unique(df$config.nodes)
tasksPerNode = unique(df$config.ntasksPerNode)
cpusPerTask = unique(df$config.cpusPerTask)
df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)

df = group_by(df, unitName, sizeFactor) %>%
  mutate(medianLatency = median(latency)) %>%
  ungroup()

breaks = 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

ppi=300
h=3
w=6

p = ggplot(data=df, aes(x=size, y=medianLatency)) +
	labs(x="Message size", y="Median latency (µs)",
    #title=sprintf("OSU benchmark: osu_latency", nodes, tasksPerNode, cpusPerTask), 
    subtitle=gsub("-", "\uad", output)) +
	geom_line(aes(linetype=unitName)) +
	geom_point(aes(shape=unitName), size=2) +
	scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
  scale_x_continuous(trans=log2_trans(),
    labels=label_bytes("auto_binary"),
    n.breaks = 12)+
  scale_shape_discrete(name = "MPI version") +
  scale_linetype_discrete(name = "MPI version") +
	theme_bw() +
  theme(plot.subtitle = element_text(size=8, family="mono")) +
	theme(legend.justification = c(0,1), legend.position = c(0.01, 0.99)) +
  theme(axis.text.x = element_text(angle=-45, hjust=0))

ggsave("median-lines.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("median-lines.pdf", plot=p, width=w, height=h, dpi=ppi)

p = ggplot(data=df, aes(x=size, y=latency)) +
	labs(x="Size (bytes)", y="Latency (us)",
    #title=sprintf("OSU benchmark: osu_latency", nodes, tasksPerNode, cpusPerTask), 
    subtitle=output) +
	geom_line(aes(y=medianLatency, linetype=unitName, group=unitName)) +
	geom_point(aes(shape=unitName), size=2) +
	scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
  scale_x_continuous(trans=log2_trans(),
    labels=label_bytes("auto_binary"),
    breaks=unique(df$size),
    minor_breaks=NULL) +
	theme_bw() +
  theme(plot.subtitle = element_text(color="gray50")) +
  theme(axis.text.x = element_text(angle=-45, hjust=0)) +
	theme(legend.position = c(0.2, 0.8))

ggsave("latency.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("latency.pdf", plot=p, width=w, height=h, dpi=ppi)
