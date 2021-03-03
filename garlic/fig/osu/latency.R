library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.unitName, config.nodes, config.ntasksPerNode, config.cpusPerTask, size, latency) %>%
	rename(unitName=config.unitName)

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

p = ggplot(data=df, aes(x=size, y=latency)) +
	labs(x="Size (bytes)", y="Latency (us)",
              title=sprintf("OSU latency benchmark nodes=%d tasksPerNode=%d cpusPerTask=%d",
			    nodes, tasksPerNode, cpusPerTask), 
              subtitle=input_file) +
	geom_boxplot(aes(color=unitName, group=interaction(unitName, sizeFactor))) +
	scale_x_continuous(trans=log2_trans()) +
	scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
	theme(legend.position = c(0.8, 0.2))

ppi=300
h=4
w=8
ggsave("boxplot.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("boxplot.pdf", plot=p, width=w, height=h, dpi=ppi)

p = ggplot(data=df, aes(x=size, y=medianLatency)) +
	labs(x="Size (bytes)", y="Latency (us)",
              title=sprintf("OSU benchmark: osu_latency",
			    nodes, tasksPerNode, cpusPerTask), 
              subtitle=input_file) +
	geom_line(aes(color=unitName, linetype=unitName)) +
	geom_point(aes(color=unitName, shape=unitName)) +
	scale_x_continuous(trans=log2_trans()) +
	scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
	theme(legend.position = c(0.2, 0.8))

ggsave("median-lines.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("median-lines.pdf", plot=p, width=w, height=h, dpi=ppi)
