@echo off

if exist b (
  del /f/s/q b > nul
  rmdir /s/q b
)

if exist b-cross (
  del /f/s/q b-cross > nul
  rmdir /s/q b-cross
)
