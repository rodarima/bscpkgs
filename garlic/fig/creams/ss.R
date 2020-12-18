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
df = select(dataset, unit, config.nodes, config.gitBranch, time) %>%
	rename(nodes=config.nodes, gitBranch=config.gitBranch)

df$unit = as.factor(df$unit)
df$nnodes = df$nodes
df$nodes = as.factor(df$nodes)
df$gitBranch = as.factor(df$gitBranch)

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

png("variability.png", width=1.5*w*ppi, height=h*ppi, res=ppi)
p = ggplot(data=D, aes(x=nodes, y=tnorm, color=variability)) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	# Add the maximum allowed error lines
	geom_hline(yintercept=c(-0.01, 0.01),
		linetype="dashed", color="gray") +
	# Draw boxplots
	geom_boxplot(aes(fill=gitBranch)) +
	scale_color_manual(values=c("brown", "black")) +
	# Labels
	labs(x="Nodes", y="Normalized time", title="Creams strong scaling",
    subtitle=input_file)
print(p)
dev.off()

png("time.png", width=w*1.5*ppi, height=h*ppi, res=ppi)
p = ggplot(D, aes(x=nodes, y=mtime, color=gitBranch)) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	geom_line(aes(group=gitBranch)) +
	#geom_point() +
	geom_point(aes(shape=variability), size=3) +
	scale_shape_manual(values=c(21, 19)) +
  #  position=position_dodge(width=0.3)) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans()) +
	labs(x="Nodes", y="Time (s)",
    title="Creams strong scaling (lower is better)",
    subtitle=input_file)
print(p)
dev.off()

png("refficiency.png", width=w*1.5*ppi, height=h*ppi, res=ppi)
p = ggplot(D, aes(x=nodes, y=rmeff, color=gitBranch)) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	geom_line(aes(group=gitBranch)) +
	geom_point(aes(shape=variability), size=3) +
	#geom_boxplot(aes(y=reff),
  #  position=position_dodge(width=0.0)) +
	scale_shape_manual(values=c(21, 19)) +
	#geom_point(aes(y=rntime),
  #  position=position_dodge(width=0.3)) +
	#scale_x_continuous(trans=log2_trans()) +
	#scale_y_continuous(trans=log2_trans()) +
	labs(x="Nodes", y="Relative efficiency (to best)",
    title="Creams strong scaling (higher is better)",
    subtitle=input_file)
print(p)
dev.off()
