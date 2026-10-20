// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include "version.h"

#include "kumulus_version.h"

namespace Kumulus
{

QString version()
{
    return QStringLiteral(KUMULUS_VERSION_STRING);
}

} // namespace Kumulus
