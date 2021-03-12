library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)
library(viridis)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
	jsonlite::flatten()


# We only need the nblocks and time
#df = select(dataset, config.nbly, config.nodes, time, total_time, config.gitCommit) %>%
#	rename(nbly=config.nbly, nnodes=config.nodes, gitCommit=config.gitCommit)

df = select(dataset, config.nbly, config.nblz, config.nbltotal, config.nodes, time, total_time) %>%
	rename(nbly=config.nbly, nblz=config.nblz, nbltotal=config.nbltotal, nnodes=config.nodes)

df2 = df[df$nblz == 1 | df$nblz == 2 | df$nblz == 4, ]
df3 = df[df$nbly == 1 | df$nbly == 2 | df$nbly == 4, ]

# df2 data frame
df2$nblsetZ     = as.factor(df2$nblz)
df2$nblPerProcZ = as.factor(df2$nbltotal / 24)
df2$nbltotal    = as.factor(df2$nbltotal)
df2$nodes       = as.factor(df2$nnodes)

# df3 data frame
df3$nblsetY     = as.factor(df3$nbly)
df3$nblPerProcY = as.factor(df3$nbltotal / 24)
df3$nbltotalY   = as.factor(df3$nbltotal)
df3$nodes       = as.factor(df3$nnodes)

df$nbly = as.factor(df$nbly)
df$nblz = as.factor(df$nblz)
df$nblPerProc = as.factor(df$nbltotal / 24)
df$nbltotal = as.factor(df$nbltotal)
df$nodes = as.factor(df$nnodes)
#df$gitCommit = as.factor(df$gitCommit)

# Normalize the time by the median
#D=group_by(df, nbly, nodes, gitCommit) %>%
D=group_by(df, nbly, nblz, nbltotal, nodes) %>%
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


png("scatter_nbly.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot() +
	geom_point(data=df2, aes(x=nblPerProcZ, y=time, color=nblsetZ), shape=21, size=3, show.legend=TRUE) +
	geom_point(data=df3, aes(x=nblPerProcY, y=time, color=nblsetY), shape=4,  size=2, show.legend=TRUE) +
	labs(x="nblPerProc", y="Time (s)",
              title=sprintf("Saiph-Heat3D granularity per nodes"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = c(0.5, 0.5)) +
	scale_y_continuous(trans=log2_trans()) +
	facet_wrap( ~ nodes)


# Render the plot
print(p)

# Save the png image
dev.off()







png("scatter_nbly.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot() +
	geom_point(data=df2, aes(x=nblPerProcZ, y=time, color=nblsetZ), shape=21, size=3, show.legend=TRUE) +
	geom_point(data=df3, aes(x=nblPerProcY, y=time, color=nblsetY), shape=4,  size=2, show.legend=TRUE) +
	labs(x="nblPerProc", y="Time (s)",
              title=sprintf("Saiph-Heat3D granularity per nodes"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = c(0.5, 0.5)) +
	scale_y_continuous(trans=log2_trans()) +
	facet_wrap( ~ nodes)


# Render the plot
print(p)

# Save the png image
dev.off()

png("test1.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot(D, aes(x=nblPerProc, y=tn)) +

	labs(x="nblPerProc", y="Time (s) * nodes",
              title=sprintf("Saiph-Heat3D granularity per nbly blocks"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +

	geom_point(shape=21, size=3) +
  geom_line(aes(color=nodes, group=nodes)) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans()) +
	facet_wrap( ~ nbly)

# Render the plot
print(p)

# Save the png image
dev.off()


heatmap_plot = function(df, colname, title) {
  p = ggplot(df, aes(x=nbly, y=nblz, fill=!!ensym(colname))) +
    geom_raster() +
    #scale_fill_gradient(high="black", low="white") +
    scale_fill_viridis(option="plasma") +
    coord_fixed() +
    theme_bw() +
    theme(axis.text.x=element_text(angle = -45, hjust = 0)) +
    theme(plot.subtitle=element_text(size=8)) +
    #guides(fill = guide_colorbar(barwidth=15, title.position="top")) +
    guides(fill = guide_colorbar(barwidth=12, title.vjust=0.8)) +
    labs(x="nbly", y="nblz",
      title=sprintf("Heat granularity: %s", title), 
      subtitle=input_file) +
    theme(legend.position="bottom")+
    facet_wrap( ~ nodes)

  k=1
  ggsave(sprintf("%s.png", colname), plot=p, width=4.8*k, height=5*k, dpi=300)
  ggsave(sprintf("%s.pdf", colname), plot=p, width=4.8*k, height=5*k, dpi=300)
}

heatmap_plot(D, "tmedian", "time")
