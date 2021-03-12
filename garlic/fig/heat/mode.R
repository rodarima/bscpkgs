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
df = select(dataset, config.cbs, config.rbs,
    ctf_mode.runtime,
    ctf_mode.task,
    ctf_mode.dead,
    time) %>%
	rename(
    cbs=config.cbs,
    rbs=config.rbs,
    runtime=ctf_mode.runtime,
    task=ctf_mode.task,
    dead=ctf_mode.dead,
  )

df$cbs = as.factor(df$cbs)
df$rbs = as.factor(df$rbs)

# Normalize the time by the median
df = df %>%
	mutate(runtime = runtime * 1e-9) %>%
	mutate(dead = dead * 1e-9) %>%
	mutate(task = task * 1e-9) %>%
  group_by(cbs, rbs) %>%
	mutate(median.time = median(time)) %>%
	mutate(log.median.time = log(median.time)) %>%
	mutate(median.dead = median(dead)) %>%
	mutate(median.runtime = median(runtime)) %>%
	mutate(median.task = median(task)) %>%
  ungroup()# %>%

print(df)

heatmap_plot = function(df, colname, title) {
  p = ggplot(df, aes(x=cbs, y=rbs, fill=!!ensym(colname))) +
    geom_raster() +
    #scale_fill_gradient(high="black", low="white") +
    scale_fill_viridis(option="plasma") +
    coord_fixed() +
    theme_bw() +
    theme(axis.text.x=element_text(angle = -45, hjust = 0)) +
    theme(plot.subtitle=element_text(size=8)) +
    #guides(fill = guide_colorbar(barwidth=15, title.position="top")) +
    guides(fill = guide_colorbar(barwidth=12, title.vjust=0.8)) +
    labs(x="cbs", y="rbs",
      title=sprintf("Heat granularity: %s", title), 
      subtitle=input_file) +
    theme(legend.position="bottom")

  k=1
  ggsave(sprintf("%s.png", colname), plot=p, width=4.8*k, height=5*k, dpi=300)
  ggsave(sprintf("%s.pdf", colname), plot=p, width=4.8*k, height=5*k, dpi=300)
}

heatmap_plot(df, "median.runtime", "runtime")
heatmap_plot(df, "median.dead", "not used")
heatmap_plot(df, "median.task", "task")

cutlevel = 0.5
# To plot the median.time we crop the larger values:
df_filtered = filter(df, between(median.time,
  median(time) - (cutlevel * sd(time)),
  median(time) + (cutlevel * sd(time))))

heatmap_plot(df, "median.time", "execution time (seconds)")
heatmap_plot(df, "log.median.time", "execution time")
