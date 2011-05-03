#! /usr/bin/env python
def main():
    import sys
    for val in range(int(sys.argv[1])):
            DirName = "SampleFam_%s"%str(val+1).zfill(2)
            print DirName


if __name__ == '__main__':
    main()

