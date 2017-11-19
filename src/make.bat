@echo off
del *.exe *.obj
ml /c /coff %1.asm
rc /v %2.rc
cvtres /machine:ix86 %2.res
link /subsystem:windows %1.obj %2.obj
@echo on