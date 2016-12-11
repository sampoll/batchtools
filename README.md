# batchtools

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/batchtools)](https://cran.r-project.org/package=batchtools)
[![Build Status](https://travis-ci.org/mllg/batchtools.svg?branch=master)](https://travis-ci.org/mllg/batchtools)
[![Build status](https://ci.appveyor.com/api/projects/status/1gdgk7twxrghi943/branch/master?svg=true)](https://ci.appveyor.com/project/mllg/batchtools-jgbhb/branch/master)
[![Coverage Status](https://img.shields.io/coveralls/mllg/batchtools.svg)](https://coveralls.io/r/mllg/batchtools?branch=master)

As a successor of the packages [BatchJobs](https://github.com/tudo-r/BatchJobs) and [BatchExperiments](https://github.com/tudo-r/Batchexperiments), batchtools provides a parallel implementation of Map for high performance computing systems managed by schedulers like Slurm, Torque, or SGE.
For a complete list, see the [Setup vignette](https://mllg.github.io/batchtools/articles/Setup).
Moreover, the package provides an abstraction mechanism to define large-scale computer experiments in a well-organized and reproducible way.

## Installation
Install the stable version from CRAN:
```{R}
install.packages("batchtools")
```
For the development version, use [devtools](https://cran.r-project.org/package=devtools):
```{R}
devtools::install_github("mllg/batchtools")
```

## Resources
* [NEWS](https://github.com/mllg/batchtools/blob/master/NEWS.md) including a comparison with [BatchJobs](https://github.com/tudo-r/BatchJobs) and [BatchExperiments](https://github.com/tudo-r/Batchexperiments)
* [Setup](https://mllg.github.io/batchtools/articles/Setup)
* [Documentation and Vignettes](https://mllg.github.io/batchtools/)
* [Paper on BatchJobs/BatchExperiments](http://www.jstatsoft.org/v64/i11)


## Related Software
* The [High Performance Computing Task View](https://cran.r-project.org/web/views/HighPerformanceComputing.html) lists the most relevant packages for scientific computing with R
* [batch](https://cran.r-project.org/package=batch) assists in splitting and submitting jobs to LSF and MOSIX clusters
* [flowr](https://cran.r-project.org/package=flowr) supports LSF, Slurm, Torque and Moab and provides a scatter-gather approach to define computational jobs
