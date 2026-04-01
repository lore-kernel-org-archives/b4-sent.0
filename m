From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 01 Apr 2026 17:47:47 +0800
Subject: [PATCH RESEND] checkpatch: Suppress warnings when Reported-by: is
 followed by Link:
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-checkpatch-v1-1-57da0c7aeb30@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwND3eSM1OTsgsSS5AzdJEvzFIPkpFTz1FRLJaCGgqLUtMwKsGHRSkG
 uwa5+LkqxEPHi0qSs1OQSkElKtbUAvrdnm3YAAAA=
X-Change-ID: 20260401-checkpatch-b97d0cbe7ee9
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: Andrew Morton <akpm@linux-foundation.org>, linux-doc@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, zhanjun@uniontech.com, 
 niecheng1@uniontech.com, kernel@uniontech.com, Petr Vorel <pvorel@suse.cz>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775036867; l=1810;
 i=cryolitia@uniontech.com; s=20260401; h=from:subject:message-id;
 bh=YxanUXAo1zZz/4EvE63HKWNGGvJyrkveItkRihtZCV4=;
 b=D766Pb878qsWoWtRl0Y0dX3lM14ATdLtp1TaIGcCCH6ilanTBA4wKyOB419peRrrBVysnR6RU
 kqnOeWaKfSZCzh3anOpxpDemFvfIqvkNOvBuErAtYFvPCTQzK05soEm
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=kF6wBkp7j9167keuk8Q9RvPgMRPuHlJztbLy0vbJ3K0=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20260401 with auth_id=710
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

> The tag should be followed by a Closes: tag pointing to the report,
> unless the report is not available on the web. The Link: tag can be
> used instead of Closes: if the patch fixes a part of the issue(s)
> being reported.

Accroding to Documentation/process/submitting-patches.rst , Link: is
also acceptable to followed a Reported-by:, if the patch fixes a part
of the issue(s) being reported.

Reviewed-by: Petr Vorel <pvorel@suse.cz>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 scripts/checkpatch.pl | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index e56374662ff7..b8a098061181 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -3223,10 +3223,10 @@ sub process {
 			if ($sign_off =~ /^reported(?:|-and-tested)-by:$/i) {
 				if (!defined $lines[$linenr]) {
 					WARN("BAD_REPORTED_BY_LINK",
-					     "Reported-by: should be immediately followed by Closes: with a URL to the report\n" . $herecurr . "\n");
-				} elsif ($rawlines[$linenr] !~ /^closes:\s*/i) {
+					     "Reported-by: should be immediately followed by Closes: or Link: with a URL to the report\n" . $herecurr . "\n");
+				} elsif ($rawlines[$linenr] !~ /^(closes|link):\s*/i) {
 					WARN("BAD_REPORTED_BY_LINK",
-					     "Reported-by: should be immediately followed by Closes: with a URL to the report\n" . $herecurr . $rawlines[$linenr] . "\n");
+					     "Reported-by: should be immediately followed by Closes: or Link: with a URL to the report\n" . $herecurr . $rawlines[$linenr] . "\n");
 				}
 			}
 		}

---
base-commit: 9147566d801602c9e7fc7f85e989735735bf38ba
change-id: 20260401-checkpatch-b97d0cbe7ee9

Best regards,
--  
Cryolitia PukNgae <cryolitia@uniontech.com>

