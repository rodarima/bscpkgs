library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%
  jsonlite::flatten()

# We only need some colums
df = select(dataset, unit, config.nodes, config.gitBranch,
    config.granul, time, total_time) %>%
  rename(nodes=config.nodes, gitBranch=config.gitBranch,
    granul=config.granul)

df$unit = as.factor(df$unit)
df$nnodes = df$nodes
df$nodes = as.factor(df$nodes)
df$gitBranch = as.factor(df$gitBranch)
df$granul = as.factor(df$granul)

# Remove the "garlic/" prefix from the gitBranch
levels(df$gitBranch) <- substring((levels(df$gitBranch)), 8)

# Compute new columns
D=group_by(df, unit) %>%
  mutate(tnorm = time / median(time) - 1) %>%
  mutate(bad = ifelse(max(abs(tnorm)) >= 0.01, 1, 0)) %>%
  mutate(variability = ifelse(bad > 0, "large", "ok")) %>%
  mutate(mtime = median(time)) %>%
  mutate(nmtime = mtime*nnodes) %>%
  mutate(ntime = time*nnodes) %>%
  ungroup() %>%
  mutate(min_nmtime = min(nmtime)) %>%
  mutate(rnmtime = nmtime / min_nmtime) %>%
  mutate(rntime = ntime / min_nmtime) %>%
  mutate(rmeff = 1.0 / rnmtime) %>%
  mutate(reff = 1.0 / rntime) %>%
  group_by(gitBranch) %>%
  mutate(tmax = max(mtime)) %>%
  mutate(speedup=tmax/time) %>%
  mutate(eff=speedup/nnodes) %>%
  mutate(mspeedup=tmax/mtime) %>%
  mutate(meff=mspeedup/nnodes) %>%
  ungroup()

D$bad = as.factor(D$bad > 0)
D$variability = as.factor(D$variability)

ppi=300
h=5
w=5

png("time.png", width=w*1.5*ppi, height=h*ppi, res=ppi)
p = ggplot(D, aes(x=granul, y=mtime, linetype=gitBranch, shape=nodes)) +
  geom_line(aes(group=interaction(nodes, gitBranch))) +
  geom_point(aes(y=time)) +
  scale_y_continuous(trans=log2_trans()) +
  labs(x="Granularity", y="Time (s)",
    title="Creams granularity",
    subtitle=input_file) +
  theme_bw() +
  theme(plot.subtitle=element_text(size=8))
print(p)
dev.off()
