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
	    config.PSM2_MTU,
	    size, bw, config.iterations) %>%
	rename(unitName=config.unitName,
	       iterations=config.iterations,
	       PSM2_MQ_EAGER_SDMA_SZ.val=config.PSM2_MQ_EAGER_SDMA_SZ,
	       PSM2_MTU.val=config.PSM2_MTU) %>%
  mutate(bw = bw / 1000.0)

nodes = unique(df$config.nodes)
tasksPerNode = unique(df$config.ntasksPerNode)
cpusPerTask = unique(df$config.cpusPerTask)
df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)
df$sizeKB = df$size / 1024
df$PSM2_MQ_EAGER_SDMA_SZ = as.factor(df$PSM2_MQ_EAGER_SDMA_SZ.val)
df$PSM2_MTU = as.factor(df$PSM2_MTU.val)

iterations = unique(df$iterations)

df = group_by(df, unitName, sizeFactor) %>%
  mutate(median.bw = median(bw)) %>%
  ungroup()

breaks = 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

ppi=300
h=3
w=6

p = ggplot(data=df, aes(x=sizeKB, y=bw)) +
  geom_vline(aes(xintercept = PSM2_MQ_EAGER_SDMA_SZ.val/1024), color="blue") +
  geom_vline(aes(xintercept = PSM2_MTU.val/1024), color="red") +
  labs(x="Message size (KiB)", y="Bandwidth (GB/s)",
    #title=sprintf("OSU benchmark: osu_bw --iterations %d", iterations), 
    subtitle=gsub("-", "\uad", output)) +
  geom_point(shape=21, size=2) +
  #annotate("text", x = 10.2, y = 8.5e3, label = "MTU = 10KB", color="red", hjust=0) +
  facet_wrap(vars(PSM2_MTU), nrow=3, labeller = "label_both") +
  #scale_x_continuous(breaks = unique(df$sizeKB), minor_breaks=NULL) +
  scale_x_continuous(n.breaks = 12) +
  theme_bw() +
  theme(plot.subtitle = element_text(size=8, family="mono"))

ggsave("bw.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("bw.pdf", plot=p, width=w, height=h, dpi=ppi)
