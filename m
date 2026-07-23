From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 18:27:08 +0700
Subject: [PATCH 1/4] Input: edt-ft5x06 - ignore contacts with an
 out-of-range slot id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-ft5426-v1-1-d4b4e32be042@gmail.com>
References: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
In-Reply-To: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784806028; l=1395;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=D0XuFOboekFyulaNFU7MxXVtoV8b4Kp9OM9aoWYiFTo=;
 b=oso77UFU2tWgwp7TRwwFdKsBZiu0lKjhhcLPJNm0fpO3hsaHh+HTKbV8LSrOdbE2Q3op2RQu1
 6OwLQ8qvABnD13r3CHrfXX2JWjVBjZF531nfbvGbgHss0RKGNsql16+
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

-- 
2.55.0

