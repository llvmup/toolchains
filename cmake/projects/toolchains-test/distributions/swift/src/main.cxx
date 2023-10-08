#include <iostream>
#include <swift/Demangling/Demangle.h>

auto
main([[gnu::unused]] int argc, [[gnu::unused]] char const** argv) -> int
{
  std::string const mangledName = "_$s21ControlFlowFlattening04withaB9FlattenedyyF";
  auto ctx = swift::Demangle::Context();
  auto const name = ctx.demangleSymbolAsString(mangledName);
  std::cout << name << "\n";
  return 0;
}
