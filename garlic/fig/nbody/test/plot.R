library(ggplot2)
library(dplyr)
library(scales)

# Load the dataset
df=read.table("data.csv", col.names=c("blocksize", "time"))

bs_unique = unique(df$blocksize)
nbs=length(bs_unique)

# Normalize the time by the median
D=group_by(df, blocksize) %>% mutate(tnorm = time / median(time) - 1)

ppi=300
h=5
w=5
png("box.png", width=w*ppi, height=h*ppi, res=ppi)

# Create the plot with the normalized time vs blocksize
p = ggplot(D, aes(x=blocksize, y=tnorm)) +

	# Labels
	labs(x="Blocksize", y="Normalized time",
              title="Nbody granularity",
              subtitle="@expResult@") +

	# Center the title
	#theme(plot.title = element_text(hjust = 0.5)) +

	# Black and white mode (useful for printing)
	#theme_bw() +

	# Draw boxplots
	geom_boxplot(aes(group=blocksize)) +

	# Use log2 scale in x
	scale_x_continuous(trans=log2_trans(),
			   breaks=bs_unique) +

	scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +

	# Add the maximum allowed error lines
	geom_hline(yintercept=c(-0.01, 0.01),
		linetype="dashed", color="red")

# Render the plot
print(p)

# Save the png image
dev.off()

D=group_by(df, blocksize) %>% mutate(tnorm = time / median(time) - 1)

png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)

# Create the plot with the normalized time vs blocksize
p = ggplot(D, aes(x=blocksize, y=time)) +

	labs(x="Blocksize", y="Time (s)",
              title="Nbody granularity",
              subtitle="@expResult@") +

	geom_point(
		   #position=position_jitter(width=0.2, heigh=0)
		   shape=21, size=1.5) +
	scale_x_continuous(trans=log2_trans(),
			   breaks=bs_unique) +
	scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()
