library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(stringr)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }
if (length(args)>1) { output = args[2] } else { output = "?" }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
	jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.unitName, config.nodes, config.ntasksPerNode, config.cpusPerTask, size, bw) %>%
	rename(unitName=config.unitName) %>%
  mutate(bw=bw / 1024.0) %>%
  mutate(unitName=str_replace(unitName, "osu-bw-", ""))

nodes = unique(df$config.nodes)
tasksPerNode = unique(df$config.ntasksPerNode)
cpusPerTask = unique(df$config.cpusPerTask)
df$unitName = as.factor(df$unitName)
df$sizeFactor = as.factor(df$size)

df = group_by(df, unitName, sizeFactor) %>%
  mutate(median.bw = median(bw)) %>%
  ungroup()

ppi=300
h=3
w=6

p = ggplot(data=df, aes(x=size, y=median.bw)) +
	labs(x="Message size", y="Bandwidth (GB/s)",
    subtitle=output) +
	geom_line(aes(linetype=unitName)) +
	geom_point(aes(shape=unitName), size=1.5) +
  scale_shape_discrete(name = "MPI version") +
  scale_linetype_discrete(name = "MPI version") +
  geom_hline(yintercept=12.5, color="red") +
  annotate("text", x=1, y=12.5 * .95,
    label="Max: 12.5GB/s (100Gbps)",
    hjust=0, vjust=1, size=3) +
  scale_x_continuous(trans=log2_trans(),
    labels=label_bytes("auto_binary"),
    n.breaks = 12,
  ) +
	theme_bw() +
  theme(plot.subtitle = element_text(size=8, family="mono")) +
	theme(legend.justification = c(1,0), legend.position = c(0.99, 0.01)) +
  theme(axis.text.x = element_text(angle=-45, hjust=0))

ggsave("median-lines.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("median-lines.pdf", plot=p, width=w, height=h, dpi=ppi)
