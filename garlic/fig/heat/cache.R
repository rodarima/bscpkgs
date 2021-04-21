library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)
library(viridis)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }
if (length(args)>1) { output = args[2] } else { output = "?" }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.cbs, config.rbs, perf.cache_misses, perf.instructions, perf.cycles, time) %>%
	rename(cbs=config.cbs, rbs=config.rbs)

df$cbs = as.factor(df$cbs)
df$rbs = as.factor(df$rbs)

# Normalize the time by the median
df=group_by(df, cbs, rbs) %>%
	mutate(median.time = median(time)) %>%
	mutate(log.median.time = log(median.time)) %>%
	mutate(median.misses = median(perf.cache_misses)) %>%
	mutate(log.median.misses = log(median.misses)) %>%
	mutate(median.instr= median(perf.instructions)) %>%
	mutate(log.median.instr= log(median.instr)) %>%
	mutate(median.cycles = median(perf.cycles)) %>%
	mutate(median.cpi = median.cycles / median.instr) %>%
	mutate(median.ipc = median.instr / median.cycles) %>%
	mutate(median.ips = median.instr / median.time) %>%
	mutate(median.cps = median.cycles / median.time) %>%
  ungroup()# %>%

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
      subtitle=output) +
    theme(legend.position="bottom")

  k=1
  ggsave(sprintf("%s.png", colname), plot=p, width=4.8*k, height=5*k, dpi=300)
  ggsave(sprintf("%s.pdf", colname), plot=p, width=4.8*k, height=5*k, dpi=300)
}

heatmap_plot(df, "median.misses", "cache misses")
heatmap_plot(df, "log.median.misses", "cache misses")
heatmap_plot(df, "median.instr", "instructions")
heatmap_plot(df, "log.median.instr", "instructions")
heatmap_plot(df, "median.cycles", "cycles")
heatmap_plot(df, "median.ipc", "IPC")
heatmap_plot(df, "median.cpi", "cycles/instruction")
heatmap_plot(df, "median.ips", "instructions/second")
heatmap_plot(df, "median.cps", "cycles/second")

cutlevel = 0.5
# To plot the median.time we crop the larger values:
df_filtered = filter(df, between(median.time,
  median(time) - (cutlevel * sd(time)),
  median(time) + (cutlevel * sd(time))))

heatmap_plot(df_filtered, "median.time", "execution time (seconds)")
heatmap_plot(df_filtered, "log.median.time", "execution time")
