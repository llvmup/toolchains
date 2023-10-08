#include "toy_dialect.hxx"

#include <iostream>

auto
main([[gnu::unused]] int argc, [[gnu::unused]] char const** argv) -> int
{
  auto ctx = mlir::MLIRContext();
  auto const dialect = ToyDialect{ &ctx };
  auto const nameSpace = dialect.getNamespace();
  std::cout << std::string{ nameSpace } << "\n";
  return 0;
}
