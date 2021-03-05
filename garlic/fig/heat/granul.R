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
df = select(dataset, config.cbs, config.rbs, time) %>%
	rename(cbs=config.cbs, rbs=config.rbs)

df$cbs = as.factor(df$cbs)
df$rbs = as.factor(df$rbs)

# Normalize the time by the median
df=group_by(df, cbs, rbs) %>%
	mutate(mtime = median(time)) %>%
	mutate(tnorm = time / mtime - 1) %>%
	mutate(logmtime = log(mtime)) %>%
  ungroup() %>%
  filter(between(mtime, mean(time) - (1 * sd(time)),
    mean(time) + (1 * sd(time))))

ppi=300
h=5
w=5

png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
#
# Create the plot with the normalized time vs nblocks
p = ggplot(data=df, aes(x=cbs, y=tnorm)) +

	# Labels
	labs(x="cbs", y="Normalized time",
              title=sprintf("Heat normalized time"), 
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
p = ggplot(df, aes(x=cbs, y=time, linetype=rbs, group=rbs)) +

	labs(x="cbs", y="Time (s)",
              title=sprintf("Heat granularity"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = c(0.5, 0.88)) +

	geom_point(shape=21, size=3) +
	geom_line(aes(y=mtime)) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()


png("heatmap.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(df, aes(x=cbs, y=rbs, fill=logmtime)) +
	geom_raster() +
  scale_fill_gradient(high="black", low="white") +
  coord_fixed() +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	labs(x="cbs", y="rbs",
    title=sprintf("Heat granularity"), 
    subtitle=input_file)

# Render the plot
print(p)

# Save the png image
dev.off()
