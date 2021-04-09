library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(stringr)
#library(extrafont)
#library(Cairo)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

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
    #title=sprintf("OSU benchmark: osu_bw", nodes, tasksPerNode, cpusPerTask), 
    subtitle=gsub("-", "\uad", input_file)) +
	geom_line(aes(linetype=unitName)) +
	geom_point(aes(shape=unitName), size=1.5) +
  scale_shape_discrete(name = "MPI version") +
  scale_linetype_discrete(name = "MPI version") +
  #scale_color_discrete(name = "MPI version") +
  geom_hline(yintercept=12.5, color="red") +
  annotate("text", x=1, y=12.5 * .95,
    label="Max: 12.5GB/s (100Gbps)",
    hjust=0, vjust=1, size=3) +
	#scale_x_continuous(trans=log2_trans()) +
  scale_x_continuous(trans=log2_trans(),
    labels=label_bytes("auto_binary"),
    n.breaks = 12,
    #breaks=unique(df$size),
    #minor_breaks=NULL
  ) +
	#scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
  theme(plot.subtitle = element_text(size=8, family="mono")) +
	theme(legend.justification = c(1,0), legend.position = c(0.99, 0.01)) +
  theme(axis.text.x = element_text(angle=-45, hjust=0))

ggsave("median-lines.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("median-lines.pdf", plot=p, width=w, height=h, dpi=ppi)
#ggsave("median-lines-cairo.pdf", plot=p, width=w, height=h, dpi=ppi, device=cairo_pdf)
#CairoPDF(file="median-lines-Cairo.pdf", width=w, height=h)
#print(p)
#dev.off()


p = ggplot(data=df, aes(x=size, y=bw)) +
	labs(x="Message size", y="Bandwidth (MB/s)",
    #title=sprintf("OSU benchmark: osu_bw", nodes, tasksPerNode, cpusPerTask),
    subtitle=input_file) +
	geom_line(aes(y=median.bw, linetype=unitName, group=unitName)) +
	geom_point(aes(shape=unitName), size=2) +
  scale_shape(solid = FALSE) +
  geom_hline(yintercept = 100e3 / 8, color="red") +
  annotate("text", x = 8, y = (100e3 / 8) * 0.95,
    label = "Max: 12.5GB/s (100Gbps)") +
	#scale_x_continuous(trans=log2_trans()) +
  scale_x_continuous(trans=log2_trans(),
    labels=label_bytes("auto_binary"),
    breaks=unique(df$size),
    minor_breaks=NULL) +
	#scale_y_log10(breaks = breaks, minor_breaks = minor_breaks) +
	theme_bw() +
  theme(plot.subtitle = element_text(size=4)) +
	theme(legend.position = c(0.2, 0.6)) +
  theme(axis.text.x = element_text(angle=-45, hjust=0))

ggsave("bw.png", plot=p, width=w, height=h, dpi=ppi)
ggsave("bw.pdf", plot=p, width=w, height=h, dpi=ppi)

warnings()
