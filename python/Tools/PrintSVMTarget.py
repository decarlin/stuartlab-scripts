#! /usr/bin/env python
def main():
    import os
    RawDir = os.path.basename(os.getcwd())
    TargName = RawDir.lstrip('Run').lower()
    print TargName


if __name__ == '__main__':
    main()

