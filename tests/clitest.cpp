// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include <QProcess>
#include <QTest>

class CliTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    // #2 R7: `kumulusctl --version` prints the project version.
    void versionPrintsProjectVersion()
    {
        QProcess process;
        process.start(QStringLiteral(KUMULUSCTL_PATH), {QStringLiteral("--version")});
        QVERIFY(process.waitForFinished());
        QCOMPARE(process.exitStatus(), QProcess::NormalExit);
        QCOMPARE(process.exitCode(), 0);
        QCOMPARE(QString::fromUtf8(process.readAllStandardOutput()).trimmed(), QStringLiteral("kumulusctl " KUMULUS_EXPECTED_VERSION));
    }
};

QTEST_GUILESS_MAIN(CliTest)

#include "clitest.moc"
