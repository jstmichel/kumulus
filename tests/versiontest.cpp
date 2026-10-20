// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include "version.h"

#include <QTest>

class VersionTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    // #2 R1: the core library builds and its tests run.
    void versionMatchesProject()
    {
        QCOMPARE(Kumulus::version(), QStringLiteral(KUMULUS_EXPECTED_VERSION));
    }
};

QTEST_GUILESS_MAIN(VersionTest)

#include "versiontest.moc"
