# This R program takes as argument the dataset that contains the results of the
# execution of the heat example experiment and produces some plots. All the
# knowledge to understand how this script works is covered by this nice R book:
#
# Winston Chang, R Graphics Cookbook: Practical Recipes for Visualizing Data,
# O’Reilly Media (2020). 2nd edition
#
# Which can be freely read it online here: https://r-graphics.org/
#
# Please, search in this book before copying some random (and probably oudated)
# reply on stack overflow.

# We load some R packages to import the required functions. We mainly use the
# tidyverse packages, which are very good for ploting data,
library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(scales)
library(jsonlite)
library(viridis, warn.conflicts = FALSE)

# Here we simply load the arguments to find the input dataset. If nothing is
# specified we use the file named `input` in the current directory.
# We can run this script directly using:
# Rscript <path-to-this-script> <input-dataset>

# Load the arguments (argv)
args = commandArgs(trailingOnly=TRUE)

# Set the input dataset if given in argv[1], or use "input" as default
if (length(args)>0) { input_file = args[1] } else { input_file = "input" }

df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%

  # Then we flatten it, as it may contain dictionaries inside the columns
  jsonlite::flatten() %>%

  # Now the dataframe contains all the configuration of the units inside the
  # columns named `config.*`, for example `config.cbs`. We first select only
  # the columns that we need:
  select(config.nblocks, config.ncommblocks, config.hw.cpusPerSocket, unit, time) %>%

  # And then we rename those columns to something shorter:
  rename(nblocks=config.nblocks,
         ncommblocks=config.ncommblocks,
         cpusPerSocket=config.hw.cpusPerSocket) %>%

  mutate(blocksPerCpu = nblocks / cpusPerSocket) %>%

  mutate(nblocks = as.factor(nblocks)) %>%
  mutate(blocksPerCpu = as.factor(blocksPerCpu)) %>%
  mutate(unit = as.factor(unit)) %>%

  group_by(unit) %>%

  # And compute some metrics which are applied to each group. For example we
  # compute the median time within the runs of a unit:
  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  # Then, we remove the grouping. This step is very important, otherwise the
  # plotting functions get confused:
  ungroup()

dpi=300
h=5
w=5

p = ggplot(df, aes(x=blocksPerCpu, y=normalized.time)) +

  # The boxplots are useful to identify outliers and problems with the
  # distribution of time
  geom_boxplot() +

  # We add a line to mark the 1% limit above and below the median
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +

  # The bw theme is recommended for publications
  theme_bw() +

  # Here we add the title and the labels of the axes
  labs(x="Blocks per CPU", y="Normalized time", title="HPCG granularity: normalized time",
    subtitle=input_file) +

  # And set the subtitle font size a bit smaller, so it fits nicely
  theme(plot.subtitle=element_text(size=8))

# Then, we save the plot both in png and pdf
ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)

# We plot the time of each run as we vary the block size
p = ggplot(df, aes(x=blocksPerCpu, y=time)) +

  # We add a points (scatter plot) using circles (shape=21) a bit larger
  # than the default (size=3)
  geom_point(shape=21, size=3) +

  # The bw theme is recommended for publications
  theme_bw() +

  # Here we add the title and the labels of the axes
  labs(x="Blocks Per CPU", y="Time (s)", title="HPCG granularity: time",
    subtitle=input_file) +

  # And set the subtitle font size a bit smaller, so it fits nicely
  theme(plot.subtitle=element_text(size=8))

# Then, we save the plot both in png and pdf
ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)

