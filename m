From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 19 Sep 2025 16:53:33 +0800
Subject: [PATCH] checkpatch: Suppress warnings when Reported-by: is
 followed by Link:
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-checkpatch-v1-1-d889973932fa@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAAwazWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDS0NL3eSM1OTsgsSS5AxdAyNzM3ML89SktKRUJaCGgqLUtMwKsGHRsbW
 1AG4CVdhcAAAA
X-Change-ID: 20250919-checkpatch-0276787ebfbe
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: linux-kernel@vger.kernel.org, niecheng1@uniontech.com, 
 zhanjun@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758272014; l=1763;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=Iyk6yjBAdRxSTomegUDUJm0OiNce0KlYMkESMKoKGyk=;
 b=0hOu1V1/1ECrRUw2hyfnfh4IfkHPYcD+eTUzyG1iEzyK3LZ1oMmLtHteADCJYzSdoYKZxL+5D
 +OaR3TwnuivAu7rLi4UGKGxW5p+CaPRpF/POVW46nJpy1jpDrFyyc+w
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

> The tag should be followed by a Closes: tag pointing to the report,
> unless the report is not available on the web. The Link: tag can be
> used instead of Closes: if the patch fixes a part of the issue(s)
> being reported.

Accroding to Documentation/process/submitting-patches.rst , Link: is
also acceptable to followed a Reported-by:

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 scripts/checkpatch.pl | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index e722dd6fa8ef3d7062988e2b3ec8f5872bdfefeb..f09e3d0536d71d60184f15018202cc36a5f3832e 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -3200,10 +3200,10 @@ sub process {
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
base-commit: 097a6c336d0080725c626fda118ecfec448acd0f
change-id: 20250919-checkpatch-0276787ebfbe

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

