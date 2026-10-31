From: Jason Lee <jay@ruby.im>
Date: Fri, 30 Oct 2026 20:12:49 -0400
Subject: [PATCH] HID: logitech-dj: Silently drop the G602 vendor report
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-hid-logitech-dj-report-log-v1-1-11e33ba05106@ruby.im>
X-B4-Tracking: v=1; b=H4sIAIAy5WoC/yXMQQqDMBBA0avIrDsQUwy2Vyld6GQ0I8XIJIog3
 r2xXb6/+AckVuEEz+oA5U2SxLmgvlVAoZtHRvHFYI11tbkbDOLxE0fJTAH9hMpL1HwlbMhR1zx
 672wLZbAoD7L/5q/332ntJ6Z8HeE8v6QZ1QF+AAAA
X-Change-ID: 20261030-hid-logitech-dj-report-log-5c6ca59bd628
To: =?utf-8?q?Filipe_La=C3=ADns?= <lains@riseup.net>, 
 Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans de Goede <hansg@kernel.org>, Jason Lee <jay@ruby.im>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793405579; l=2837;
 i=jay@ruby.im; s=20261030; h=from:subject:message-id;
 bh=I1de0OPh3QAdhK16Qx/LZrN+CVkA1e95vFNyssyrv9w=;
 b=5LhGD3dZwizDh75sDmST6C8U34zl9TzgSCgfgxcxF2komIOZsiw/PMmDys2mSG11ujDCAnVzT
 IMCaJfGrUcRAhoMoFGbQLqGt546sHRuyiWWQ1ItHJby2PpPbmq9EQZJ
X-Developer-Key: i=jay@ruby.im; a=ed25519;
 pk=nwVVsNgYUApfCPxmvZyTv0afv7bOSDky/hRrOjJKzys=
X-Endpoint-Received: by B4 Relay for jay@ruby.im/20261030 with auth_id=1367
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the G602 receiver (046d:c537) was added, every mouse click logs
(as logitech-djreceiver 0003:046D:C537.000A):

  Unexpected input report number 128

One user counted 2353 of these lines in a single boot, and the bug has
been reported against kernels from 5.10 to 6.16. Some users blacklist
hid_logitech_dj just to get rid of them.

Report 0x80 is a vendor report in the receiver's report descriptor.
logi_dj_recv_forward_input_report() can only forward reports up to
REPORT_TYPE_RFREPORT_LAST, because it uses the report number as a bit
in reports_supported. Nothing in the driver needs this report, and
logi_dj_raw_event() returns false afterwards, so HID core still
handles it on the receiver.

Hans de Goede suggested in 2021 that the driver should recognise this
report and silently discard it. Do that, and keep the error for any
other unexpected report number.

Fixes: e400071a805d ("HID: logitech-dj: add the G602 receiver")
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=215796
Link: https://lore.kernel.org/lkml/cb14d9fb-9928-4c62-a087-b1a54202d65a@redhat.com/
Suggested-by: Hans de Goede <hansg@kernel.org>
Signed-off-by: Jason Lee <jay@ruby.im>
---
An earlier patch for this ("HID: logitech-dj: stop G602 mouse dmesg
flooding", 2025-02-25) checked the receiver's product ID and got no
replies; this version follows Hans de Goede's 2021 suggestion instead.

Compile tested only; I don't have a G602 to test with.

An AI assistant helped find this bug report and draft the change.
---
 drivers/hid/hid-logitech-dj.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/hid/hid-logitech-dj.c b/drivers/hid/hid-logitech-dj.c
index 6e8db01d27..a433e2ac76 100644
--- a/drivers/hid/hid-logitech-dj.c
+++ b/drivers/hid/hid-logitech-dj.c
@@ -40,6 +40,9 @@
 #define REPORT_TYPE_RFREPORT_FIRST		0x01
 #define REPORT_TYPE_RFREPORT_LAST		0x1F
 
+/* Vendor report sent by the G602 receiver (0xc537) on every click */
+#define REPORT_ID_G602_VENDOR			0x80
+
 /* Command Switch to DJ mode */
 #define REPORT_TYPE_CMD_SWITCH			0x80
 #define CMD_SWITCH_PARAM_DEVBITFIELD		0x00
@@ -1245,7 +1248,13 @@ static void logi_dj_recv_forward_input_report(struct hid_device *hdev,
 	int i;
 
 	if (report > REPORT_TYPE_RFREPORT_LAST) {
-		hid_err(hdev, "Unexpected input report number %d\n", report);
+		/*
+		 * No paired device consumes the G602 vendor report, and HID
+		 * core still handles it on the receiver, so drop it quietly.
+		 */
+		if (report != REPORT_ID_G602_VENDOR)
+			hid_err(hdev, "Unexpected input report number %d\n",
+				report);
 		return;
 	}
 

---
base-commit: a9547379cb381e2a036e3261a6becc17973ac470
change-id: 20261030-hid-logitech-dj-report-log-5c6ca59bd628

Best regards,
--  
Jason Lee <jay@ruby.im>

