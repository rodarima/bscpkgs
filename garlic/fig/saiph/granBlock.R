library(ggplot2)
library(dplyr)
library(scales)
library(jsonlite)

args=commandArgs(trailingOnly=TRUE)

# Read the timetable from args[1]
input_file1 = "input1.json"
if (length(args)>0) { input_file1 = args[1] }

input_file2 = "input2.json"
if (length(args)>1) { input_file2 = args[2] }

# Load the dataset in NDJSON format
dataset1 = jsonlite::stream_in(file(input_file1)) %>%
	 jsonlite::flatten()
dataset2 = jsonlite::stream_in(file(input_file2)) %>%
	 jsonlite::flatten()

# We only need the nblocks and time
df1 = select(dataset1, config.nbx, time) %>%
	rename(nb1=config.nbx)

df2 = select(dataset2, config.nby, time) %>%
	rename(nb2=config.nby)

df1$nb1 = as.factor(df1$nb1)
df2$nb2 = as.factor(df2$nb2)

# Normalize the time by the median
D1=group_by(df1, nb1)
D2=group_by(df2, nb2) 

print(D1)
print(D2)

ppi=300
h=5
w=7

png("scatter_granularity_and_blocking.png", width=w*ppi, height=h*ppi, res=ppi)
#
## Create the plot with the normalized time vs nblocks
p = ggplot() +
    geom_point(data=D1, aes(x=nb1, y=time, colour = 'nbx-nby-nbz'), shape=1, size=4) +
    geom_point(data=D2, aes(x=nb2, y=time, colour = 'nby-nbz'), shape=1, size=4) +

	labs(x="nb", y="Time (s)",
              title=sprintf("Saiph-Heat3D granularity & blocking"), 
              subtitle=input_file1) +
	theme_bw() +
	theme(plot.subtitle=element_text(size=8)) +
	#theme(legend.position = c(0.5, 0.88)) +
	theme(legend.position = "right") +

	geom_point(shape=21, size=3) +
	#scale_x_continuous(trans=log2_trans()) +
	scale_y_continuous(trans=log2_trans()) +
	scale_colour_discrete("Blocked directions")


# Render the plot
print(p)

# Save the png image
dev.off()
