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

particles = unique(dataset$config.particles)

# We only need the nblocks and time
df = select(dataset, config.nblocks, config.hw.cpusPerSocket, time) %>%
	rename(nblocks=config.nblocks,
		cpusPerSocket=config.hw.cpusPerSocket)

df = df %>% mutate(blocksPerCpu = nblocks / cpusPerSocket)
df$nblocks = as.factor(df$nblocks)
df$blocksPerCpuFactor = as.factor(df$blocksPerCpu)

# Normalize the time by the median
D=group_by(df, nblocks) %>%
	mutate(tnorm = time / median(time) - 1)

bs_unique = unique(df$nblocks)
nbs=length(bs_unique)

print(D)

ppi=300
h=5
w=5

png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
#
# Create the plot with the normalized time vs nblocks
p = ggplot(data=D, aes(x=blocksPerCpuFactor, y=tnorm)) +

	# Labels
	labs(x="Num blocks", y="Normalized time",
              title="HPCG normalized time", 
              subtitle=input_file) +

	# Center the title
	#theme(plot.title = element_text(hjust = 0.5)) +

	# Black and white mode (useful for printing)
	#theme_bw() +

	# Add the maximum allowed error lines
	geom_hline(yintercept=c(-0.01, 0.01),
		linetype="dashed", color="red") +

	# Draw boxplots
	geom_boxplot() +

	#scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +

	theme_bw() +

	theme(plot.subtitle=element_text(size=8)) +

	theme(legend.position = c(0.85, 0.85)) #+




# Render the plot
print(p)

## Save the png image
dev.off()
#
png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(D, aes(x=blocksPerCpuFactor, y=time)) +

	labs(x="Blocks/CPU", y="Time (s)",
              title="HPCG granularity", 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = c(0.5, 0.88)) +

	geom_point(shape=21, size=3) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()
