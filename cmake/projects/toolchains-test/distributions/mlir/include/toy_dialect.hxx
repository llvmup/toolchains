#include <mlir/IR/Dialect.h>
#include <mlir/IR/MLIRContext.h>
#include <mlir/Support/TypeID.h>

class ToyDialect : public mlir::Dialect
{
public:
  explicit ToyDialect(mlir::MLIRContext* ctx);
};

MLIR_DECLARE_EXPLICIT_TYPE_ID(ToyDialect);
