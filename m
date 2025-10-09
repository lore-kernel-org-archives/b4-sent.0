From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 09 Oct 2025 17:03:31 +0800
Subject: [PATCH RESEND] checkpatch: Suppress warnings when Reported-by: is
 followed by Link:
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251009-checkpatch-v1-1-baf0e614b96a@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAGJ652gC/22OsQ7CIBiEX6X5ZzGFRgEnB7s66Gg6UPojpLFtA
 Imm6btLmB3vLvfdrRDQOwxwqlbwmFxw85QF3VWgrZqeSNyQNbCaHWpJJdEW9bioqC2pGT9ywbE
 3PUIuLB6N+xTYA27tvb1eoMu+dSHO/ls2Ei3pP1yihJJBCCl5Ixtm1Pk95TcRtd3r+QXdtm0/n
 G1MG7AAAAA=
X-Change-ID: 20250919-checkpatch-0276787ebfbe
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: linux-kernel@vger.kernel.org, niecheng1@uniontech.com, 
 zhanjun@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760000615; l=1986;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=GglgwOO4sGxm/0cSmViQByo3JCllbsUslkPqrpN9emg=;
 b=Zh6nWoXotL3I2+RstXgrvRLgEvdeD5diRbxWeBBiU8VsOpFXfPRXdeWD1Py/cm2GTgeuVZ16J
 1BM/EAVNjALCUzPYURiB8Tcokbu+EeFMujIByKIKGrOQDnmdnteKVq6
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
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20250919-checkpatch-v1-1-d889973932fa@uniontech.com
---
 scripts/checkpatch.pl | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index 92669904eecc7a8d2afd3f2625528e02b6d17cd6..01c4e70b19a0992c2f2d56347be9ae73005be025 100755
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
base-commit: ec714e371f22f716a04e6ecb2a24988c92b26911
change-id: 20250919-checkpatch-0276787ebfbe

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

