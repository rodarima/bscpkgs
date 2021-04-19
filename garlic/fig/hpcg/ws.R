library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)

args = commandArgs(trailingOnly=TRUE)

if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%

  jsonlite::flatten() %>%

  select(config.nblocks,
         config.hw.cpusPerSocket,
         config.nodes,
         config.nprocs.x,
         config.nprocs.y,
         config.nprocs.z,
         config.blocksPerCpu,
         config.sizePerCpu.z,
         unit,
         time
         ) %>%

  rename(nblocks=config.nblocks,
         cpusPerSocket=config.hw.cpusPerSocket,
         nodes=config.nodes,
         blocksPerCpu=config.blocksPerCpu,
         sizePerCpu.z=config.sizePerCpu.z,
         npx=config.nprocs.x,
         npy=config.nprocs.y,
         npz=config.nprocs.z
         ) %>%

  mutate(axisColor=as.factor(ifelse(npx != 1, "X", ifelse(npy != 1, "Y", "Z")))) %>%
  mutate(time.sizeZ = time / sizePerCpu.z) %>%

  mutate(nblocks = as.factor(nblocks)) %>%
  mutate(blocksPerCpu = as.factor(blocksPerCpu)) %>%
  mutate(nodes = as.factor(nodes)) %>%
  mutate(unit = as.factor(unit)) %>%
  mutate(sizePerCpu.z = as.factor(sizePerCpu.z)) %>%

  mutate(timePerNprocs = time * npz) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

dpi=300
h=7
w=7

p = ggplot(df, aes(x=nodes, y=time, fill=sizePerCpu.z)) +
  geom_boxplot() +
  theme_bw() +
  labs(x="Nodes", y="Time (s)", title="HPCG weak scaling in Z",
    color="Size per CPU in Z",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8),
    legend.position="bottom")

ggsave("time.nodes.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.nodes.pdf", plot=p, width=w, height=h, dpi=dpi)
