From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 09:33:53 +0100
Subject: [PATCH 1/5] Input: s6sy761 - apply the touchscreen inversion and
 swap properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-s6sy761-fts1ba90a-v1-1-999b3cfaf82d@dxdmail.cc>
References: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
In-Reply-To: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794126835; l=1311;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=/HYbfSgZDXp9Nhf0xICDcKIqRlQIrJcsLDH8yaqlolc=;
 b=WIBweEs1vzSWji5B+Q5cDYE8grceEaquTXhxFfb0/alutLPE7YnHAt4Lx3W4WDVhOmm2JtScd
 X6OGbbzr7oMBF3zTfjRRNxXHtSMkewgR9CYtYaNvaT/ws1BunzLaSR/
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver parses the touchscreen properties, which swaps the axis
ranges for touchscreen-swapped-x-y, but reports the raw coordinates, so
inverted and swapped axes do not work. Report them through
touchscreen_report_pos(). No in-tree device tree sets these properties
for this driver.

Fixes: 0145a7141e59 ("Input: add support for the Samsung S6SY761 touchscreen")
Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 drivers/input/touchscreen/s6sy761.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/s6sy761.c b/drivers/input/touchscreen/s6sy761.c
index 1afa38850f12..967fd222f0d6 100644
--- a/drivers/input/touchscreen/s6sy761.c
+++ b/drivers/input/touchscreen/s6sy761.c
@@ -153,8 +153,7 @@ static void s6sy761_report_coordinates(struct s6sy761_data *sdata,
 	input_mt_slot(sdata->input, tid);
 
 	input_mt_report_slot_state(sdata->input, MT_TOOL_FINGER, true);
-	input_report_abs(sdata->input, ABS_MT_POSITION_X, x);
-	input_report_abs(sdata->input, ABS_MT_POSITION_Y, y);
+	touchscreen_report_pos(sdata->input, &sdata->prop, x, y, true);
 	input_report_abs(sdata->input, ABS_MT_TOUCH_MAJOR, major);
 	input_report_abs(sdata->input, ABS_MT_TOUCH_MINOR, minor);
 	input_report_abs(sdata->input, ABS_MT_PRESSURE, z);

-- 
2.56.0

