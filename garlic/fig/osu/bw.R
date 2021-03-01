library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.unitName, config.nodes, config.ntasksPerNode, config.cpusPerTask, size, bw) %>%
	rename(unitName=config.unitName)

nodes = unique(df$config.nodes)
tasksPerNode = unique(df$config.ntasksPerNode)
cpusPerTask = unique(df$config.cpusPerTask)
df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)

ppi=300
h=8
w=12

png("bw.png", width=w*ppi, height=h*ppi, res=ppi)

breaks = 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

p = ggplot(data=df, aes(x=size, y=bw)) +
	labs(x="Size (bytes)", y="Bandwidth (MB/s)",
              title=sprintf("OSU bandwidth benchmark: nodes=%d tasksPerNode=%d cpusPerTask=%d",
			    nodes, tasksPerNode, cpusPerTask), 
              subtitle=input_file) +
	geom_boxplot(aes(color=unitName, group=interaction(unitName, sizeFactor))) +
	scale_x_continuous(trans=log2_trans()) +
	scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
	theme(legend.position = c(0.15, 0.9))

# Render the plot
print(p)

## Save the png image
dev.off()
