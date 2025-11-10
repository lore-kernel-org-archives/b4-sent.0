From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Mon, 10 Nov 2025 16:55:59 +0800
Subject: [PATCH RESEND] checkpatch: Suppress warnings when Reported-by: is
 followed by Link:
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-checkpatch-v1-1-d7ae9d46a376@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAJ6oEWkC/3WOsQ6CMBiEX8X8szVt0ZY6OcjqoKNhoO1f2xiBA
 BIN4d0tjKLj3eW7uwFabAK2sF8N0GAf2lCVUbD1CowvyhuSYKMGTvmOKqaI8WjuddEZTyiXQqY
 StdMIEagbdOE1l13hnF2y0xHy6PvQdlXznjd6Nqe/6npGGLFpqpRMVMJdcXiW8U2Hxm9M9ZgWJ
 oxRusR04SgKttVK/MV4ssCckwnaGEkrvrB8HMcPSpY1Vh4BAAA=
X-Change-ID: 20250919-checkpatch-0276787ebfbe
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, niecheng1@uniontech.com, 
 zhanjun@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762764959; l=1809;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=FjYTg08j4724SsqIOglF1kA+dOmAY6fiyRP1YcvJG9I=;
 b=rTvKvZXykNbHXYZkAOi1/37E0BNa04HyXdwPxvJxULHtnHBMqRXBqkel1I8P7CuwO3SzW+Ttp
 tPm8Xlw/g+HA94YOXxKws9sUiKkG7agt8m5MCv3sAdyAW2Szwtp7uy6
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
Link to previous: https://lore.kernel.org/r/20251023-checkpatch-v1-1-ff73ed1027d6@uniontech.com
---
 scripts/checkpatch.pl | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index 92669904eecc..01c4e70b19a0 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -3205,10 +3205,10 @@ sub process {
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
base-commit: 98ac9cc4b4452ed7e714eddc8c90ac4ae5da1a09
change-id: 20250919-checkpatch-0276787ebfbe

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

