library(ggplot2)
library(dplyr)
library(scales)

# Load the dataset
#df=read.table("/nix/store/zcyazjbcjn2lhxrpa3bs5y7rw3bbcgnr-plot/data.csv",
df=read.table("data.csv",
	      col.names=c("variant", "blocksize", "time"))

# Use the blocksize as factor
df$blocksize = as.factor(df$blocksize)

# Split by malloc variant

D=df %>% group_by(variant, blocksize) %>%
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
              subtitle="@expResult@/data.csv") +

	# Center the title
	#theme(plot.title = element_text(hjust = 0.5)) +

	# Black and white mode (useful for printing)
	#theme_bw() +

	# Add the maximum allowed error lines
	geom_hline(yintercept=c(-0.01, 0.01),
		linetype="dashed", color="red") +

	# Draw boxplots
	geom_boxplot(aes(fill=variant)) +

#	# Use log2 scale in x
#	scale_x_continuous(trans=log2_trans(),
#			   breaks=bs_unique) +
#
	scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +

	theme_bw() +

	theme(plot.subtitle=element_text(size=10)) +

	theme(legend.position = c(0.85, 0.85)) #+

	# Place each variant group in one separate plot
	#facet_wrap(~variant)



# Render the plot
print(p)

## Save the png image
dev.off()
#
png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs blocksize
p = ggplot(D, aes(x=blocksize, y=time, color=variant)) +

	labs(x="Block size", y="Time (s)",
              title="Nbody granularity",
              subtitle="@expResult@") +
	theme_bw() +

	geom_point(shape=21, size=3) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()
