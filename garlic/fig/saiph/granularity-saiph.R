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


# Create a data frame selecting the desired variables from the data set
df = select(dataset, config.nbly, config.nblz, config.nodes, time, total_time) %>%
        rename(nbly=config.nbly, nblz=config.nblz, nnodes=config.nodes)

# Declare variables as factors 
# --> R does not allow to operate with factors: operate before casting to factors
df$nblPerProc = as.factor(round((df$nbly * df$nblz) / 24, digits = 2))
df$biggernbly = as.factor(df$nbly > df$nblz)
df$nbly = as.factor(df$nbly)
df$nblz = as.factor(df$nblz)
df$nodes = as.factor(df$nnodes)

# Create a new data frame including statistics
D=group_by(df, nbly, nblz, nblPerProc, nodes) %>%
        mutate(tmedian = median(time)) %>%
        mutate(ttmedian = median(total_time)) %>%
        mutate(tnorm = time / tmedian - 1) %>%
        mutate(bad = max(ifelse(abs(tnorm) >= 0.01, 1, 0))) %>%
        mutate(tn = tmedian * nnodes) %>%
  ungroup()

D$bad = as.factor(D$bad)

### Std output data frame D
print(D)

### Output figure size
ppi=300
h=5
w=8

####################################################################
### Boxplot
####################################################################
png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
# Create the plot with the normalized time vs nblocks
p = ggplot(data=D, aes(x=nblPerProc, y=tnorm, color=bad)) +

        # Labels
        labs(x="nblPerProc", y="Normalized time",
              title=sprintf("Saiph-Heat3D normalized time"),
              subtitle=input_file) +
        # Add the maximum allowed error lines
        geom_hline(yintercept=c(-0.01, 0.01),
                linetype="dashed", color="gray") +

        # Draw boxplots
        geom_boxplot() +
        scale_color_manual(values=c("black", "brown")) +
        theme_bw() +
        theme(plot.subtitle=element_text(size=8)) +
        theme(legend.position = "none")


# Render the plot
print(p)

## Save the png image
dev.off()

####################################################################
### XY Scatter plot - measured_time & total_time vs tasks per cpu
####################################################################


####################################################################
### XY Scatter plot - time vs tasks per cpu
####################################################################
png("scatter.png", width=w*ppi, height=h*ppi, res=ppi)
## Create the plot with the normalized time vs nblocks per proc
p = ggplot(D, aes(x=nblPerProc, y=time)) +
        labs(x="nblPerProc", y="Time (s)",
              title=sprintf("Saiph-Heat3D granularity"),
              subtitle=input_file) +
        theme_bw() +
        theme(plot.subtitle=element_text(size=8)) +
        theme(legend.position = c(0.5, 0.88)) +
        geom_point(shape=21, size=3) + 
        scale_y_continuous(trans=log2_trans())


# Render the plot
print(p)

## Save the png image
dev.off()

####################################################################
### XY Scatter plot - median time vs tasks per cpu 
####################################################################
png("scatter2.png", width=w*ppi, height=h*ppi, res=ppi)
## Create the plot with the normalized time vs nblocks per proc
p = ggplot(D, aes(x=nblPerProc, y=tmedian)) +
        labs(x="nblPerProc", y="Median Time (s)",
              title=sprintf("Saiph-Heat3D granularity"),
              subtitle=input_file) +
        theme_bw() +
        theme(plot.subtitle=element_text(size=8)) +
        theme(legend.position = c(0.5, 0.88)) +
        geom_point(aes(color=biggernbly), shape=21, size=3) +
	labs(color = "nbly > nblz")
        scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()

####################################################################
### Heatmap plot - median time vs tasks per cpu per dimension
####################################################################
heatmap_plot = function(df, colname, title) {
  p = ggplot(df, aes(x=nbly, y=nblz, fill=!!ensym(colname))) +
    geom_raster() +
    #scale_fill_gradient(high="black", low="white") +
    scale_fill_viridis(option="plasma") +
    coord_fixed() +
    theme_bw() +
    theme(axis.text.x=element_text(angle = -45, hjust = 0)) +
    theme(plot.subtitle=element_text(size=8)) +
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

# call heatmap function with colname and legend title
heatmap_plot(D, "tmedian", "time")

