.\" Use helvetica family
.fam H
.PS
moveht=0.1
boxwid=1
sht=boxht + 0.1
hspace = boxwid + 0.2
right
G: [
  boxwid=1
  extrawid=1.8
  right
  A: box "nix"; arrow;
  B1: box wid extrawid "App source code" "PM branch, defines...";
  move to (A.sw.x, A.y - boxht - moveht)
  A: box "garlic/nix"; arrow;
  B2: box wid extrawid "App run config" "Input size, algorithm...";
  move to (A.sw.x, A.y - boxht - moveht)
  A: box "garlic/nix"; arrow;
  B3: box wid extrawid "Build config" "MPI impl, O3, CC version...";
  move to (A.sw.x, A.y - boxht - moveht)
  A: box "garlic/nix"; arrow;
  B4: box wid extrawid "Run config" "Nodes, affinity";
  move to (A.sw.x, A.y - boxht - moveht)
  A: box "MN4"; arrow;
  B5: box wid extrawid "Hardware" "Cache size, intercomm...";
]
movewid=1
move
circlerad=0.4
E: circle "Execution"
arrow
box "Result"
rspline = 0.5
arrow from G.B1.e to E chop 0 chop circlerad
arrow from G.B2.e to E chop 0 chop circlerad
arrow from G.B3.e to E chop 0 chop circlerad
arrow from G.B4.e to E chop 0 chop circlerad
arrow from G.B5.e to E chop 0 chop circlerad
.PE
