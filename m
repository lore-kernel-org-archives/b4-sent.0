From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 12 Jun 2026 23:21:14 -0500
Subject: [PATCH] Input: mms114 - reject an oversized device packet size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-b4-disp-dc4b8dc4-v1-1-d7cb0a828d92@proton.me>
X-B4-Tracking: v=1; b=H4sIALnaLGoC/x2MQQqAIBAAvxJ7bkFNzPpKdEjdai8lChGIf0+6D
 MxhpkCmxJRh7gokejjzfTWRfQf+3K6DkENzUEIZYaRCpzFwjhi8drYBLQ2Tm4LRSo/Qspho5/d
 fLmutH/8VYphiAAAA
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Joonyoung Shim <jy0922.shim@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781324473; l=2369;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=6WV4KDtYyMuVstt+ID8Kq5NDhRv4I0YIkiOyhsfbDHc=;
 b=3EG4JelF3w7WLIYr8LmpS+FPVdyNbSggirjrZTZijCyqetaboJgZpK9v1VlMmNnFvJEY4N3ip
 dgKrM21hmn2AJEQumkdvOnK41RrNK8McqHtg3O6aBOsFs/4zPPD46Uo
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mms114_interrupt() reads a packet of touch data from the device into a
fixed-size on-stack buffer

	struct mms114_touch touch[MMS114_MAX_TOUCH];

which holds MMS114_MAX_TOUCH (10) events of MMS114_EVENT_SIZE (8) bytes,
i.e. 80 bytes. The length of the I2C read into it is taken verbatim from
the device:

	packet_size = mms114_read_reg(data, MMS114_PACKET_SIZE);
	if (packet_size <= 0)
		goto out;
	...
	error = __mms114_read_reg(data, MMS114_INFORMATION, packet_size,
			(u8 *)touch);

packet_size is a single device register byte (0x0F) and the only check
is the lower bound packet_size <= 0; it is never bounded against the
size of touch[]. A malfunctioning, malicious or counterfeit controller
(or an attacker tampering with the I2C bus) can report a packet_size of
up to 255, so __mms114_read_reg() writes up to 175 bytes past the end of
touch[] on the IRQ-thread stack: a stack out-of-bounds write that can
overwrite the stack canary, saved registers and the return address.

A well-formed device never reports more than the buffer holds, so reject
an oversized packet and drop the report, consistent with the handler's
other error paths, rather than reading past the buffer.

Fixes: 07b8481d4aff ("Input: add MELFAS mms114 touchscreen driver")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/input/touchscreen/mms114.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/input/touchscreen/mms114.c b/drivers/input/touchscreen/mms114.c
index af462086a65c..4c75f16c503d 100644
--- a/drivers/input/touchscreen/mms114.c
+++ b/drivers/input/touchscreen/mms114.c
@@ -226,6 +226,13 @@ static irqreturn_t mms114_interrupt(int irq, void *dev_id)
 	if (packet_size <= 0)
 		goto out;
 
+	/* the device controls packet_size; reject anything too big for touch[] */
+	if (packet_size > (int)sizeof(touch)) {
+		dev_err(&client->dev, "Invalid packet size %d (max %zu)\n",
+			packet_size, sizeof(touch));
+		goto out;
+	}
+
 	/* MMS136 has slightly different event size */
 	if (data->type == TYPE_MMS134S || data->type == TYPE_MMS136)
 		touch_size = packet_size / MMS136_EVENT_SIZE;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260612-b4-disp-dc4b8dc4-8e39b9d64247

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

