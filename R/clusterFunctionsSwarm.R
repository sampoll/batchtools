#' @title ClusterFunctions for Docker Swarm Execution
#'
#' @description
#' Jobs are spawned by running \code{docker service create -d --replicas 1 --restart-condition none} 
#' This results in a one-shot service that runs one task and shuts down.
#' Mandatory argument is \code{-e JOB="jpath"} the hash for the job to run.
#' \code{--mount type=bind,source=path,destination=path} 
#'
#' @inheritParams makeClusterFunctions
#' @param cname Repository and container name
#' @param ccmd Command to execute in container
#'
#' @return [\code{\link{ClusterFunctions}}].
#' @family ClusterFunctions
#' @export
#' @examples
#' \dontrun{
#' # cluster functions for multicore execution on the local machine
#' makeClusterFunctionsSwarm("spollack/r-batchtools-test3", "./run.sh")
#' }

makeClusterFunctionsSwarm = function(cname, ccmd, fs.latency = 65) { # nocov start

  # make empty list of service objects
  script = system.file("bin", "swarm-helper", package = "batchtools")

  submitJob = function(reg, jc) {
    assertRegistry(reg, writeable = TRUE)
    assertClass(jc, "JobCollection")

    # no need to do any load-balancing - swarm does it 
    # launch service, get service-jobhash association, make structure and put in list

    args = c("start-job", cname, ccmd, jc$uri, jc$log.file, ref$file.dir, "/registry")
    res <- runOSCommand(script, args);

    if (res$exit.code != 0)  {
      makeSubmitJobResult(status = 101L, batch.id = NA_character_, msg = "Submit failed.")
    }
    else  {
      makeSubmitJobResult(status = 101L, batch.id = res$out)
    }
  }

  killJob = function(reg, batch.id) {
    assertRegistry(reg, writeable = TRUE)
    assertString(batch.id)

    args <- c("kill-job", batch.id)
    res <- runOSCommand(script, args)
  }

  listJobsRunning = function(reg) {

    assertRegistry(reg, writeable = FALSE)
    args <- c("list-jobs")
    res <- runOSCommand(script, args)
  
    v <- strsplit(res$out, " ")[[1]]
    get.batchid <- function(vv)  { vvv = strsplit(vv, ":"); return(vvv[[1]][1]) }
    get.state <- function(vv)  { vvv = strsplit(vv, ":"); return(vvv[[1]][3]) }
    b <- sapply(v, get.batchid)
    s <- sapply(v, get.state)
    unname(b[s == "Running"])

  }

  # Remove services whose tasks are Complete
  rmcomplete <- function(reg)  {
    args <- c("rm-complete")
    res <- runOSCommand(script, args)
  }

  # Remove all services 
  rmcomplete <- function(reg)  {
    args <- c("rm-all")
    res <- runOSCommand(script, args)
  }

  makeClusterFunctions(name = "Swarm", submitJob = submitJob, killJob = killJob, listJobsRunning = listJobsRunning,
    store.job.collection = TRUE, fs.latency = fs.latency, hooks=list(post.sync=rmcomplete, pre.submit=rmall))

} # nocov end








