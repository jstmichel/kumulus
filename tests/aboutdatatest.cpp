// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include "aboutdata.h"

#include <QTest>

class AboutDataTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    // #2 R7: the About page shows the project version.
    void versionMatchesProject()
    {
        QCOMPARE(Kumulus::aboutData().version(), QStringLiteral(KUMULUS_EXPECTED_VERSION));
    }

    // The desktop file and the About page name the same application.
    void desktopFileNameIsAppId()
    {
        QCOMPARE(Kumulus::aboutData().desktopFileName(), QStringLiteral("me.kodara.kumulus"));
    }
};

QTEST_GUILESS_MAIN(AboutDataTest)

#include "aboutdatatest.moc"
