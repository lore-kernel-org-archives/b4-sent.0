From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Mon, 16 Mar 2026 15:45:53 +0100
Subject: [PATCH] HID: wiimote: Fix table layout in comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260316-wiimod-table-v1-1-c1f91be05137@posteo.net>
X-B4-Tracking: v=1; b=H4sIAKAXuGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0Mz3fLMzNz8FN2SxKScVN3kFMvEpGSDRKNESwsloJaCotS0zAqwcdG
 xtbUASkamMV4AAAA=
X-Change-ID: 20260316-wiimod-table-cd9abc0a2a98
To: David Rheinsberg <david@readahead.eu>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773672357; l=2872;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=DEDA+lED2vdDSlKY8TBL6dFV7luPreEtxbUEEFq+ZVg=;
 b=2WZbUhgFfRufnmPK7P+mhItvlc144t0bDO+De5Cfb0VUzeUqDaL/CDDUcnbXsGJPZWtxaeXPd
 prgfCVUqQilDii/VLHEPH9C1mADJe/o3xqZRWz2QmWHm3+DWkxcBYAz
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some tab characters snuck into the data layout table for turntable
extensions, which resulted in the table only looking right at a tabstop
of 4, which is uncommon in the kernel. Change them to the equivalent
amount of spaces, which should look correct in any editor.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/hid/hid-wiimote-modules.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/hid/hid-wiimote-modules.c b/drivers/hid/hid-wiimote-modules.c
index dbccdfa6391672..d9e1b4313d6465 100644
--- a/drivers/hid/hid-wiimote-modules.c
+++ b/drivers/hid/hid-wiimote-modules.c
@@ -2442,12 +2442,12 @@ static void wiimod_turntable_in_ext(struct wiimote_data *wdata, const __u8 *ext)
 	/* 
 	 * Byte |  7   |  6  |  5  |  4  |  3  |  2   |  1   |  0     |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
-	 *   0  | RTT<4:3>   | 		      	  SX <5:0> 			      |
-	 *   1  | RTT<2:1>   |				  SY <5:0>			      |
+	 *   0  | RTT<4:3>   |                SX <5:0>                |
+	 *   1  | RTT<2:1>   |                SY <5:0>                |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
 	 *   2  |RTT<0>|  ED<4:3>  |          CS<3:0>        | RTT<5> |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
-	 *   3  |     ED<2:0> 	   | 			 LTT<4:0>			  |
+	 *   3  |     ED<2:0>      |             LTT<4:0>             |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
 	 *   4  |  0   |  0  | LBR |  B- |  0  |  B+  |  RBR | LTT<5> |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
@@ -2458,12 +2458,12 @@ static void wiimod_turntable_in_ext(struct wiimote_data *wdata, const __u8 *ext)
 	 * With Motion+ enabled, it will look like this:
 	 * Byte |  8   |  7  |  6  |  5  |  4  |  3   |  2   |  1     |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
-	 *   1  | RTT<4:3>   | 		      	  SX <5:1> 		 |	  0   |
-	 *   2  | RTT<2:1>   |				  SY <5:1>		 |	  0   |
+	 *   1  | RTT<4:3>   |                SX <5:1>       |    0   |
+	 *   2  | RTT<2:1>   |                SY <5:1>       |    0   |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
 	 *   3  |RTT<0>|  ED<4:3>  |          CS<3:0>        | RTT<5> |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
-	 *   4  |     ED<2:0> 	   | 			 LTT<4:0>			  |
+	 *   4  |     ED<2:0>      |             LTT<4:0>             |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
 	 *   5  |  0   |  0  | LBR |  B- |  0  |  B+  | RBR  |  XXXX  |
 	 *------+------+-----+-----+-----+-----+------+------+--------+

---
base-commit: f338e77383789c0cae23ca3d48adcc5e9e137e3c
change-id: 20260316-wiimod-table-cd9abc0a2a98

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

