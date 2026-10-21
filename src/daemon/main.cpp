// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include "aboutdata.h"

#include <KAboutData>
#include <KCrash>
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcDaemon, "kumulus.daemon")

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("kumulus");

    KAboutData about = Kumulus::aboutData();
    KAboutData::setApplicationData(about);
    KCrash::initialize();

    QCommandLineParser parser;
    about.setupCommandLine(&parser);
    parser.process(app);
    about.processCommandLine(&parser);

    // Only starts and waits for now: the rclone process and the D-Bus API come with #6.
    qCInfo(lcDaemon, "kumulusd %s started", qUtf8Printable(about.version()));
    return app.exec();
}
