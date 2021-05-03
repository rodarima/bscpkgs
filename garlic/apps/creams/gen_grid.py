#!/usr/bin/env python3

import argparse

parser = argparse.ArgumentParser(description="Generate a grid.dat input file for CREAMS")

parser.add_argument('--npx', type=int, help='number of processes in X', default=1)
parser.add_argument('--npy', type=int, help='number of processes in Y', default=1)
parser.add_argument('--npz', type=int, help='number of processes in Z', default=32)
parser.add_argument('--grain', type=int, help='granularity', default=9)
parser.add_argument('--nx', type=int, help='number of points in X', default=20)
parser.add_argument('--ny', type=int, help='number of points in Y', default=20)
parser.add_argument('--nz', type=int, help='number of points in Z', default=7000)
parser.add_argument('--dx', type=float, help='grid spacing in X', default=0.0025062657)
parser.add_argument('--dy', type=float, help='grid spacing in Y', default=0.0025062657)
parser.add_argument('--dz', type=float, help='grid spacing in Z', default=0.0025062657)

args = parser.parse_args()

grain_str = "%d %d" % (args.grain, args.grain)
boundary = "extrapolation"

# Print
print(' %-49d number of processes in x-direction (0 if automatic)' % args.npx)
print(' %-49d number of processes in y-direction (0 if automatic)' % args.npy)
print(' %-49d number of processes in z-direction (0 if automatic)' % args.npz)
print(' ')
print(' %-49s subdomain granularity' % grain_str)
print(' ')
print(' %-49s -x boundary' % boundary)
print(' %-49s +x boundary' % boundary)
print(' %-49s -y boundary' % boundary)
print(' %-49s +y boundary' % boundary)
print(' %-49s -z boundary' % boundary)
print(' %-49s +z boundary' % boundary)
print(' ')
print(' x-direction')
for i in range(args.nx):
    print("%.9e" % (i * args.dx))
print(' ')
print(' y-direction')
for i in range(args.ny):
    print("%.9e" % (i * args.dy))
print(' ')
print(' z-direction')
for i in range(args.nz):
    print("%.9e" % (i * args.dz))
print(' ')
print(' END')
