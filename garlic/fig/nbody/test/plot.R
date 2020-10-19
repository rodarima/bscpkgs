library(ggplot2)
library(dplyr)
library(scales)

# Load the dataset
df=read.table("data.csv", col.names=c("blocksize", "time"))

bs_unique = unique(df$blocksize)
nbs=length(bs_unique)

# Normalize the time by the median
D=group_by(df, blocksize) %>%
	mutate(tnorm = time / median(time) - 1) # %>%
#	mutate(bad = (abs(tnorm) >= 0.01)) %>%
#	mutate(color = ifelse(bad,"red","black"))

D$bad = cut(abs(D$tnorm), breaks=c(-Inf, 0.01, +Inf), labels=c("good", "bad"))

print(D)

#ppi=300
#h=5
#w=5
#png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
#
# Create the plot with the normalized time vs blocksize
p = ggplot(D, aes(x=blocksize, y=tnorm)) +

	# Labels
	labs(x="Block size", y="Normalized time",
              title="Nbody normalized time",
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
#
## Save the png image
#dev.off()
#
#png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)

## Create the plot with the normalized time vs blocksize
#p = ggplot(D, aes(x=blocksize, y=time, color=bad)) +
#
#	labs(x="Blocksize", y="Time (s)",
#              title="Nbody granularity",
#              subtitle="@expResult@") +
#
#	geom_point(shape=21, size=1.5) +
#	scale_color_manual(values=c("black", "red")) +
#	scale_x_continuous(trans=log2_trans(),
#			   breaks=bs_unique) +
#	scale_y_continuous(trans=log2_trans())
#
## Render the plot
#print(p)

# Save the png image
#dev.off()
