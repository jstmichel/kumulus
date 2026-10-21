// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include "aboutdata.h"

#include <KAboutData>
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QCoreApplication>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("kumulus");

    KAboutData about = Kumulus::aboutData();
    // `kumulusctl --version` names the command the user typed.
    about.setComponentName(QStringLiteral("kumulusctl"));
    KAboutData::setApplicationData(about);

    QCommandLineParser parser;
    about.setupCommandLine(&parser);
    parser.process(app);
    about.processCommandLine(&parser);

    // The commands (doctor, status, sync, …) come with #25 and #6.
    parser.showHelp(0);
}
