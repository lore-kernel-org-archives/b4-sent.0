From: Felix Huang <akafelixab@gmail.com>
Date: Sat, 28 Nov 2026 10:39:24 -0500
Subject: [PATCH v3] i2c: diolan-u2c: Use __le32 when reading serial number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-i2c-diolan-u2c-unaligned-v3-1-a1343865404b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NzQ6CMBAGX8X0bE27ID+efA/jobQLrIHWUCAaw
 rvb4oWT8baTfDuzMI8DoWeXw8IGnMmTswGS44HpVtkGOZnADARkUkLOCTQ35Dpl+RTOyaqOGou
 Gw7ks0WBRqBJYeH8OWNNrU9/uX/ZT9UA9Rl9ctORHN7y39izj7o/MLLnkQicZyCrPSmGuTa+oO
 2nXs5iZYS8qfoggiHQmoFB5WkNa70Xrun4AOT+BvhsBAAA=
X-Change-ID: 20261127-i2c-diolan-u2c-unaligned-2599ede88a92
To: Guenter Roeck <linux@roeck-us.net>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org, Felix Huang <akafelixab@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795880364; l=2009;
 i=akafelixab@gmail.com; s=20261128; h=from:subject:message-id;
 bh=nFFfjDOwR/ESphf3Pfj3xpOEG99vjKOKWw9a9fqH+oc=;
 b=PmERjXF6uV+F4F64XkCHTFLZZL/f2reCSx+ieI3NkI9rquZ7W28b3lVWjCsCGvVSDzwDsj3ey
 S3tGrbxWqjiBKwfk/OHFeDAmrixR6w8RkW9rzY2Z4w4zyxwDgFofTjq
X-Developer-Key: i=akafelixab@gmail.com; a=ed25519;
 pk=Axl3BM1UWa+m0/AWcEhRIdIk/WY9FnY4wZkyQn64uVY=
X-Endpoint-Received: by B4 Relay for akafelixab@gmail.com/20261128 with auth_id=1670
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sparse reports:

  drivers/i2c/busses/i2c-diolan-u2c.c:290:26: warning:
  cast to restricted __le32

Cast the serial-number buffer pointer to __le32 before passing it to
le32_to_cpu(). This makes the byte-order conversion explicit and
silences the sparse warning.

Signed-off-by: Felix Huang <akafelixab@gmail.com>
---
Changes in v3:
- Cast the serial-number buffer pointer to __le32 before passing it to
  le32_to_cpu(), as suggested by Guenter Roeck.
- Keep the serial variable and do not use get_unaligned_le32().
- Reword the commit message to accurately describe the motivation.
- Link to v2: https://patch.msgid.link/20261128-i2c-diolan-u2c-unaligned-v2-1-c6028a74f24f@gmail.com

Changes in v2:
- Reword the commit message to accurately describe the motivation.
- The serial-number buffer is naturally aligned; do not claim that the
  existing access may be unaligned.
- Focus on fixing the sparse "cast to restricted __le32" warning. 
- Link to v1: https://patch.msgid.link/20261127-i2c-diolan-u2c-unaligned-v1-1-0c3621b7690d@gmail.com

To: Guenter Roeck <linux@roeck-us.net>
To: Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org
---
 drivers/i2c/busses/i2c-diolan-u2c.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-diolan-u2c.c b/drivers/i2c/busses/i2c-diolan-u2c.c
index d502f6e47..77471011f 100644
--- a/drivers/i2c/busses/i2c-diolan-u2c.c
+++ b/drivers/i2c/busses/i2c-diolan-u2c.c
@@ -287,7 +287,7 @@ static void diolan_get_serial(struct i2c_diolan_u2c *dev)
 
 	ret = diolan_usb_cmd(dev, CMD_GET_SERIAL, true);
 	if (ret >= 4) {
-		serial = le32_to_cpu(*(u32 *)dev->ibuffer);
+		serial = le32_to_cpu(*(__le32 *)dev->ibuffer);
 		dev_info(&dev->interface->dev,
 			 "Diolan U2C serial number %u\n", serial);
 	}

---
base-commit: f4585067150b85e33f60876149a6e742928da75e
change-id: 20261127-i2c-diolan-u2c-unaligned-2599ede88a92

Best regards,
--  
Felix Huang <akafelixab@gmail.com>

