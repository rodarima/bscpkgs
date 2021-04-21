library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)
library(egg)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input.json"
if (length(args)>0) { input_file = args[1] }
if (length(args)>1) { output = args[2] } else { output = "?" }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
  jsonlite::flatten()

particles = unique(dataset$config.particles)

# We only need the nblocks and time
df = select(dataset,
  config.nblocks,
  config.hw.cpusPerSocket,
  config.nodes,
  config.blocksize,
  config.particles,
  config.gitBranch,
  time) %>%
  rename(nblocks=config.nblocks,
    nodes=config.nodes,
    blocksize=config.blocksize,
    particles=config.particles,
    gitBranch=config.gitBranch,
    cpusPerSocket=config.hw.cpusPerSocket)

df = df %>% mutate(blocksPerCpu = nblocks / cpusPerSocket)
df$nblocks = as.factor(df$nblocks)
df$nodesFactor = as.factor(df$nodes)
df$blocksPerCpuFactor = as.factor(df$blocksPerCpu)
df$blocksizeFactor = as.factor(df$blocksize)
df$particlesFactor = as.factor(df$particles)
df$gitBranch = as.factor(df$gitBranch)

# Normalize the time by the median
D=group_by(df, nblocks, nodesFactor, gitBranch) %>%
  mutate(tmedian = median(time)) %>%
  mutate(tn = tmedian * nodes) %>%
  mutate(tnorm = time / median(time) - 1) %>%
  mutate(bad = max(ifelse(abs(tnorm) >= 0.01, 1, 0))) %>%
  ungroup() %>%
  group_by(nodesFactor, gitBranch) %>%
  mutate(tmedian_min = min(tmedian)) %>%
  ungroup() %>%
  group_by(gitBranch) %>%
  mutate(tmin_max = max(tmedian_min)) %>%
  mutate(tideal = tmin_max / nodes) %>%
  ungroup()

D$bad = as.factor(D$bad)

#D$bad = as.factor(ifelse(abs(D$tnorm) >= 0.01, 2,
#         ifelse(abs(D$tnorm) >= 0.005, 1, 0)))

bs_unique = unique(df$nblocks)
nbs=length(bs_unique)

print(D)

ppi=300
h=7.5
w=7.5

png("box.png", width=w*ppi, height=h*ppi, res=ppi)
#
#
#
# Create the plot with the normalized time vs nblocks
p = ggplot(data=D, aes(x=blocksPerCpuFactor, y=tnorm, color=bad)) +

  # Labels
  labs(x="Blocks/CPU", y="Normalized time",
              title=sprintf("Nbody normalized time. Particles=%d", particles), 
              subtitle=output) +


  # Center the title
  #theme(plot.title = element_text(hjust = 0.5)) +

  # Black and white mode (useful for printing)
  #theme_bw() +

  # Add the maximum allowed error lines
  geom_hline(yintercept=c(-0.01, 0.01),
    linetype="dashed", color="gray") +

  # Draw boxplots
  geom_boxplot(aes(fill=nodesFactor)) +
  scale_color_manual(values=c("black", "brown")) +
  facet_grid(gitBranch ~ .) +

  #scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +


  #theme(legend.position = "none")
  #theme(legend.position = c(0.85, 0.85))
  theme_bw()+
  theme(plot.subtitle=element_text(size=8))




# Render the plot
print(p)
dev.off()


p1 = ggplot(D, aes(x=blocksizeFactor, y=time)) +

  labs(x="Blocksize", y="Time (s)",
              title=sprintf("Nbody granularity. Particles=%d", particles), 
              subtitle=output) +
  theme_bw() +
  theme(plot.subtitle=element_text(size=8)) +
  #theme(legend.position = c(0.5, 0.8)) +

  geom_line(aes(y=tmedian,
    group=interaction(gitBranch, nodesFactor),
    color=nodesFactor)) +
  geom_point(aes(color=nodesFactor), size=3, shape=21) +
  facet_grid(gitBranch ~ .) +
  scale_shape_manual(values=c(21, 22)) +
  scale_y_continuous(trans=log2_trans())

png("time-blocksize.png", width=w*ppi, height=h*ppi, res=ppi)
print(p1)
dev.off()

p2 = ggplot(D, aes(x=blocksPerCpuFactor, y=time)) +

  labs(x="Blocks/CPU", y="Time (s)",
              title=sprintf("Nbody granularity. Particles=%d", particles), 
              subtitle=output) +
  theme_bw() +
  theme(plot.subtitle=element_text(size=8)) +

  geom_line(aes(y=tmedian,
    group=interaction(gitBranch, nodesFactor),
    color=nodesFactor)) +
  geom_point(aes(color=nodesFactor), size=3, shape=21) +
  facet_grid(gitBranch ~ .) +

  scale_shape_manual(values=c(21, 22)) +
  scale_y_continuous(trans=log2_trans())

png("time-blocks-per-cpu.png", width=w*ppi, height=h*ppi, res=ppi)
print(p2)
dev.off()

#p = ggarrange(p1, p2, ncol=2)
#png("time-gra.png", width=2*w*ppi, height=h*ppi, res=ppi)
#print(p)
#dev.off()



png("exp-space.png", width=w*ppi, height=h*ppi, res=ppi)
p = ggplot(data=df, aes(x=nodesFactor, y=particlesFactor)) +
  labs(x="Nodes", y="Particles", title="Nbody: Experiment space") +
  geom_line(aes(group=particles)) +
  geom_point(aes(color=nodesFactor), size=3) +
  facet_grid(gitBranch ~ .) +
  theme_bw()
print(p)
dev.off()


png("gra-space.png", width=w*ppi, height=h*ppi, res=ppi)
p = ggplot(data=D, aes(x=nodesFactor, y=blocksPerCpuFactor)) +
  labs(x="Nodes", y="Blocks/CPU", title="Nbody: Granularity space") +
  geom_line(aes(group=nodesFactor)) +
  geom_point(aes(color=nodesFactor), size=3) +
  facet_grid(gitBranch ~ .) +
  theme_bw()
print(p)
dev.off()


png("performance.png", width=w*ppi, height=h*ppi, res=ppi)
p = ggplot(D, aes(x=nodesFactor)) +
  labs(x="Nodes", y="Time (s)", title="Nbody strong scaling") +
  theme_bw() +
  geom_line(aes(y=tmedian,
    linetype=blocksPerCpuFactor,
    group=interaction(gitBranch, blocksPerCpuFactor))) +
  geom_line(aes(y=tideal, group=gitBranch), color="red") +
  geom_point(aes(y=tmedian, color=nodesFactor), size=3) +
  facet_grid(gitBranch ~ .) +
  scale_shape_manual(values=c(21, 22)) +
  scale_y_continuous(trans=log2_trans())
print(p)
dev.off()


png("time-nodes.png", width=w*ppi, height=h*ppi, res=ppi)
p = ggplot(D, aes(x=nodesFactor)) +
  labs(x="Nodes", y="Time * nodes (s)", title="Nbody strong scaling") +
  theme_bw() +
  geom_line(aes(y=tn, group=gitBranch)) +
  facet_grid(gitBranch ~ .) +
  scale_y_continuous(trans=log2_trans())
print(p)
dev.off()
