# VictoriaOS

Inctoduction

VictoriaOS is a 16-bit operational system created for educational purpuses. 
VictoriaOS in it's present form can't compete with other modern systems. It was 
created with aims of exploring common principles of operational systems 
architecture and testing our own ideas.

Thus current version of VictoriaOS may be considered to be a demonstration of 
our abilities. Possibly next version will be written from scratch.
It will have nothing common with current version. Creators wish people 
intrested in OS developing to join this project. Victoria may become serious 
OS in time.

## System requirements

VictoriaOS works in processor's real mode and it's kernel uses only 
capabilities of Intel 80186 processor. Of course, it could works on any
compatible processor (on most of modern processors). 

VictoriaOS may be booted from a single 3.5'' floppy disk.

## Compilation and running

You can build VictoriaOS under Linux and Windows operating systems. Copilation
in both system may be performed in a similar way.

To compile VictoriaOS you need Flat Assembler (version 1.65 or higher) and 
"make" utility. You also need "imgwrite" utility which is distributed in form 
of executable files and source code with VictoriaOS sources. Flat Assembler 
in form of executable files for Windows and Linux (please read Flat Assembler 
license in fasm/fasm-license.txt) and "make" and "rm" utilities for Windows 
are also distributed with VictoriaOS sources (please read Flat Assembler 
license in file "fasm/fasm-license.txt"). 

To compile VictoriaOS you need unpack source code archive to any folder,
make this folder current and execute "make" comand. 

After compilation you will get disk.img file. You can write it to a floppy 
disk or use with virtual machine (like qemu, vmware or MS Virtual PC).

## License

VictoriaOS is distributed under GNU GPL terms and conditions.

Flat Assembler is copyrighted by Tomasz Grysztar (Flat Assembler license may
be found in "fasm/fasm-license.txt"). Official Flat Assembler website address 
is http://flatassembler.com.

"Make" and "rm" utilities are distributed under GNU GPL license. Their sources 
may be downloaded from http://www.gnu.org.

## Authors

VictoriaOS was written by Ilya Strukov and Nick Kudasov.
