From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 19 Jun 2026 21:36:29 -0500
Subject: [PATCH 1/2] ata: libata-core: Clamp the concurrent positioning
 ranges count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-b4-disp-6200c44e-v1-1-4624a4707d9e@proton.me>
References: <20260619-b4-disp-6200c44e-v1-0-4624a4707d9e@proton.me>
In-Reply-To: <20260619-b4-disp-6200c44e-v1-0-4624a4707d9e@proton.me>
To: Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781922988; l=1600;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=8PNoOz3QbWUZ2Z1u7nRPinneyr22XG/IsUnvRsy1/Zo=;
 b=xTKR/NgL29fdsQcXNnou7yNH31sszPGgziqf/bsJFN0stPsP4wI2ma0JvRGzp/krJfGNO2V66
 QSxtOKuQMWKDQJ7XwobHaZP3EpZMCHTZDNNR8+jHrWTzFG9hcjdR1WG
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ata_dev_config_cpr() sizes the log buffer from the length reported in
the GPL directory but takes the number of range descriptors from buf[0],
which the device reports independently. A device advertising a small log
but a large count makes the descriptor loop read past the buffer: a
one-sector log with buf[0] = 255 reaches up to 7704 bytes beyond the
512-byte allocation, a slab out-of-bounds read whose contents are then
handed to the initiator through INQUIRY VPD page B9h.

Clamp the descriptor count to what the allocated buffer holds, as
sd_read_cpr() already does on the SCSI side.

Fixes: c745dfc541e7 ("libata: fix reading concurrent positioning ranges log")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/ata/libata-core.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/ata/libata-core.c b/drivers/ata/libata-core.c
index 3d0027ec33c2..e8d708f0810e 100644
--- a/drivers/ata/libata-core.c
+++ b/drivers/ata/libata-core.c
@@ -2832,6 +2832,17 @@ static void ata_dev_config_cpr(struct ata_device *dev)
 	if (!nr_cpr)
 		goto out;
 
+	/*
+	 * The log size is reported in the GPL directory independently of the
+	 * number of range descriptors in buf[0]. Clamp the count to what the
+	 * allocated buffer holds so the loop below cannot read past it.
+	 */
+	if (buf_len < 64 + (size_t)nr_cpr * 32) {
+		nr_cpr = buf_len > 64 ? (buf_len - 64) / 32 : 0;
+		if (!nr_cpr)
+			goto out;
+	}
+
 	cpr_log = kzalloc_flex(*cpr_log, cpr, nr_cpr);
 	if (!cpr_log)
 		goto out;

-- 
2.43.0

