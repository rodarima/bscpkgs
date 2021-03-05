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
df = select(dataset, config.cbs, config.rbs, perf.cache_misses) %>%
	rename(cbs=config.cbs, rbs=config.rbs)

df$cbs = as.factor(df$cbs)
df$rbs = as.factor(df$rbs)

# Normalize the time by the median
df=group_by(df, cbs, rbs) %>%
	mutate(median.misses = median(perf.cache_misses)) %>%
	mutate(log.median.misses = log(median.misses)) %>%
  ungroup()

ppi=300
h=5
w=5


png("heatmap.png", width=1.5*w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(df, aes(x=cbs, y=rbs, fill=log.median.misses)) +
	geom_raster() +
  scale_fill_gradient(high="black", low="white") +
  coord_fixed() +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	labs(x="cbs", y="rbs",
    title=sprintf("Heat granularity: cache misses"), 
    subtitle=input_file)

# Render the plot
print(p)

# Save the png image
dev.off()
