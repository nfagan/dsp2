# dsp2

`dsp2` is a MATLAB package for pre-processing, analyzing, and storing continuous time series (LFP) data recorded from the Chang Lab Dictator Game. To get started, download / clone the dependencies listed below, and add them to MATLAB's path.

### Dependendices

* MATLAB R2015b (newer releases probably work, but are untested)
* MATLAB Signal Processing Toolbox
* Chronux Signal Processing Library
* `changlabneuro/h5_api.git`
* `changlabneuro/global.git`
* `changlabneuro/dsp.git`

### Package overview

* `+config` contains methods to create, save, and load global configuration options used throughout the library.
* `+analysis` contains methods to run + save time-frequency analyses -- these include spectral power, coherence, and normalized spectral power.
* `+database` contains methods + classes to construct, update, and read from a .sqlite database.
* `+io` contains methods + classes to load and save data.
* `+process` contains methods to pre-process signals, as well as clean-up data labeling.
* `+util` contains utilities used throughout the library.





 	