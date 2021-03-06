% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/submitJobs.R
\name{submitJobs}
\alias{submitJobs}
\title{Submit Jobs to the Batch Systems}
\usage{
submitJobs(ids = NULL, resources = list(), sleep = NULL,
  reg = getDefaultRegistry())
}
\arguments{
\item{ids}{[\code{\link[base]{data.frame}} or \code{integer}]\cr
A \code{\link[base]{data.frame}} (or \code{\link[data.table]{data.table}})
with a column named \dQuote{job.id}.
Alternatively, you may also pass a vector of integerish job ids.
If not set, defaults to the return value of \code{\link{findNotSubmitted}}.
Invalid ids are ignored.}

\item{resources}{[\code{named list}]\cr
Computational  resources for the batch jobs. The elements of this list
(e.g. something like \dQuote{walltime} or \dQuote{nodes}) depend on your template file.
See notes for reserved special resource names.
Defaults can be stored in the configuration file by providing the named list \code{default.resources}.
Settings in \code{resources} overwrite those in \code{default.resources}.}

\item{sleep}{[\code{function(i)} | \code{numeric(1)}]\cr
Parameter to control the duration to sleep between temporary errors.
You can pass an absolute numeric value in seconds or a \code{function(i)} which returns the number of seconds to sleep in the \code{i}-th
iteration between temporary errors.
If not provided (\code{NULL}), tries to read the value (number/function) from the configuration file (stored in \code{reg$sleep}) or defaults to
a function with exponential backoff between 5 and 120 seconds.}

\item{reg}{[\code{\link{Registry}}]\cr
Registry. If not explicitly passed, uses the default registry (see \code{\link{setDefaultRegistry}}).}
}
\value{
[\code{\link{data.table}}] with columns \dQuote{job.id} and \dQuote{chunk}.
}
\description{
Submits defined jobs to the batch system.

If an additional column \dQuote{chunk} is found in the table \code{ids},
jobs will be grouped accordingly to be executed sequentially on the same slave.
The utility functions \code{\link{chunk}}, \code{\link{binpack}} and \code{\link{lpt}}
can assist in grouping jobs.
Jobs are submitted in the order of chunks, i.e. jobs which have chunk number
\code{unique(ids$chunk)[1]} first, then jobs with chunk number \code{unique(ids$chunk)[2]}
and so on. If no chunks are provided, jobs are submitted in the order of \code{ids$job.id}.

After submitting the jobs, you can use \code{\link{waitForJobs}} to wait for the
termination of jobs or call \code{\link{reduceResultsList}}/\code{\link{reduceResults}}
to collect partial results.
The progress can be monitored with \code{\link{getStatus}}.
}
\note{
If you a large number of jobs, disabling the progress bar (\code{options(batchtools.progress = FALSE)})
can significantly increase the performance of \code{submitJobs}.
}
\section{Limiting the number of jobs}{

If requested, \code{submitJobs} tries to limit the number of concurrent jobs of the user by waiting until jobs terminate
before submitting new ones.
This can be controlled by setting \dQuote{max.concurrent.jobs} in the configuration file (see \code{\link{Registry}})
or by setting the resource \dQuote{max.concurrent.jobs} to the maximum number of jobs to run simultaneously.
If both are set, the setting via the resource takes precedence over the setting in the configuration.
}

\section{Array Jobs}{

If your cluster supports array jobs, you can set the resource \code{chunks.as.arrayjobs} to \code{TRUE} in order
to execute chunks as job arrays. To do so, the job must be repeated \code{nrow(jobs)} times via the cluster functions template.
The function \code{\link{doJobCollection}} (which is called on the slave) now retrieves the repetition number from the environment
and restricts the computation to the respective job in the \code{\link{JobCollection}}.
}

\section{Memory Measurement}{

Setting the resource \code{measure.memory} to \code{TRUE} turns on memory measurement:
\code{\link[base]{gc}} is called  directly before and after the job and the difference is
stored in the internal database. Note that this is just a rough estimate and does
neither work reliably for external code like C/C++ nor in combination with threading.
}

