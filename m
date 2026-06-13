From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 00:39:32 -0500
Subject: [PATCH] Input: synaptics-rmi4 - bound the SMBus block read to the
 caller buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-2e033955-v1-1-43ab7281667a@proton.me>
X-B4-Tracking: v=1; b=H4sIABPtLGoC/x3MOwqAMBBF0a3I1A7EjIpxK2Lh50WnUUlAhODeD
 ZanuDdRRFBE6otEAbdGPY+Mqixo2adjA+uaTdbY1rSV8FzzqvFiCyPimoa9h3SdWyBwlLMrwOv
 zL4fxfT/Le4ksYgAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: Benjamin Tissoires <bentiss@kernel.org>, linux-input@vger.kernel.org, 
 Andrew Duggan <aduggan@synaptics.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781329171; l=2461;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=cj8C56VjTvQj5r/vaode4Mpb2LNoByz6cw/zLdVEHGo=;
 b=/0AvHtPbyx29w2TCDiByHC3TOp5drI3nPffW6Y7j3m0t4Zr9t/SRrY6uoVYdjENo7931tRBfB
 KM1Tk9xnbUXCd20XCuYAyi7xBWWkHL24fnj0BEgl/G3WOGmJhNqusRE
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smb_block_read() takes a destination length but passes it nowhere:

	static int smb_block_read(struct rmi_transport_dev *xport,
				  u8 commandcode, void *buf, size_t len)
	{
		...
		retval = i2c_smbus_read_block_data(client, commandcode, buf);

i2c_smbus_read_block_data() has no destination-size argument; it copies
the block count reported by the device (the first SMBus byte, up to
I2C_SMBUS_BLOCK_MAX = 32) into buf. The RMI callers pass buffers far
smaller than 32 bytes - rmi_read_pdt_entry() reads a PDT entry into an
on-stack u8 buf[RMI_PDT_ENTRY_SIZE] (6 bytes) during the PDT scan - so a
malfunctioning, malicious or counterfeit RMI4 SMBus controller (or an
attacker tampering with the I2C bus) that reports a larger block count
overflows the caller's stack buffer by up to 32 - 6 = 26 bytes,
clobbering the stack canary, saved registers and the return address.

Read into a local I2C_SMBUS_BLOCK_MAX-sized buffer and copy back at most
len bytes, so the device can never write past the caller's buffer.

Fixes: 82264d0cf7ae ("Input: synaptics-rmi4 - add SMBus support")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/input/rmi4/rmi_smbus.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/input/rmi4/rmi_smbus.c b/drivers/input/rmi4/rmi_smbus.c
index f3d0b40721df..ea957aba28f1 100644
--- a/drivers/input/rmi4/rmi_smbus.c
+++ b/drivers/input/rmi4/rmi_smbus.c
@@ -177,12 +177,20 @@ static int smb_block_read(struct rmi_transport_dev *xport,
 	struct rmi_smb_xport *rmi_smb =
 		container_of(xport, struct rmi_smb_xport, xport);
 	struct i2c_client *client = rmi_smb->client;
+	u8 data[I2C_SMBUS_BLOCK_MAX];
 	int retval;
 
-	retval = i2c_smbus_read_block_data(client, commandcode, buf);
+	/*
+	 * i2c_smbus_read_block_data() copies the device-reported block count
+	 * (up to I2C_SMBUS_BLOCK_MAX) into the destination and has no way to
+	 * know its size, so read into a local buffer and copy back at most
+	 * len bytes - never past the caller's buffer.
+	 */
+	retval = i2c_smbus_read_block_data(client, commandcode, data);
 	if (retval < 0)
 		return retval;
 
+	memcpy(buf, data, min_t(size_t, retval, len));
 	return retval;
 }
 

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-2e033955-ffe3889ce3e9

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

