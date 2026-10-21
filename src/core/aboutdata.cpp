// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

#include "aboutdata.h"

#include "version.h"

#include <KLocalizedString>

#include <QUrl>

namespace Kumulus
{

KAboutData aboutData()
{
    KAboutData about(QStringLiteral("kumulus"),
                     i18nc("@title", "Kumulus"),
                     version(),
                     i18nc("@info", "Sync your cloud storage with KDE, powered by rclone"),
                     KAboutLicense::MIT,
                     i18nc("@info:credit", "© 2026 Kumulus contributors"));

    // No email address for the author: the About page is public.
    about.addAuthor(QStringLiteral("Jonathan St-Michel"),
                    i18nc("@info:credit", "Author and maintainer"),
                    QString(),
                    QStringLiteral("https://github.com/jstmichel"),
                    QUrl(QStringLiteral("https://avatars.githubusercontent.com/jstmichel")));
    about.addCredit(QStringLiteral("Kira"),
                    i18nc("@info:credit", "AI pair programmer: specifications and code"),
                    QStringLiteral("kira@kodara.me"),
                    QStringLiteral("https://github.com/kira-kodara"),
                    QUrl(QStringLiteral("https://avatars.githubusercontent.com/kira-kodara")));
    about.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));

    // Bugs go to the project's issues, not to KDE's tracker.
    about.setHomepage(QStringLiteral("https://github.com/jstmichel/kumulus"));
    about.setBugAddress(QByteArrayLiteral("https://github.com/jstmichel/kumulus/issues"));
    about.setDesktopFileName(QStringLiteral("me.kodara.kumulus"));
    return about;
}

} // namespace Kumulus
