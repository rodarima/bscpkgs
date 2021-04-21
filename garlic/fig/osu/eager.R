library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }
if (length(args)>1) { output = args[2] } else { output = "?" }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset,
	    config.unitName,
	    config.nodes,
	    config.ntasksPerNode,
	    config.cpusPerTask,
	    config.PSM2_MQ_EAGER_SDMA_SZ,
	    size, bw, config.iterations) %>%
	rename(unitName=config.unitName,
	       iterations=config.iterations,
	       PSM2_MQ_EAGER_SDMA_SZ=config.PSM2_MQ_EAGER_SDMA_SZ)

nodes = unique(df$config.nodes)
tasksPerNode = unique(df$config.ntasksPerNode)
cpusPerTask = unique(df$config.cpusPerTask)
df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)
df$sizeKB = df$size / 1024
df$PSM2_MQ_EAGER_SDMA_SZ.f = as.factor(df$PSM2_MQ_EAGER_SDMA_SZ)

iterations = unique(df$iterations)

df = group_by(df, unitName, sizeFactor) %>%
  mutate(medianBw = median(bw)) %>%
  ungroup()

breaks = 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

ppi=150
h=6
w=8

p = ggplot(data=df, aes(x=sizeKB, y=bw)) +
  labs(x="Message size (KB)", y="Bandwidth (MB/s)",
    title=sprintf("OSU benchmark: osu_bw --iterations %d", iterations), 
    subtitle=output) +
  geom_point(shape=21, size=3) +
  geom_vline(aes(xintercept = PSM2_MQ_EAGER_SDMA_SZ/1024), color="blue") +
  geom_vline(xintercept = 10, color="red") +
  annotate("text", x = 10.2, y = 8.5e3, label = "MTU = 10KB", color="red", hjust=0) +
  facet_wrap(vars(PSM2_MQ_EAGER_SDMA_SZ.f), nrow=3, labeller = "label_both") +
  scale_x_continuous(breaks = unique(df$sizeKB), minor_breaks=NULL) +
  theme_bw()

ggsave("bw.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("bw.pdf", plot=p, width=w, height=h, dpi=ppi)
