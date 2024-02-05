From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 05 Feb 2024 16:58:14 +0100
Subject: [PATCH] counter: fix privdata alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240205-counter-align-fix-v1-1-4821ced960ab@analog.com>
X-B4-Tracking: v=1; b=H4sIAJYFwWUC/x2MQQqAIBAAvxJ7bsEsCfpKdLBabSE0tCII/97Sc
 QZmXsiUmDIM1QuJbs4cg0BTV7BsNnhCXoVBK90prQwu8QonJbQ7+4COH2ydpdnNptfWgXRHItH
 /c5xK+QAL+cZwYwAAAA==
To: linux-iio@vger.kernel.org
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 William Breathitt Gray <william.gray@linaro.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707148694; l=1491;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=JL+X9g5gr6vuqR5+sLDCtbqSByJMt51WufOmdlrZIjQ=;
 b=M4MdFlfCwoupYtvp/5nltEXUhtZHeVJwQrX0B+cfrKVKkXMrs10ywLLdB8q5vo3+FhV5Z//ks
 yS3T5yn4aDCBg7U3E+qKYy30Gm2TPz2R2gU9au9VPprFq9pKtLuwcz0
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Aligning to the L1 cache does guarantee the same alignment as kmallocing
an object [1]. Furthermore, in some platforms, that alignment is not
sufficient for DMA safety (in case someone wants to have a DMA safe
buffer in privdata) [2].

Sometime ago, we had the same fixes in IIO.

[1]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/base/devres.c#n35
[2]: https://lore.kernel.org/linux-iio/20220508175712.647246-2-jic23@kernel.org/

Fixes: c18e2760308e ("counter: Provide alternative counter registration functions")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
William, if you prefer, we can do something like in IIO and add a
specific COUNTER_DMA_MINALIGN define
---
 drivers/counter/counter-core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/counter/counter-core.c b/drivers/counter/counter-core.c
index 09c77afb33ca..073bf6b67a57 100644
--- a/drivers/counter/counter-core.c
+++ b/drivers/counter/counter-core.c
@@ -34,7 +34,7 @@ struct counter_device_allochelper {
 	 * This is cache line aligned to ensure private data behaves like if it
 	 * were kmalloced separately.
 	 */
-	unsigned long privdata[] ____cacheline_aligned;
+	unsigned long privdata[] __aligned(ARCH_DMA_MINALIGN);
 };
 
 static void counter_device_release(struct device *dev)

---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240205-counter-align-fix-3faebfb572af
--

Thanks!
- Nuno Sá

