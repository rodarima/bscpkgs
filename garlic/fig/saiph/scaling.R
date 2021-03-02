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
df = select(dataset, config.nby, config.nodes, time, total_time, config.gitCommit) %>%
	rename(nby=config.nby, nnodes=config.nodes, gitCommit=config.gitCommit)

df$nby = as.factor(df$nby)
df$nodes = as.factor(df$nnodes)
df$gitCommit = as.factor(df$gitCommit)

# Normalize the time by the median
D=group_by(df, nby, nodes, gitCommit) %>%
	mutate(tmedian = median(time)) %>%
	mutate(ttmedian = median(total_time)) %>%
	mutate(tnorm = time / tmedian - 1) %>%
	mutate(bad = max(ifelse(abs(tnorm) >= 0.01, 1, 0))) %>%
	mutate(tn = tmedian * nnodes) %>%
  ungroup()

D$bad = as.factor(D$bad)


print(D)

ppi=300
h=5
w=8

png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
#
# Create the plot with the normalized time vs nblocks
p = ggplot(data=D, aes(x=nby, y=tnorm, color=bad)) +

	# Labels
	labs(x="nby", y="Normalized time",
              title=sprintf("Saiph-Heat3D normalized time"), 
              subtitle=input_file) +

	# Center the title
	#theme(plot.title = element_text(hjust = 0.5)) +

	# Black and white mode (useful for printing)
	#theme_bw() +

	# Add the maximum allowed error lines
	geom_hline(yintercept=c(-0.01, 0.01),
		linetype="dashed", color="gray") +

	# Draw boxplots
	geom_boxplot() +
	scale_color_manual(values=c("black", "brown")) +

	#scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +

	theme_bw() +

	theme(plot.subtitle=element_text(size=8)) +
        theme(legend.position = "none")
	#theme(legend.position = c(0.85, 0.85))




# Render the plot
print(p)

## Save the png image
dev.off()
#
png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(D, aes(x=nby, y=time)) +

	labs(x="nby", y="Time (s)",
              title=sprintf("Saiph-Heat3D granularity"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = c(0.5, 0.88)) +

	geom_point(aes(color=nodes), shape=21, size=3) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans()) +
	facet_wrap( ~ gitCommit)


# Render the plot
print(p)

# Save the png image
dev.off()

png("wasted.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(D, aes(x=nby, y=time)) +

	labs(x="nby", y="Time (s)",
              title=sprintf("Saiph-Heat3D granularity"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +

	geom_point(shape=21, size=3) +
	geom_point(aes(y=total_time), shape=1, size=3, color="red") +
  geom_line(aes(y=tmedian, color=nodes, group=nodes)) +
  geom_line(aes(y=ttmedian, color=nodes, group=nodes)) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans()) +
	facet_wrap( ~ gitCommit)

# Render the plot
print(p)

# Save the png image
dev.off()

png("test.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(D, aes(x=nby, y=tn)) +

	labs(x="nby", y="Time (s) * nodes",
              title=sprintf("Saiph-Heat3D granularity"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +

	geom_point(shape=21, size=3) +
  geom_line(aes(color=nodes, group=nodes)) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans()) +
	facet_wrap( ~ gitCommit)

# Render the plot
print(p)

# Save the png image
dev.off()
