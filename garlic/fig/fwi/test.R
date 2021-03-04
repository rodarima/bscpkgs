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
df = select(dataset, config.blocksize, config.gitBranch, time) %>%
	rename(blocksize=config.blocksize, gitBranch=config.gitBranch) %>%
  group_by(blocksize, gitBranch) %>%
  mutate(mtime = median(time)) %>%
  ungroup()

df$gitBranch = as.factor(df$gitBranch)
df$blocksize = as.factor(df$blocksize)

ppi=300
h=5
w=5

png("time.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(df, aes(x=blocksize, y=time)) +
	geom_point() +
	geom_line(aes(y=mtime, group=gitBranch, color=gitBranch)) +
	theme_bw() +
	labs(x="Blocksize", y="Time (s)", title="FWI granularity",
    subtitle=input_file) +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = c(0.5, 0.88))

# Render the plot
print(p)

# Save the png image
dev.off()
