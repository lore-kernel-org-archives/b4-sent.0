From: Casey Tunturi <casey@samaritansolutions.net>
Date: Fri, 07 Aug 2026 20:35:13 -0400
Subject: [PATCH] slimbus: qcom-ngd-ctrl: match downstream DEF_ACT_CHAN
 encoding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-slimbus-def-act-chan-v1-1-fd542efb3d30@samaritansolutions.net>
X-B4-Tracking: v=1; b=H4sIAMB5dmoC/y2NWw6CMBQFt0L6bZNS6AO3YvjovdxqjYC2xZgQ9
 m4RPyeZM2dliWKgxM7VyiK9QwrzVKA+VQxvbroSD0NhJoXUwgrD0yOMsCQ+kOcOM98tDkZQ68E
 4gJqV6TOSD59f9tIfnBa4E+a99TcivZbylw+NgUvEcR7HkM+VUl6S67y3DaI0ziolNdQtYAeN9
 J12wg6akPXb9gUEzzu6xAAAAA==
X-Change-ID: 20260807-slimbus-def-act-chan-b70e4fb7abb1
To: Srinivas Kandagatla <srini@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 stable@vger.kernel.org, Casey Tunturi <casey@samaritansolutions.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786149357; l=1541;
 i=casey@samaritansolutions.net; s=20260808; h=from:subject:message-id;
 bh=e+Q5bDUByME3v5es1Uq1PGS+sTl936AilMSdVkoqZLc=;
 b=a/xPXsw22g09JQ+s5pQ5aOdlYeYCoHIxbI1RBc18HAnf2Bx0vvVajzqTLPH1wp5w3JUUE+fJA
 4QJoSeL6h+jBzT2XrKBvJsFTpkiVKJEkXE2HRbVIpMxq0MszPOj2uB3
X-Developer-Key: i=casey@samaritansolutions.net; a=ed25519;
 pk=oAg9oAsm2ZYWlQFWe7kijWzWnqsQZ/KIY59MAWrTRzk=
X-Endpoint-Received: by B4 Relay for casey@samaritansolutions.net/20260808 with auth_id=926
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During my investigations, and some rather incessant cross-checking of
blueline's SLIMbus path, I found that Qualcomm's downstream driver
packs the first DEF_ACT_CHAN byte differently from mainline. Bits [7:5]
hold the data format; bits [4:0] hold the five-bit client number.

I changed ours to match. It made no immediate difference on my own
hardware: blueline's current values produce 0x0f either way. The
downstream layout is correct and should help devices that use upper
logical-address bits or a non-zero data format.

Fixes: 52490169cddf ("slimbus: ngd: add stream support")
Cc: stable@vger.kernel.org
Signed-off-by: Casey Tunturi <casey@samaritansolutions.net>
---
 drivers/slimbus/qcom-ngd-ctrl.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/slimbus/qcom-ngd-ctrl.c b/drivers/slimbus/qcom-ngd-ctrl.c
index 3071e46d0..14192380d 100644
--- a/drivers/slimbus/qcom-ngd-ctrl.c
+++ b/drivers/slimbus/qcom-ngd-ctrl.c
@@ -1018,7 +1018,8 @@ static int qcom_slim_ngd_enable_stream(struct slim_stream_runtime *rt)
 		if (txn.msg->num_bytes == 0) {
 			int exp = 0, coef = 0;
 
-			wbuf[txn.msg->num_bytes++] = sdev->laddr;
+			wbuf[txn.msg->num_bytes++] =
+				(port->ch.data_fmt << 5) | (sdev->laddr & 0x1f);
 			wbuf[txn.msg->num_bytes] = rt->bps >> 2 |
 						   (port->ch.aux_fmt << 6);
 

---
base-commit: 55f2ea9ff83cc27a85526b14bc9b32f96a08d6ec
change-id: 20260807-slimbus-def-act-chan-b70e4fb7abb1

Best regards,
--  
Casey Tunturi <casey@samaritansolutions.net>

