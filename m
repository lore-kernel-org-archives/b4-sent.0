From: Andrew Gigena <mail@andrewgigena.dev>
Subject: [PATCH 0/2] arm64: dts: qcom: sm8150: Add standalone ICE node for
 UFS
Date: Wed, 04 Nov 2026 08:00:35 +0000
Message-Id: <20261104-sm8150-ice-rfc-v1-0-5737b6c2ecc0@andrewgigena.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDQAxA4atI1gYyoxbxKuKik0ZNwR8mWgTx7
 h3b5bd47wSTqGLQZCdE+ajpMie4PAMen/MgqK9k8OQfzlGJNtWuIlQWjD0jhTJ4pqKSmiBFa5R
 ej9+w7f62PbyFt/sC1/UFAWPPRHIAAAA=
X-Change-ID: 20261104-sm8150-ice-rfc-0b4b2c035e80
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793779278; l=2116;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=CG4hBCZDt6NMDb6T/GIIXkxNx2nWNouLk8UK8MwH370=;
 b=8JRR2i0YPt0NbVNbojLUBVDdePC4/V5tgYtK9H/b/gTU6h9PLJFsf69/uXGhsHfkxBT5GGrhc
 fsiviVuRAKnD8B43S4aqE6KQ7f5KX1z7Xh8IoETU8zxmeJ87Eb2Ub+c
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi everyone,

This small series brings the Qualcomm Inline Crypto Engine (ICE) to the
SM8150 (Snapdragon 855) platform, following the same standalone-node style
already used on SM8250 and newer SoCs.

The first patch documents the new compatible in the binding, and the second
converts the UFS node to reference a dedicated ICE node instead of embedding
the registers directly.

I've tested this on a Google Pixel 4 (google-flame) and everything works:
/sys/block/sda/queue/crypto now advertises AES-256-XTS and ext4 reports
encryption as "supported". The ICE self-test completes cleanly during boot.

Happy to adjust anything or add more details if needed. Thanks for reviewing!

Andrew Gigena (2):

dt-bindings: crypto: ice: Document sm8150 inline crypto engine
arm64: dts: qcom: sm8150: Use standalone ICE node for UFS
---
 .../devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml |  1 +
 arch/arm64/boot/dts/qcom/sm8150.dtsi                         | 21 ++++++++++++---------
 2 files changed, 13 insertions(+), 9 deletions(-)

To: Abel Vesa <abelvesa@kernel.org>
To: Herbert Xu <herbert@gondor.apana.org.au>
To: "David S. Miller" <davem@davemloft.net>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-crypto@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>

---
Andrew Gigena (2):
      dt-bindings: crypto: ice: Document sm8150 inline crypto engine
      arm64: dts: qcom: sm8150: Use standalone ICE node for UFS

 .../bindings/crypto/qcom,inline-crypto-engine.yaml |  1 +
 arch/arm64/boot/dts/qcom/sm8150.dtsi               | 25 ++++++++++++++--------
 2 files changed, 17 insertions(+), 9 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-sm8150-ice-rfc-0b4b2c035e80

Best regards,
--  
Andrew Gigena <mail@andrewgigena.dev>

