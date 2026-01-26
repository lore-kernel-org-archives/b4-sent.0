From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Mon, 26 Jan 2026 11:11:26 +0100
Subject: [PATCH 3/3] rtc: optee: simplify OP-TEE context match
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-optee-simplify-context-match-v1-3-d4104e526cb6@linaro.org>
References: <20260126-optee-simplify-context-match-v1-0-d4104e526cb6@linaro.org>
In-Reply-To: <20260126-optee-simplify-context-match-v1-0-d4104e526cb6@linaro.org>
To: Jens Wiklander <jens.wiklander@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: op-tee@lists.trustedfirmware.org, linux-kernel@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-rtc@vger.kernel.org, 
 Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769422286; l=831;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=QLdJDajsDAHZ5Jp/WvnfqKpNSpcj2i8eHxM4elD1BXk=;
 b=hUChSt/PerjC7blQ6RZipCBKxqnlwex+ECe8CfZ0Wb6SYUNshrn+Zn+ndFsgEjw9ve3jh9TQk
 BW08OOTuUhyCZjXixJ0Uk91h8vNM070X6eNfQyVTmMuXGcKhVgSHyg8
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simplify the TEE implementor ID match by returning the boolean
expression directly instead of going through an if/else.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
 drivers/rtc/rtc-optee.c | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/drivers/rtc/rtc-optee.c b/drivers/rtc/rtc-optee.c
index 184c6d142801..2f18be3de684 100644
--- a/drivers/rtc/rtc-optee.c
+++ b/drivers/rtc/rtc-optee.c
@@ -541,10 +541,7 @@ static int optee_rtc_read_info(struct device *dev, struct rtc_device *rtc,
 
 static int optee_ctx_match(struct tee_ioctl_version_data *ver, const void *data)
 {
-	if (ver->impl_id == TEE_IMPL_ID_OPTEE)
-		return 1;
-	else
-		return 0;
+	return (ver->impl_id == TEE_IMPL_ID_OPTEE);
 }
 
 static int optee_rtc_probe(struct device *dev)

-- 
2.52.0

