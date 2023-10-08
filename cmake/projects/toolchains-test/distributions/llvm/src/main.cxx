#include <llvm/Support/CommandLine.h>

auto
main(int argc, char const** argv) -> int
{
  llvm::cl::ParseCommandLineOptions(argc, argv);

  return 0;
}
