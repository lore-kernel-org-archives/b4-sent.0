From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 20:24:09 +0700
Subject: [PATCH v2] Input: edt-ft5x06 - ignore contacts with an
 out-of-range slot id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-ft5426-v2-1-cd2bed168051@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBAAv0L2bE3ZLqic/IfhQMsCawRMi0RD+
 LsFrx4nmcwsENgLByiSBTzPEmQcIuAhAddVQ8tK6siAGnN9QqMsqWbKCHNlLqY+Zykx2Qai//T
 cyHtv3cofh5e9s5u2wGZ0EqbRf/bZnG7ev+6cKq1qssQGLWvCa9tX8ji6sYdyXdcvn8NsEbQAA
 AA=
X-Change-ID: 20260723-b4-ft5426-393d8514e4bf
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784813048; l=2253;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=6IHuIpjD8BG+tOqYEL/Wqs7fTLnyHV/DC62HqKtwf7Y=;
 b=zELHXbmUBupqxeC4/gqIng4pEA22m699PwwBoiw64dl6u5a0uRSJh+kME/8Ht0pXqKFBDIDUs
 M47Lx7jLRYjAcpbH/vp289DWcy3VTWSVsh+DZGRrNb4eQ34RbZU6gLm
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The per-contact slot id is taken from the top nibble of the third
report byte, so it can be any value from 0 to 15. The driver only
allocates max_support_points MT slots (2 to 10 depending on the
variant), so a report that carries an id at or above that count - be it
a genuinely higher-numbered contact or a corrupted byte - is outside the
range the input core was told about.

input_mt_slot() silently ignores an ABS_MT_SLOT beyond num_slots and
leaves the current slot unchanged, so the following
input_mt_report_slot_state()/touchscreen_report_pos() pair is applied to
whichever slot happened to be selected last, reporting the contact at the
wrong position. Skip such entries instead.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
A single generic correctness fix: a report whose contact id is at or
above max_support_points selects an MT slot the input core was never
told about, so input_mt_slot() ignores it and the contact is reported
against the previously-selected slot.

The marginal-i2c-bus mitigations that accompanied this in v1 (the
no-regmap-bulk-read property + driver fallback, and the poll-while-down
recovery) are dropped: reviewers correctly noted the bulk-read quirk is
a property of the i2c controller rather than the touch controller and
does not belong in the touch node's binding, so that work is better
placed in the i2c controller (or kept out of tree) and is not part of
this series.
---
 drivers/input/touchscreen/edt-ft5x06.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index d3b1177185a3..d6c3d033b83d 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -331,6 +331,8 @@ static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
 			swap(x, y);
 
 		id = (buf[2] >> 4) & 0x0f;
+		if (id >= tsdata->max_support_points)
+			continue;
 
 		input_mt_slot(tsdata->input, id);
 		if (input_mt_report_slot_state(tsdata->input, MT_TOOL_FINGER,

---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260723-b4-ft5426-393d8514e4bf

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

