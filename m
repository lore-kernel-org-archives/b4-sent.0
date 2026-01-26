From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Subject: [PATCH 0/3] OP-TEE/OP-TEE drivers: simplify context matches
Date: Mon, 26 Jan 2026 11:11:23 +0100
Message-Id: <20260126-optee-simplify-context-match-v1-0-d4104e526cb6@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMs9d2kC/x3MwQqEIBAA0F+JOTdQVgb7K0sHm8YaKBWVpSX69
 6Tju7wLEkfhBJ/qgsg/SeJdQVtXQJtxK6MsxaAapZtWafQhM2OSI+xi/0jeZT4zHibThsswd70
 eZ2uIoBQhspXz7b/TfT8vP92GbgAAAA==
X-Change-ID: 20260126-optee-simplify-context-match-d5b3467bfacc
To: Jens Wiklander <jens.wiklander@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: op-tee@lists.trustedfirmware.org, linux-kernel@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-rtc@vger.kernel.org, 
 Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769422286; l=722;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=tDYIhxiz36gjJoQl3PD4STiraGAmWfjSN46yy4QfZ70=;
 b=6UdZd8aIRGT4L/9vrsiyrk5kkRQCa4+9u0QApVUg2I2zC/EDJOMyYlB50+svgmeaLWEmtkJB8
 cbObPWCi6L2AZqhKJIzHXabmOpA+4OgmlhEeAmksR98tL2uaWZkEYXL
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both the OP-TEE core and some OP-TEE drivers use an if/else expression
to check a boolean which can instead be returned directly. Implement
this change.

---
Rouven Czerwinski (3):
      optee: simplify OP-TEE context match
      hwrng: optee - simplify OP-TEE context match
      rtc: optee: simplify OP-TEE context match

 drivers/char/hw_random/optee-rng.c | 5 +----
 drivers/rtc/rtc-optee.c            | 5 +----
 drivers/tee/optee/device.c         | 5 +----
 3 files changed, 3 insertions(+), 12 deletions(-)
---
base-commit: 63804fed149a6750ffd28610c5c1c98cce6bd377
change-id: 20260126-optee-simplify-context-match-d5b3467bfacc

Best regards,
-- 
Rouven Czerwinski <rouven.czerwinski@linaro.org>

