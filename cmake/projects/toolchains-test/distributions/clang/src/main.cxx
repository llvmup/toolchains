#include <clang/Tooling/CommonOptionsParser.h>
#include <llvm/Support/CommandLine.h>

auto
main(int argc, char const** argv) -> int
{
  llvm::cl::OptionCategory ExampleToolCategory("example options");
  const llvm::cl::extrahelp CommonHelp(clang::tooling::CommonOptionsParser::HelpMessage);

  auto ExpectedParser = clang::tooling::CommonOptionsParser::create(argc, argv, ExampleToolCategory);
  if (!ExpectedParser) {
    llvm::errs() << ExpectedParser.takeError();
    return 1;
  }

  auto& OptionsParser = ExpectedParser.get();

  return 0;
}
