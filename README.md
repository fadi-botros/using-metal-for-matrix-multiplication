# Using Metal for Matrix Multiplication

***WARNING: This mini demo application is written in unsafe technologies, functions like `vm_allocate`, `vm_deallocate` are unsafe and using them incorrectly would lead to very dangerous vulnerabilities (like Use-After-Free, Buffer-Overflow) using the application written in them, so, before learning from this application, read carefully the documentation of `vm_allocate`, `vm_deallocate` and read how to manage memory in Metal applications and in Swift***

***Any code reviews containing safety/security corrections are welcome***

## Classes

### `Matrix`

Represents a 2D matrix, but in a low-level data structure so that it can be used directly in Metal

### `VMMemory`

For performance, one needs buffers not being copied. To do this, share the buffer between CPU and GPU, and allocate them aligned by 4096 bytes, the simplest way for this is following the official documentation which states that using `vm_allocate` or `mmap` are the way. So, use `vm_allocate`.

There is something good (but unsafe) in Swift which is called `Data(bytesNoCopy:options:deallocator)`, this creates a traditional `Data` wrapper around the allocated buffer, good for security to make it covered by ARC. While deallocating the buffer after calculation is done.

The same is in Metal by creating a non-copy buffer, also with deallocator. Used the instance of `Matrix` inside the deallocator so that the lifetime of the Matrix object would be extended until the removal of the command

### `MatrixMultiplierMaths`

A matrix multiplier, using the naiive algorithm

### `MatrixMultiplierMetal`

Uses Metal for the same algorithm 

### LICENSE

MIT license
