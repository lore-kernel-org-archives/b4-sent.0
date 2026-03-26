From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 26 Mar 2026 15:03:48 +0100
Subject: [PATCH v2] HID: wiimote: Fix table layout and whitespace errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260326-wiimod-table-v2-1-a11703ccdf41@posteo.net>
X-B4-Tracking: v=1; b=H4sIAMM8xWkC/3XMQQ6CMBCF4auQWTumUyKKK+5hWLRlkEmUkrapG
 sLdrexd/i953wqRg3CEa7VC4CxR/FxCHypwk5nvjDKUBq10o2pq8CXy9AMmYx+MbmiNdcpo016
 gXJbAo7x37taXniQmHz67num3/oEyIaGjsSXL6kT1uVt8TOyPMyfot237ArcxjZepAAAA
X-Change-ID: 20260316-wiimod-table-cd9abc0a2a98
To: David Rheinsberg <david@readahead.eu>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Bogdan Petru <thonkdifferent@outlook.com>, 
 Joshua Jun <joshuajun@vivaldi.net>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774533856; l=7027;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=FgYpCYvhtgKlsH8SHBekcIbkuz7x2xhzDunKOXgRYgY=;
 b=jlQ/SIc+gN4uLo3iBU+tNL2ZJ6ufbZYYpdrx121lMLWovx77IB3Bhvih4SGi05hEJVrkpjGvF
 QHAlRKyXcMeDfUdVRumQuX2Ggq3I0N1K89kzRGNe1Qn1/jfYHKO65sz
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some tab characters snuck into the data layout table for turntable
extensions, which resulted in the table only looking right at a tabstop
of 4, which is uncommon in the kernel. Change them to the equivalent
amount of spaces, which should look correct in any editor.

While at it, also fix the other whitespace errors (trailing spaces at
end of line) introduced in the same commit.

Fixes: 05086f3db530b3 ("HID: wiimote: Add support for the DJ Hero turntable")
Reviewed-by: David Rheinsberg <david@readahead.eu>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- also fix the other whitespace errors in the file
  (suggested by David Rheinsberg <david@readahead.eu>)
- add Reviewed-by
- Link to v1: https://lore.kernel.org/r/20260316-wiimod-table-v1-1-c1f91be05137@posteo.net
---
 drivers/hid/hid-wiimote-modules.c | 58 +++++++++++++++++++--------------------
 1 file changed, 29 insertions(+), 29 deletions(-)

diff --git a/drivers/hid/hid-wiimote-modules.c b/drivers/hid/hid-wiimote-modules.c
index dbccdfa6391672..dccb78bb3afd61 100644
--- a/drivers/hid/hid-wiimote-modules.c
+++ b/drivers/hid/hid-wiimote-modules.c
@@ -2403,7 +2403,7 @@ static const struct wiimod_ops wiimod_guitar = {
 	.in_ext = wiimod_guitar_in_ext,
 };
 
-/* 
+/*
  * Turntable
  * DJ Hero came with a Turntable Controller that was plugged in
  * as an extension.
@@ -2439,15 +2439,15 @@ static const __u16 wiimod_turntable_map[] = {
 static void wiimod_turntable_in_ext(struct wiimote_data *wdata, const __u8 *ext)
 {
 	__u8 be, cs, sx, sy, ed, rtt, rbg, rbr, rbb, ltt, lbg, lbr, lbb, bp, bm;
-	/* 
+	/*
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
@@ -2458,20 +2458,20 @@ static void wiimod_turntable_in_ext(struct wiimote_data *wdata, const __u8 *ext)
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
 	 *   6  | LBB  |  0  | RBG |  BE | LBG | RBB  | XXXX |  XXXX  |
 	 *------+------+-----+-----+-----+-----+------+------+--------+
 	 */
-	
-	be = !(ext[5] & 0x10); 
+
+	be = !(ext[5] & 0x10);
 	cs = ((ext[2] & 0x1e));
 	sx = ext[0] & 0x3f;
 	sy = ext[1] & 0x3f;
@@ -2499,32 +2499,32 @@ static void wiimod_turntable_in_ext(struct wiimote_data *wdata, const __u8 *ext)
 	input_report_abs(wdata->extension.input, ABS_HAT1X, ltt);
 	input_report_abs(wdata->extension.input, ABS_HAT2X, cs);
 	input_report_abs(wdata->extension.input, ABS_HAT3X, ed);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_G_RIGHT], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_G_RIGHT],
 					rbg);
 	input_report_key(wdata->extension.input,
 					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_R_RIGHT],
 					rbr);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_B_RIGHT], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_B_RIGHT],
 					rbb);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_G_LEFT], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_G_LEFT],
 					lbg);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_R_LEFT], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_R_LEFT],
 					lbr);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_B_LEFT], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_B_LEFT],
 					lbb);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_EUPHORIA], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_EUPHORIA],
 					be);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_PLUS], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_PLUS],
 					bp);
-	input_report_key(wdata->extension.input, 
-					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_MINUS], 
+	input_report_key(wdata->extension.input,
+					wiimod_turntable_map[WIIMOD_TURNTABLE_KEY_MINUS],
 					bm);
 
 	input_sync(wdata->extension.input);
@@ -2557,7 +2557,7 @@ static void wiimod_turntable_close(struct input_dev *dev)
 static int wiimod_turntable_probe(const struct wiimod_ops *ops,
 			       struct wiimote_data *wdata)
 {
- 	int ret, i;
+	int ret, i;
 
 	wdata->extension.input = input_allocate_device();
 	if (!wdata->extension.input)
@@ -2594,9 +2594,9 @@ static int wiimod_turntable_probe(const struct wiimod_ops *ops,
 	input_set_abs_params(wdata->extension.input,
 			     ABS_HAT1X, -8, 8, 0, 0);
 	input_set_abs_params(wdata->extension.input,
-			     ABS_HAT2X, 0, 31, 1, 1);	
+			     ABS_HAT2X, 0, 31, 1, 1);
 	input_set_abs_params(wdata->extension.input,
-			     ABS_HAT3X, 0, 7, 0, 0);	 
+			     ABS_HAT3X, 0, 7, 0, 0);
 	ret = input_register_device(wdata->extension.input);
 	if (ret)
 		goto err_free;

---
base-commit: f338e77383789c0cae23ca3d48adcc5e9e137e3c
change-id: 20260316-wiimod-table-cd9abc0a2a98

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

