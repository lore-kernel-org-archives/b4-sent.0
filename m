From: Demi Marie Obenour <demiobenour@gmail.com>
Date: Sat, 23 May 2026 15:03:57 -0400
Subject: [PATCH 2/2] devicetree: Mark QCE bindings as deprecated
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-delete-qce-v1-2-86105cd7f406@gmail.com>
References: <20260523-delete-qce-v1-0-86105cd7f406@gmail.com>
In-Reply-To: <20260523-delete-qce-v1-0-86105cd7f406@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779563043; l=938;
 i=demiobenour@gmail.com; s=20250731; h=from:subject:message-id;
 bh=UpFD3AMMc7/LD9RiWL4w2/RMipvwMvRcG8UHGJEaez0=;
 b=yo8EFawzIu9uowTwT6gx7418eSwz8NdE8eaN4nlUmJi9nZT0Xb5dT6bfPYa7PttwabD5CoOZk
 jPDSEapbCQmAEMcriUpUZqZEojgTId9Zs1zk5AxN8mRKDz79OkI9g2t
X-Developer-Key: i=demiobenour@gmail.com; a=ed25519;
 pk=4iGY+ynEKxIfs+fIUK9EzsvZ44yGE0GvXLeLTPKKPhI=
X-Endpoint-Received: by B4 Relay for demiobenour@gmail.com/20250731 with auth_id=473
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

They are no longer used by the kernel.  Keep them to avoid unnecessary
churn and because I know next to nothing about devicetree.

Signed-off-by: Demi Marie Obenour <demiobenour@gmail.com>
---
 Documentation/devicetree/bindings/crypto/qcom-qce.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/crypto/qcom-qce.yaml b/Documentation/devicetree/bindings/crypto/qcom-qce.yaml
index 08febd66c22ba8220860f1a59403782d12f8531f..0f378073ddf550ff5954fbe169d5d262a4e46dcf 100644
--- a/Documentation/devicetree/bindings/crypto/qcom-qce.yaml
+++ b/Documentation/devicetree/bindings/crypto/qcom-qce.yaml
@@ -14,6 +14,9 @@ description:
   This document defines the binding for the QCE crypto
   controller found on Qualcomm parts.
 
+  This driver is no longer used and so this binding only exists
+  for backwards compatibility.
+
 properties:
   compatible:
     oneOf:

-- 
2.54.0

