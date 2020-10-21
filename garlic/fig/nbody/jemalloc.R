library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "timetable.json.gz"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
	jsonlite::flatten()

# We only need the cpu bind, blocksize and time
df = select(dataset, config.enableJemalloc, config.blocksize, time) %>%
	rename(blocksize=config.blocksize,
	       jemalloc=config.enableJemalloc)

# Use the blocksize as factor
df$blocksize = as.factor(df$blocksize)
df$jemalloc = as.factor(df$jemalloc)

# Split by malloc variant
D=df %>% group_by(jemalloc, blocksize) %>%
	mutate(tnorm = time / median(time) - 1)

bs_unique = unique(df$blocksize)
nbs=length(bs_unique)


print(D)

ppi=300
h=5
w=5

png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
#
# Create the plot with the normalized time vs blocksize
p = ggplot(data=D, aes(x=blocksize, y=tnorm)) +

	# Labels
	labs(x="Block size", y="Normalized time",
              title="Nbody normalized time",
              subtitle=input_file) +

	# Center the title
	#theme(plot.title = element_text(hjust = 0.5)) +

	# Black and white mode (useful for printing)
	#theme_bw() +

	# Add the maximum allowed error lines
	geom_hline(yintercept=c(-0.01, 0.01),
		linetype="dashed", color="red") +

	# Draw boxplots
	geom_boxplot(aes(fill=jemalloc)) +

#	# Use log2 scale in x
#	scale_x_continuous(trans=log2_trans(),
#			   breaks=bs_unique) +
#
	scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +

	theme_bw() +

	theme(plot.subtitle=element_text(size=8)) +

	theme(legend.position = c(0.85, 0.85)) #+

	# Place each variant group in one separate plot
	#facet_wrap(~jemalloc)



# Render the plot
print(p)

## Save the png image
dev.off()
#
png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs blocksize
p = ggplot(D, aes(x=blocksize, y=time, color=jemalloc)) +

	labs(x="Block size", y="Time (s)",
              title="Nbody granularity",
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +

	geom_point(shape=21, size=3) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()
