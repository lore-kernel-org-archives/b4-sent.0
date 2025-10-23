From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 23 Oct 2025 09:39:17 +0800
Subject: [PATCH RESEND] checkpatch: Suppress warnings when Reported-by: is
 followed by Link:
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251023-checkpatch-v1-1-ff73ed1027d6@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAESH+WgC/22OsQ7CIBiEX8X8sxigWoqTg10ddDQdgP4IMbYN1
 EbT9N2lHdXx7vLd3QgRg8cI+9UIAQcffdskwdYrME41NyS+Tho45TsqmSTGobl3qjeOUC5yUQj
 UViMkoAto/Wspu8K5vJSnI1TJdz72bXgvGwNb0n91AyOM1EUhpchkxq06PJv0pkfjNqZ9zAszx
 ij9xbSyFHO21TL/xqppmj5dtCzF5wAAAA==
X-Change-ID: 20250919-checkpatch-0276787ebfbe
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: linux-kernel@vger.kernel.org, niecheng1@uniontech.com, 
 zhanjun@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761183569; l=1707;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=vUU7NAqZP6AaVlvTisDIDk7HTxW7vXFFPAdlCDO/Azs=;
 b=WAagc3efadbxJTTEx4RaJF6M2dT0W0eMonzV5c9Ki6HtxvaM9/iNIfCSt1+l2lR3nFNdpP+ic
 NggAiWzaeiVCz/OgjPlmPcy0xnb0cblK0liQW+4s2s8WUHRlu+mdkze
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

