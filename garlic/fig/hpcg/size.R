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

  mutate(time.nodes = time * nodes) %>%
  mutate(time.nodes.elem = time.nodes / sizePerCpu.z) %>%

  mutate(axisColor=as.factor(ifelse(npx != 1, "X", ifelse(npy != 1, "Y", "Z")))) %>%

  mutate(nblocks = as.factor(nblocks)) %>%
  mutate(blocksPerCpu = as.factor(blocksPerCpu)) %>%
  mutate(sizePerCpu.z = as.factor(sizePerCpu.z)) %>%
  mutate(nodes = as.factor(nodes)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  ungroup()

dpi=300
h=5
w=5

p = ggplot(df, aes(x=sizePerCpu.z, y=time.nodes.elem)) +
  geom_point(shape=21, size=3) +
  theme_bw() +
  labs(x="Size per CPU in Z", y="Time * nodes / spcz (s)",
    title="HPCG size: time * nodes / spcz",
    subtitle=input_file) +
  theme(plot.subtitle=element_text(size=8),
    legend.position="bottom")

ggsave("time.nodes.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.nodes.pdf", plot=p, width=w, height=h, dpi=dpi)
