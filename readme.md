# Overview

This is a MATLAB importer for .xdf files. xdf files are likely to have been created by [LabRecorder](https://github.com/labstreaminglayer/App-LabRecorder), the default file recorder for use with [LabStreamingLayer](https://github.com/sccn/labstreaminglayer). LabRecorder records a collection of streams, including all their data (time-series / markers, meta-data) into a single XDF file. The XDF format (Extensible Data Format) is a general-purpose format for time series and their meta-data that was jointly developed with LSL to ensure compatibility, see [here](http://github.com/sccn/xdf/).

# Usage from EEGLAB

Use plugin manager (mneu item File > Plugin manager) and install plugin xdfimport (we know it is called here xdf-EEGLAB and that the plugin is named differently but it is the same code). Use file import menu to import XDF files. Note that the Mobilab EEGLAB plugin also contains code to import XDF and resample multiple streams to the same sampling rate. It is an alternative to consider (Mobilab shares Matlab import functions with this plugin).

# Usage from the command line

After a session has been recorded to disk using the LabRecorder or any other compatible recording application, it can be imported into MATLAB using the functions in this folder.

Note that EEGLAB plugins are structured so the EEGLAB (/BCILAB/MoBILAB) plugin files are in the top level (i.e. the directory containing this readme) and the actual import function is `load_xdf` in the `xdf` subfolder.

To use `load_xdf` directly:

  * Start MATLAB and make sure that you have the function added to MATLAB's path. You can do this either through the GUI, under File / Set Path / Add Folder) or in the command line, by typing:

> `addpath('C:\\path\\to\\xdf_repo\\Matlab\\xdf')`

  * To load an .xdf file, type in the command line:

> `streams = load_xdf('your_file_name.xdf')`

  * After a few seconds it should return a cell array with one cell for every stream that was contained in the file. For each stream you get a struct that contains the entire meta-data (including channel descriptions and domain-specific information), as well as the time series data itself (numeric or cell-string array, depending on the value type of the stream), and the time stamps of each sample in the time series. All time stamps (across all streams, even if they were collected on different computers of the lab network) are in the same time domain, so they are synchronized. Note that time stamps from different .xdf files are generally not synchronized (although they will normally be in seconds since the recording machine was turned on).

# Usage from the EEGLAB GUI

Upon installing the plugin and invoking the menu "File > Import data > Using EEGLAB functions and plugins > From XDF or XDFZ file" and selecting a file, the following interface pops up.

![Screenshot 2024-11-14 at 18 33 10](https://github.com/user-attachments/assets/c3c280c7-5328-4177-af0b-22b2e63bd608)

You may select the primary stream to import either by using its name or its type. By default, the first EEG stream is imported. Next, you can select additional streams to import, which will be merged with the primary stream and resampled at the same sampling frequency. Marker streams may also be excluded; by default, all marker streams are imported. Finally, you have the option to use the effective sampling frequency of the primary stream, which is the default as of version 2.0.

# Documentation
As usual in MATLAB, to get the documentation of the function, type `help load_xdf` or `doc load_xdf`.

# Version note
- version 1.2  multistream import (backward compatible)
- version 1.19 includes MATLAB binaries
- version 1.18 implement fix for g.tek files
- Version 1.17 fixes to Matlab XDF importer
- Version 1.16 fixes compilation of submodule xdf-matlab for newer versions of Matlab
- Version 1.15 fixes importing channel labels when more than 1 stream is present
- Version 1.14 fixes loading datasets under Mac OSX


