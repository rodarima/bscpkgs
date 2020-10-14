set terminal png size 800,800
set output 'out.png'

set xrange [16:1024]
set nokey
set logscale x 2
set logscale y 2
set grid

set xlabel "blocksize"
set ylabel "time (s)"

plot 'time.32'  using (32):1  with circles title "32", \
     'time.64'  using (64):1  with circles title "64", \
     'time.128' using (128):1 with circles title "128", \
     'time.256' using (256):1 with circles title "256", \
     'time.512' using (512):1 with circles title "512"