\section{Inner Parallelization}{

Inner parallelization is typically done via threading, sockets or MPI.
Two backends are supported to assist in setting up inner parallelization.

The first package is \pkg{parallelMap}.
If you set the resource \dQuote{pm.backend} to \dQuote{multicore}, \dQuote{socket} or \dQuote{mpi},
\code{\link[parallelMap]{parallelStart}} is called on the slave before the first job in the chunk is started
and \code{\link[parallelMap]{parallelStop}} is called after the last job terminated.
This way, the used resources for inner parallelization are set in the same place as the resources for the outer parallelization done by
\pkg{batchtools} and all resources get stored together in the \code{\link{Registry}}.
The user function just has to call \code{\link[parallelMap]{parallelMap}} to start parallelization using the preconfigured backend.

Note that you should set the resource \code{ncpus} to control the number of CPUs to use in \pkg{parallelMap}.
Otherwise \code{ncpus} defaults to the number of available CPUs (as reported by (see \code{\link[parallel]{detectCores}}))
on the executing machine for multicore and socket mode and defaults to the return value of \code{\link[Rmpi]{mpi.universe.size}-1} for MPI.
Your template must be set up to handle the parallelization, e.g. start R with \code{mpirun} or request the right number of CPUs.
You may pass further options like \code{level} to \code{\link[parallelMap]{parallelStart}} via the named list \dQuote{pm.opts}.

The second supported parallelization backend is \pkg{foreach}.
If you set the resource \dQuote{foreach.backend} to \dQuote{seq} (sequential mode), \dQuote{parallel} (\pkg{doParallel}) or
\dQuote{mpi} (\pkg{doMPI}), the requested \pkg{foreach} backend is automatically registered on the slave.
Again, the resource \code{ncpus} is used to determine the number of CPUs.

Neither the namespace of \pkg{parallelMap} nor the namespace \pkg{foreach} are attached.
You have to do this manually via \code{\link[base]{library}} or let the registry load the packages for you.
}

\examples{
### Example 1: Using memory measurement
tmp = makeRegistry(file.dir = NA, make.default = FALSE)

# Toy function which creates a large matrix and returns the column sums
fun = function(n, p) colMeans(matrix(runif(n*p), n, p))

# Arguments to fun:
args = CJ(n = c(1e4, 1e5), p = c(10, 50)) # like expand.grid()
print(args)

# Map function to create jobs
ids = batchMap(fun, args = args, reg = tmp)

# Set resources: enable memory measurement
res = list(measure.memory = TRUE)

# Submit jobs using the currently configured cluster functions
submitJobs(ids, resources = res, reg = tmp)

# Retrive information about memory, combine with parameters
info = ijoin(getJobStatus(reg = tmp)[, .(job.id, mem.used)], getJobPars(reg = tmp))
print(flatten(info))

# Combine job info with results -> each job is aggregated using mean()
flatten(ijoin(info, reduceResultsDataTable(fun = function(res) list(res = mean(res)), reg = tmp)))

### Example 2: Multicore execution on the slave
tmp = makeRegistry(file.dir = NA, make.default = FALSE)

# Function which sleeps 10 seconds, i-times
f = function(i) {
  parallelMap::parallelMap(Sys.sleep, rep(10, i))
}

# Create one job with parameter i=4
ids = batchMap(f, i = 4, reg = tmp)

# Set resources: Use parallelMap in multicore mode with 4 CPUs
# batchtools internally loads the namespace of parallelMap and then
# calls parallelStart() before the job and parallelStop() right
# after the job last job in the chunk terminated.
res = list(pm.backend = "multicore", ncpus = 4)

\dontrun{
# Submit both jobs and wait for them
submitJobs(resources = res, reg = tmp)
waitForJobs(reg = tmp)

# If successfull, the running time should be ~10s
getJobTable(reg = tmp)[, .(job.id, time.running)]

# There should also be a note in the log:
grepLogs(pattern = "parallelMap", reg = tmp)
}
}
