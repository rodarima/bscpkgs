library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file = "input1.json"
if (length(args)>0) { input_file = args[1] }

input_file2 = "input2.json"
if (length(args)>0) { input_file2 = args[1] }

# Load the dataset in NDJSON format
dataset = jsonlite::stream_in(file(input_file)) %>%
	jsonlite::flatten()

dataset2 = jsonlite::stream_in(file(input_file2)) %>%
	jsonlite::flatten()


# We only need the nblocks and time
df = select(dataset, config.nby, time) %>%
     rename(nby=config.nby)

df$nby = as.factor(df$nby)

df2 = select(dataset2, config.nbz, time) %>%
      rename(nbz=config.nbz)

df2$nbz = as.factor(df2$nbz)


# Normalize the time by the median
D=group_by(df, nby) %>%
	mutate(tnorm = time / median(time) - 1) %>%
	mutate(bad = max(ifelse(abs(tnorm) >= 0.01, 1, 0)))

D$bad = as.factor(D$bad)


print(D)

D2=group_by(df2, nbz) %>%
	mutate(tnorm = time / median(time) - 1) %>%
	mutate(bad = max(ifelse(abs(tnorm) >= 0.01, 1, 0)))

D2$bad = as.factor(D2$bad)

print(D)
print(D2)

png("scatter-blockY8Z_yZ8.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot() +
	geom_point(data=D, aes(x=nby, y=time, colour="nby blocks - nbz = 8"), shape=1, size=3) +
	geom_point(data=D2, aes(x=nbz, y=time, colour="nby = 8 - nbz blocks"), shape=1, size=3) +

	labs(x="nb", y="Time (s)",
              title=sprintf("Saiph-Heat3D blockingY/Z"), 
              subtitle=input_file) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	theme(legend.position = "right") +

	geom_point(shape=21, size=3) +
	scale_colour_discrete("Blocked directions")
	#+ scale_x_continuous(trans=log2_trans())
	#+ scale_y_continuous(trans=log2_trans())

# Render the plot
print(p)

# Save the png image
dev.off()
