#include "toy_dialect.hxx"

#include <mlir/IR/Dialect.h>
#include <mlir/Support/TypeID.h>

MLIR_DEFINE_EXPLICIT_TYPE_ID(ToyDialect);

ToyDialect::ToyDialect(mlir::MLIRContext* ctx)
  : mlir::Dialect{ "toy", ctx, mlir::detail::TypeIDResolver<ToyDialect>::resolveTypeID() }
{
}
