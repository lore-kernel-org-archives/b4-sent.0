From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 03:04:02 -0500
Subject: [PATCH] nfc: fdp: reject an oversized device-reported packet
 length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-f42dce2d-v1-1-186ff3dcbf37@proton.me>
X-B4-Tracking: v=1; b=H4sIAPGxL2oC/x3MMQqAMAxA0atIZgMxthW8ijhUm2qWKi2IIN7d4
 viG/x8oklUKjM0DWS4teqSKrm1g3X3aBDVUAxM7cp3FxWDQcmI0HFbhgGQt9VZ8PyweanZmiXr
 /y2l+3w8CUnDGYgAAAA==
To: David Heidelberg <david@ixit.cz>
Cc: linux-kernel@vger.kernel.org, Robert Dolca <robert.dolca@intel.com>, 
 netdev@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 Samuel Ortiz <sameo@linux.intel.com>, Kang Chen <void0red@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781510641; l=3491;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=YWNzYrdEVobq/LRKI1zxupMwajgzI8infZUte46uWMI=;
 b=lMWqMpt5U5MP/GG7ddKRwOwBSd9MWJ6TtlybHae3my9qt/5BoiELZa8mYaGivOliaUImlcVXw
 XeqDRfTa97nCfUbJ6+R0/geT6IxOaSw4EwpnMcWuaNBfy6+opjMso78
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fdp_nci_i2c_read() reads the length of the next packet from the device
into phy->next_read_size and uses it as the i2c_master_recv() byte count
into a fixed on-stack buffer:

	u8 tmp[FDP_NCI_I2C_MAX_PAYLOAD];		/* 261 bytes */
	...
	len = phy->next_read_size;
	r = i2c_master_recv(client, tmp, len);

When a "length packet" arrives (tmp[0] == 0 && tmp[1] == 0), the next
length is taken verbatim from two device-supplied bytes:

	phy->next_read_size = (tmp[2] << 8) + tmp[3] + 3;

next_read_size is a u16, so this can be driven as high as 65535 - far
larger than the 261-byte tmp[] buffer - and it is never bounded before
the next iteration's i2c_master_recv(). A malfunctioning, malicious or
counterfeit FDP NFC controller (or an attacker tampering with the I2C
bus) that sends such a length packet makes i2c_master_recv() write up to
about 64 KB into the 261-byte on-stack buffer: a stack out-of-bounds
write that clobbers the stack canary, saved registers and the return
address.

Reject a next_read_size larger than the receive buffer the same way a
corrupted packet is already handled - drop it and force resynchronization
- so a device can never drive an over-length read.

Fixes: a06347c04c13 ("NFC: Add Intel Fields Peak NFC solution driver")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
I reproduced the out-of-bounds write with an in-kernel test that drives
the fdp_nci_i2c_read() buffer geometry verbatim under KASAN
(CONFIG_KASAN_STACK=y), modelling i2c_master_recv() delivering
next_read_size device bytes into the 261-byte tmp[] buffer:

  next_read_size = 281, no bound:
    BUG: KASAN: stack-out-of-bounds in i2c_master_recv...
    Write of size 281 ... [48, 309) 'tmp'   (the 261-byte buffer)
  with the device length bounded to <= FDP_NCI_I2C_MAX_PAYLOAD (what this
    patch enforces): no KASAN report.
  a well-formed packet (length <= 261) is unaffected, no KASAN report.

The full device range - next_read_size = 65535 (tmp[2] = 0xff,
tmp[3] = 0xfc; the u16 field truncates the + 3), a 65535-byte write =
65274 bytes past the buffer, smashing the stack canary and the return
address - reproduces the same way under userspace AddressSanitizer on
both -m32 and -m64.
---
 drivers/nfc/fdp/i2c.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/nfc/fdp/i2c.c b/drivers/nfc/fdp/i2c.c
index c1896a1d978c..0392bb49bb4b 100644
--- a/drivers/nfc/fdp/i2c.c
+++ b/drivers/nfc/fdp/i2c.c
@@ -166,6 +166,20 @@ static int fdp_nci_i2c_read(struct fdp_i2c_phy *phy, struct sk_buff **skb)
 		/* Packet that contains a length */
 		if (tmp[0] == 0 && tmp[1] == 0) {
 			phy->next_read_size = (tmp[2] << 8) + tmp[3] + 3;
+
+			/*
+			 * next_read_size is taken from the device and is used
+			 * as the i2c_master_recv() count on the next iteration.
+			 * A value larger than the receive buffer would overflow
+			 * tmp[]; treat it like a corrupted packet and force
+			 * resynchronization.
+			 */
+			if (phy->next_read_size > FDP_NCI_I2C_MAX_PAYLOAD) {
+				dev_dbg(&client->dev, "%s: corrupted packet\n",
+					__func__);
+				phy->next_read_size = FDP_NCI_I2C_MIN_PAYLOAD;
+				goto flush;
+			}
 		} else {
 			phy->next_read_size = FDP_NCI_I2C_MIN_PAYLOAD;
 

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260615-b4-disp-f42dce2d-055035ea37ba

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

