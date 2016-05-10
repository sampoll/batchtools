context("hooks")

test_that("hooks", {
  reg = makeRegistry(file.dir = NA, make.default = FALSE)
  if (!is.null(reg$cluster.functions$hooks$pre.do.collection) || !is.null(reg$cluster.functions$hooks$post.sync))
    skip("Hooks already defined by Cluster Functions")
  reg$cluster.functions$hooks = list(
    "pre.do.collection" = function(jc, con, ...) cat(jc$job.hash, "\n", sep = "", file = con),
    "post.sync" = function(reg, ...) cat("post.syn", file = file.path(reg$file.dir, "post.sync.txt"))
  )

  jc = makeJobCollection(1, reg = reg)
  expect_function(jc$hooks$pre.do.collection, args = "jc")

  fn.ps = file.path(reg$file.dir, "post.sync.txt")
  expect_false(file.exists(fn.ps))

  silent({
    batchMap(identity, 1, reg = reg)
    submitJobs(1, reg = reg)
    waitForJobs(1, reg = reg)
  })

  expect_true(file.exists(fn.ps))

  lines = readLog(1, reg = reg)
  expect_true(reg$status[1]$job.hash %in% lines)

  unlink(fn.ps)
})