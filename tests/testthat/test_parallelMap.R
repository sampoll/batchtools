context("inner parallelization")

reg = makeRegistry(file.dir = NA, make.default = FALSE)
fun = function(i) { fun = function(i) i^2; parallelMap::parallelMap(fun, 1:i)}
ids = batchMap(fun, i = 1:4, reg = reg)

test_that("pm/socket", {
  skip_if_not_installed("parallelMap")
  silent({
    submitJobs(chunkIds(ids, reg = reg), resources = list(pm.backend = "socket", ncpus = 2), reg = reg)
    waitForJobs(reg = reg)
  })
  expect_true(nrow(findDone(reg = reg)) == 4)
})

test_that("pm/multicore", {
  skip_on_os("windows")
  skip_if_not_installed("parallelMap")
  silent({
    submitJobs(chunkIds(ids, reg = reg), resources = list(pm.backend = "multicore", ncpus = 2), reg = reg)
    waitForJobs(reg = reg)
  })
  expect_true(nrow(findDone(reg = reg)) == 4)
})

test_that("pm/mpi", {
  skip_if_not_installed("parallelMap")
  skip_if_not_installed("Rmpi")
  skip_on_cran()
  skip_on_travis()
  silent({
    submitJobs(chunkIds(ids, reg = reg), resources = list(pm.backend = "mpi", ncpus = 2), reg = reg)
    waitForJobs(reg = reg)
  })
  expect_true(nrow(findDone(reg = reg)) == 4)
})