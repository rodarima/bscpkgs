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
if (length(args)>1) { output = args[2] } else { output = "?" }

# Here we build of dataframe from the input dataset by chaining operations using
# the magritte operator `%>%`, which is similar to a UNIX pipe.
# First we read the input file, which is expected to be NDJSON
df = jsonlite::stream_in(file(input_file), verbose=FALSE) %>%

  # Then we flatten it, as it may contain dictionaries inside the columns
  jsonlite::flatten() %>%
  
  # Now the dataframe contains all the configuration of the units inside the
  # columns named `config.*`, for example `config.cbs`. We first select only
  # the columns that we need:
  select(config.cbs, config.rbs, unit, time) %>%

  # And then we rename those columns to something shorter:
  rename(cbs=config.cbs, rbs=config.rbs) %>%

  # The columns contain the values that we specified in the experiment as
  # integers. However, we need to tell R that those values are factors. So we
  # apply to those columns the `as.factor()` function:
  mutate(cbs = as.factor(cbs)) %>%
  mutate(rbs = as.factor(rbs)) %>%

  # The same for the unit (which is the hash that nix has given to each unit)
  mutate(unit = as.factor(unit)) %>%

  # Then, we can group our dataset by each unit. This will always work
  # independently of the variables that vary from unit to unit.
  group_by(unit) %>%

  # And compute some metrics which are applied to each group. For example we
  # compute the median time within the runs of a unit:
  mutate(median.time = median(time)) %>%
  mutate(normalized.time = time / median.time - 1) %>%
  mutate(log.median.time = log(median.time)) %>%

  # Then, we remove the grouping. This step is very important, otherwise the
  # plotting functions get confused:
  ungroup()


# These constants will be used when creating the plots. We use high quality
# images with 300 dots per inch and 5 x 5 inches of size by default.
dpi = 300
h = 5
w = 5


# ---------------------------------------------------------------------


# We plot the median time (of each unit) as we vary the block size. As we vary
# both the cbs and rbs, we plot cbs while fixing rbs at a time.
p = ggplot(df, aes(x=cbs, y=median.time, color=rbs)) +
  # We add a point to the median
  geom_point() +

  # We also add the lines to connect the points. We need to specify which
  # variable will do the grouping, otherwise we will have one line per point.
  geom_line(aes(group=rbs)) +

  # The bw theme is recommended for publications
  theme_bw() +

  # Here we add the title and the labels of the axes
  labs(x="cbs", y="Median time (s)", title="Heat granularity: median time", 
    subtitle=output) + 

  # And set the subtitle font size a bit smaller, so it fits nicely
  theme(plot.subtitle=element_text(size=8))

# Then, we save the plot both in png and pdf
ggsave("median.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("median.time.pdf", plot=p, width=w, height=h, dpi=dpi)


# ---------------------------------------------------------------------


# Another interesting plot is the normalized time, which shows the variance of
# the execution times, and can be used to find problems:
p = ggplot(df, aes(x=cbs, y=normalized.time)) +

  # The boxplots are useful to identify outliers and problems with the
  # distribution of time
  geom_boxplot() +

  # We add a line to mark the 1% limit above and below the median 
  geom_hline(yintercept=c(-0.01, 0.01), linetype="dashed", color="red") +

  # We split the plot into subplots, one for each value of the rbs column
  facet_wrap(~ rbs) +

  # The bw theme is recommended for publications
  theme_bw() +

  # Here we add the title and the labels of the axes
  labs(x="cbs", y="Normalized time", title="Heat granularity: normalized time", 
    subtitle=output) + 

  # And set the subtitle font size a bit smaller, so it fits nicely
  theme(plot.subtitle=element_text(size=8))

# Then, we save the plot both in png and pdf
ggsave("normalized.time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("normalized.time.pdf", plot=p, width=w, height=h, dpi=dpi)


# ---------------------------------------------------------------------


# We plot the time of each run as we vary the block size
p = ggplot(df, aes(x=cbs, y=time, color=rbs)) +

  # We add a points (scatter plot) using circles (shape=21) a bit larger
  # than the default (size=3) 
  geom_point(shape=21, size=3) +

  # The bw theme is recommended for publications
  theme_bw() +

  # Here we add the title and the labels of the axes
  labs(x="cbs", y="Time (s)", title="Heat granularity: time", 
    subtitle=output) + 

  # And set the subtitle font size a bit smaller, so it fits nicely
  theme(plot.subtitle=element_text(size=8))

# Then, we save the plot both in png and pdf
ggsave("time.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.pdf", plot=p, width=w, height=h, dpi=dpi)


# ---------------------------------------------------------------------


# We can also plot both cbs and rbs in each dimension by mapping the time with a
# color. The `fill` argument instruct R to use the `median.time` as color
p = ggplot(df, aes(x=cbs, y=rbs, fill=median.time)) +

  # Then we use the geom_raster method to paint rectangles filled with color
  geom_raster() + 

  # The colors are set using the viridis package, using the plasma palete. Those
  # colors are designed to be safe for color impaired people and also when
  # converting the figures to grayscale.
  scale_fill_viridis(option="plasma") +

  # We also force each tile to be an square
  coord_fixed() +

  # The bw theme is recommended for publications
  theme_bw() +

  # Here we add the title and the labels of the axes
  labs(x="cbs", y="rbs", title="Heat granularity: time", 
    subtitle=output) + 

  # And set the subtitle font size a bit smaller, so it fits nicely
  theme(plot.subtitle=element_text(size=8))

# Then, we save the plot both in png and pdf
ggsave("time.heatmap.png", plot=p, width=w, height=h, dpi=dpi)
ggsave("time.heatmap.pdf", plot=p, width=w, height=h, dpi=dpi)
