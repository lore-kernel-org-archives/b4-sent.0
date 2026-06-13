From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 01:12:34 -0500
Subject: [PATCH] Input: cyapa - bound the SMBus block reads to the caller
 buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-8e550272-v1-1-9658cf8292c2@proton.me>
X-B4-Tracking: v=1; b=H4sIANH0LGoC/x3MQQqAIBBA0avErBtQ06yuEi3MppqNhUIE4t2Tl
 m/xf4ZEkSnB1GSI9HDiK1TItgF/unAQ8lYNSqhe9LLDVePG6caBjBHKKnTSaW290WIYoWZ3pJ3
 ffzkvpXxVRhvSYgAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: Dudley Du <dudl@cypress.com>, Benson Leung <bleung@chromium.org>, 
 linux-input@vger.kernel.org, Daniel Kurtz <djkurtz@chromium.org>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781331153; l=3371;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=GV3OIu9GRRKjdqcaWZ4II7ZaN9d38honFN8iwiNx23I=;
 b=3CZ2VsGndrYewICriNIQ9fnVkJilLdoqSN4+F9OMOHEaFaDrPxldIzWCYCZS1s4Raaf8L3R8Z
 RCmFL4lyw8BB4T8yp0vOuvt6y0ggRCSXzrit/hF4vLovmqPGiaXTBTQ
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cyapa_smbus_read_block() takes the expected length of the result but
never uses it to bound the destination:

	if (SMBUS_GROUP_BLOCK_CMD_MASK & cmd) {
		smbus_cmd = SMBUS_ENCODE_RW(cmd, SMBUS_READ);
		ret = i2c_smbus_read_block_data(client, smbus_cmd, values);
		goto out;
	}
	...
		buf = values + I2C_SMBUS_BLOCK_MAX * index;
		ret = i2c_smbus_read_block_data(client, smbus_cmd, buf);

i2c_smbus_read_block_data() has no destination-size argument; it copies
the block count reported by the device (the first SMBus byte, up to
I2C_SMBUS_BLOCK_MAX = 32) into the buffer. Several callers pass buffers
smaller than 32 bytes - cyapa_detect() reads CYAPA_CMD_BL_STATUS into an
on-stack u8 status[BL_STATUS_SIZE] (3 bytes), and the group-query path
reads into u8 query_data[QUERY_DATA_SIZE] (27 bytes) - so a
malfunctioning, malicious or counterfeit trackpad (or an attacker
tampering with the SMBus) that reports a larger block count overflows
the caller's stack buffer by up to 32 - 3 = 29 bytes, clobbering the
stack canary, saved registers and the return address.

Read each block into a local I2C_SMBUS_BLOCK_MAX-sized buffer and copy
back only the expected number of bytes, in both the group-block branch
and the multi-block loop, so the device can never write past the
caller's buffer.

Fixes: 6ddaf744c9f6 ("Input: cyapa - add support for smbus protocol")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/input/mouse/cyapa_gen3.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/drivers/input/mouse/cyapa_gen3.c b/drivers/input/mouse/cyapa_gen3.c
index fc3fb954523b..832775bb7182 100644
--- a/drivers/input/mouse/cyapa_gen3.c
+++ b/drivers/input/mouse/cyapa_gen3.c
@@ -247,27 +247,37 @@ ssize_t cyapa_smbus_read_block(struct cyapa *cyapa, u8 cmd, size_t len,
 	ssize_t ret;
 	u8 index;
 	u8 smbus_cmd;
-	u8 *buf;
+	u8 buf[I2C_SMBUS_BLOCK_MAX];
 	struct i2c_client *client = cyapa->client;
 
 	if (!(SMBUS_BYTE_BLOCK_CMD_MASK & cmd))
 		return -EINVAL;
 
+	/*
+	 * i2c_smbus_read_block_data() copies the device-reported block count
+	 * (up to I2C_SMBUS_BLOCK_MAX) into its buffer and has no way to know
+	 * its size, so read into a local buffer and copy back at most the
+	 * expected number of bytes - never past the caller's buffer.
+	 */
 	if (SMBUS_GROUP_BLOCK_CMD_MASK & cmd) {
 		/* read specific block registers command. */
 		smbus_cmd = SMBUS_ENCODE_RW(cmd, SMBUS_READ);
-		ret = i2c_smbus_read_block_data(client, smbus_cmd, values);
+		ret = i2c_smbus_read_block_data(client, smbus_cmd, buf);
+		if (ret > 0)
+			memcpy(values, buf, min_t(size_t, ret, len));
 		goto out;
 	}
 
 	ret = 0;
 	for (index = 0; index * I2C_SMBUS_BLOCK_MAX < len; index++) {
+		size_t offset = index * I2C_SMBUS_BLOCK_MAX;
+
 		smbus_cmd = SMBUS_ENCODE_IDX(cmd, index);
 		smbus_cmd = SMBUS_ENCODE_RW(smbus_cmd, SMBUS_READ);
-		buf = values + I2C_SMBUS_BLOCK_MAX * index;
 		ret = i2c_smbus_read_block_data(client, smbus_cmd, buf);
 		if (ret < 0)
 			goto out;
+		memcpy(values + offset, buf, min_t(size_t, ret, len - offset));
 	}
 
 out:

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-8e550272-a1a447c54089

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

