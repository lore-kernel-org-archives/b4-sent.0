From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 20 Jun 2026 21:42:11 -0500
Subject: [PATCH] misc: nsm: bound the device-reported response length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-b4-disp-a54b7dd6-v1-1-79d1f236a854@proton.me>
X-B4-Tracking: v=1; b=H4sIAIJPN2oC/x3MQQqAIBBA0avErBtQM4WuEi3UmWo2FQoRhHdPW
 r7F/y8UzsIFpu6FzLcUOY8G3XeQ9nBsjELNYJRxyhmF0SJJuTCMNnoihzZFCn4gp22Ell2ZV3n
 +5bzU+gECCHn6YgAAAA==
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Arnd Bergmann <arnd@arndb.de>, Alexander Graf <graf@amazon.com>
Cc: linux-kernel@vger.kernel.org, 
 The AWS Nitro Enclaves Team <aws-nitro-enclaves-devel@amazon.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782009730; l=1421;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=JWZdYEnTNclIV/qmVW/4gJrFDqr8fBVcSzL5/nSWf+8=;
 b=gVpskgS/tKVwDdLSoOwrzd9AwOofKwUFFwXYPE/n0kTqSZsnREw13fG3hmce+TBVKnVsBJMzI
 QHQxCeDupm+A3umXIrp+R9E7LzftvVPR+nIpW7ieqzgMsYsra4Qc1Ch
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nsm_sendrecv_msg_locked() stores the virtqueue used-ring length reported
by the NSM device into msg->resp.len without bounding it to the response
buffer. A malicious or buggy backend can report a length larger than the
response buffer; parse_resp_raw() then copies that many bytes out of the
fixed buffer to user space, disclosing adjacent kernel heap (an
out-of-bounds read). The request path already floors its length in
fill_req_raw(); the response path lacks the symmetric check.

Clamp the stored length to the size of the response buffer. Well-behaved
devices report no more than the posted buffer size, so conforming traffic
is unaffected.

Fixes: b9873755a6c8 ("misc: Add Nitro Secure Module driver")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/misc/nsm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/misc/nsm.c b/drivers/misc/nsm.c
index ef7b32742340..f759fbba049a 100644
--- a/drivers/misc/nsm.c
+++ b/drivers/misc/nsm.c
@@ -243,7 +243,7 @@ static int nsm_sendrecv_msg_locked(struct nsm *nsm)
 		goto cleanup;
 	}
 
-	msg->resp.len = len;
+	msg->resp.len = min_t(unsigned int, len, sizeof(msg->resp.data));
 
 	rc = 0;
 

---
base-commit: 1a3746ccbb0a97bed3c06ccde6b880013b1dddc1
change-id: 20260620-b4-disp-a54b7dd6-4cbda73d614b

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

