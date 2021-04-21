library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }
if (length(args)>1) { output = args[2] } else { output = "?" }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.unitName, config.nodes, config.ntasksPerNode, config.cpusPerTask, config.threshold, size, bw) %>%
	rename(unitName=config.unitName) %>%
  rename(threshold=config.threshold)

nodes = unique(df$config.nodes)
tasksPerNode = unique(df$config.ntasksPerNode)
cpusPerTask = unique(df$config.cpusPerTask)
df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)
df$threshold = as.factor(df$threshold)

df = group_by(df, unitName, sizeFactor) %>%
  mutate(medianBw = median(bw)) %>%
  ungroup()

breaks = 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

p = ggplot(data=df, aes(x=size, y=bw)) +
	labs(x="Size (bytes)", y="Bandwidth (MB/s)",
              title=sprintf("OSU bandwidth benchmark: nodes=%d tasksPerNode=%d cpusPerTask=%d",
			    nodes, tasksPerNode, cpusPerTask), 
              subtitle=output) +
	geom_boxplot(aes(color=threshold, group=interaction(threshold, sizeFactor))) +
	scale_x_continuous(trans=log2_trans()) +
	#scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
	theme(legend.position = c(0.8, 0.2))

ppi=300
h=4
w=8
ggsave("boxplot.pdf", plot=p, width=w, height=h, dpi=ppi)
ggsave("boxplot.png", plot=p, width=w, height=h, dpi=ppi)

p = ggplot(data=df, aes(x=size, y=medianBw)) +
	labs(x="Size (bytes)", y="Bandwidth (MB/s)",
              title=sprintf("OSU benchmark: osu_bw",
			    nodes, tasksPerNode, cpusPerTask), 
              subtitle=output) +
	geom_line(aes(color=threshold, linetype=threshold)) +
	geom_point(aes(color=threshold, shape=threshold)) +
  geom_hline(yintercept = 100e3 / 8, color="red") +
  annotate("text", x = 8, y = (100e3 / 8) * 0.95, label = "12.5GB/s (100Gb/s)") +
	scale_x_continuous(trans=log2_trans()) +
	#scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
	theme(legend.position = c(0.8, 0.2))

ggsave("median-lines.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("median-lines.pdf", plot=p, width=w, height=h, dpi=ppi)
