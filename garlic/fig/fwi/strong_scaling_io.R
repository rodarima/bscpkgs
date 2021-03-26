library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)
library(forcats)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
  jsonlite::flatten()

# We only need the nblocks and time
df = select(dataset, config.blocksize, config.ioFreq, config.gitBranch, config.nodes, time) %>%
  rename(
     blocksize=config.blocksize,
     io=config.ioFreq,
     gitBranch=config.gitBranch,
     nodes=config.nodes
  ) %>%
  filter(blocksize == 1) %>%
  group_by(nodes, gitBranch, io) %>%
  mutate(mtime = median(time)) %>%
  mutate(nxmtime = mtime * nodes) %>%
  mutate(nxtime = time * nodes) %>%
  ungroup()

df$gitBranch = as.factor(df$gitBranch)
df$io        = as.factor(df$io)
df$blocksize = as.factor(df$blocksize)
df$nodes     = as.factor(df$nodes)

df$io = fct_recode(df$io, enabled = "-1", disabled = "9999")


ppi=300
h=5
w=5

####################################################################
### Line plot (time)
####################################################################
png("time.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(df, aes(x=nodes, y=time, group=io, color=io)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Nodes", y="Time (s)", title="FWI strong scaling for mpi+send+oss+task",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position = c(0.5, 0.88))

# Render the plot
print(p)

# Save the png image
dev.off()

####################################################################
### Line plot (time x nodes)
####################################################################
png("nxtime.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(df, aes(x=nodes, y=nxtime, group=io, color=io)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Nodes", y="Time * Nodes (s)", title="FWI strong scaling for mpi+send+oss+task",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position = c(0.5, 0.88))

# Render the plot
print(p)

# Save the png image
dev.off()

#####################################################################
#### Line plot (median time)
#####################################################################
#png("mediantime.png", width=w*ppi, height=h*ppi, res=ppi)
#
#p = ggplot(df, aes(x=nodes, y=mtime, group=gitBranch, color=gitBranch)) +
#  geom_point() +
#  geom_line() +
#  theme_bw() +
#  labs(x="Nodes", y="Median Time (s)", title="FWI strong scaling",
#    subtitle=input_file) +
#  theme(plot.subtitle=element_text(size=8)) +
#  theme(legend.position = c(0.5, 0.88))
#
## Render the plot
#print(p)
#
## Save the png image
#dev.off()
#
#####################################################################
#### Line plot (nodes x median time)
#####################################################################
#png("nxmtime.png", width=w*ppi, height=h*ppi, res=ppi)
#
#p = ggplot(df, aes(x=nodes, y=nxmtime, group=gitBranch, color=gitBranch)) +
#  geom_point() +
#  geom_line() +
#  theme_bw() +
#  labs(x="Nodes", y="Median Time * Nodes (s)", title="FWI strong scaling",
#    subtitle=input_file) +
#  theme(plot.subtitle=element_text(size=8)) +
#  theme(legend.position = c(0.5, 0.88))
#
## Render the plot
#print(p)
#
## Save the png image
#dev.off()
