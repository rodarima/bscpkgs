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
df = select(dataset, config.unitName, size, latency) %>%
	rename(unitName=config.unitName)

df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)

ppi=300
h=8
w=12

png("latency.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(data=df, aes(x=size, y=latency)) +
	labs(x="Size (bytes)", y="Latency (us)",
              title="OSU latency benchmark", 
              subtitle=input_file) +
	geom_boxplot(aes(color=unitName, group=interaction(unitName, sizeFactor))) +
	scale_y_continuous(trans=log10_trans()) +
	scale_x_continuous(trans=log2_trans()) +
	theme_bw() +
	theme(legend.position = c(0.15, 0.9))

# Render the plot
print(p)

## Save the png image
dev.off()
