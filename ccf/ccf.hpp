#ifndef CCF_HH
#define CCF_HH

#include <string>

// Include the export header, this handles the symbol visibility for us
#include "ccf/ccf_export.h"

namespace ccf {
void CCF_EXPORT message(const std::string& m);
} // namespace ccf

#endif // CCF_HH

