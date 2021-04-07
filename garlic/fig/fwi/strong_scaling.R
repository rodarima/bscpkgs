library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
  jsonlite::flatten()

# Select block size to display
useBlocksize = 2

# We only need the nblocks and time
df = select(dataset, config.blocksize, config.gitBranch, config.nodes, time) %>%
  rename(
     blocksize=config.blocksize,
     gitBranch=config.gitBranch,
     nodes=config.nodes
  ) %>%
  filter(blocksize == useBlocksize | blocksize == 0) %>%
  group_by(nodes, gitBranch) %>%
  mutate(mtime = median(time)) %>%
  mutate(nxmtime = mtime * nodes) %>%
  mutate(nxtime = time * nodes) %>%
  ungroup()

df$gitBranch = as.factor(df$gitBranch)
df$blocksize = as.factor(df$blocksize)
df$nodes     = as.factor(df$nodes)

ppi=300
h=5
w=5

####################################################################
### Line plot (time)
####################################################################
png("time.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(df, aes(x=nodes, y=time, group=gitBranch, color=gitBranch)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Nodes", y="Time (s)", title="FWI strong scaling",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position = c(0.6, 0.75))

# Render the plot
print(p)

# Save the png image
dev.off()

####################################################################
### Line plot (time x nodes)
####################################################################
png("nxtime.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(df, aes(x=nodes, y=nxtime, group=gitBranch, color=gitBranch)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Nodes", y="Time * Nodes (s)", title="FWI strong scaling",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position = c(0.15, 0.80)) +
  theme(legend.text = element_text(size = 7))

# Render the plot
print(p)

# Save the png image
dev.off()

####################################################################
### Line plot (median time)
####################################################################
png("mediantime.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(df, aes(x=nodes, y=mtime, group=gitBranch, color=gitBranch)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Nodes", y="Median Time (s)", title="FWI strong scaling",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position = c(0.5, 0.88))

# Render the plot
print(p)

# Save the png image
dev.off()

####################################################################
### Line plot (nodes x median time)
####################################################################
png("nxmtime.png", width=w*ppi, height=h*ppi, res=ppi)

p = ggplot(df, aes(x=nodes, y=nxmtime, group=gitBranch, color=gitBranch)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Nodes", y="Median Time * Nodes (s)", title="FWI strong scaling",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8)) +
  theme(legend.position = c(0.5, 0.88))

# Render the plot
print(p)

# Save the png image
dev.off()
