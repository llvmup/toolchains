include_guard(GLOBAL)

function(toolchains_unset_distribution_find_package_cache_variables)
  unset(Clang_DIR CACHE)
  unset(LLD_DIR CACHE)
  unset(LLVM_DIR CACHE)
  unset(MLIR_DIR CACHE)
  unset(SWIFT_DIR CACHE)
endfunction()
