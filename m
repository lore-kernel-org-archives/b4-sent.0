From: Demi Marie Obenour <demiobenour@gmail.com>
Subject: [PATCH 0/2] Delete the Qualcomm crypto engine
Date: Sat, 23 May 2026 15:03:55 -0400
Message-Id: <20260523-delete-qce-v1-0-86105cd7f406@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUyNj3ZTUnNSSVN3C5FRdA2Mz4xQjo0QLU0szJaCGgqLUtMwKsGHRsbW
 1AAdO39VcAAAA
X-Change-ID: 20260523-delete-qce-0363d22a8596
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Thara Gopinath <thara.gopinath@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-kernel@vger.kernel.org, linux-crypto@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Eric Biggers <ebiggers@kernel.org>, 
 Ard Biesheuvel <ardb@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Demi Marie Obenour <demiobenour@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779563043; l=2071;
 i=demiobenour@gmail.com; s=20250731; h=from:subject:message-id;
 bh=qKdKW12reljmkI9Y5GL96UhP5eGpAEu75do6kp2GrbQ=;
 b=TtSJ+IKiIz4+J8ZUozDqY5sbAF3vqtXPpM9l1sFNxConO52NyijO6g3Vw49p+zAa/n1QHX5tt
 xTSDIB65+CJC+aZ2Q+K518avBn4FicGdDE2+6UFcs1UfpBdkIoLYdjs
X-Developer-Key: i=demiobenour@gmail.com; a=ed25519;
 pk=4iGY+ynEKxIfs+fIUK9EzsvZ44yGE0GvXLeLTPKKPhI=
X-Endpoint-Received: by B4 Relay for demiobenour@gmail.com/20250731 with auth_id=473
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The only realistic uses I can think of are:

1. Very weak devices where QCE is actually faster.
2. Devices without bitsliced NEON.

Do any such devices exist in the wild?  I have no idea.

Not even compile-tested, but should be trivial as it just deletes code.
I didn't change the device tree beyond marking the bindings as
deprecated.

Signed-off-by: Demi Marie Obenour <demiobenour@gmail.com>
---
Demi Marie Obenour (2):
      crypto: Delete Qualcomm crypto engine driver
      devicetree: Mark QCE bindings as deprecated

 .../devicetree/bindings/crypto/qcom-qce.yaml       |   3 +
 MAINTAINERS                                        |   8 -
 arch/arm/configs/multi_v7_defconfig                |   1 -
 arch/arm64/configs/defconfig                       |   1 -
 drivers/crypto/Kconfig                             | 111 ---
 drivers/crypto/Makefile                            |   1 -
 drivers/crypto/qce/Makefile                        |   9 -
 drivers/crypto/qce/aead.c                          | 841 ---------------------
 drivers/crypto/qce/aead.h                          |  56 --
 drivers/crypto/qce/cipher.h                        |  56 --
 drivers/crypto/qce/common.c                        | 595 ---------------
 drivers/crypto/qce/common.h                        | 104 ---
 drivers/crypto/qce/core.c                          | 271 -------
 drivers/crypto/qce/core.h                          |  64 --
 drivers/crypto/qce/dma.c                           | 135 ----
 drivers/crypto/qce/dma.h                           |  47 --
 drivers/crypto/qce/regs-v5.h                       | 326 --------
 drivers/crypto/qce/sha.c                           | 545 -------------
 drivers/crypto/qce/sha.h                           |  72 --
 drivers/crypto/qce/skcipher.c                      | 529 -------------
 20 files changed, 3 insertions(+), 3772 deletions(-)
---
base-commit: 49e05bb00f2e8168695f7af4d694c39e1423e8a2
change-id: 20260523-delete-qce-0363d22a8596

Best regards,
-- 
Demi Marie Obenour <demiobenour@gmail.com>

