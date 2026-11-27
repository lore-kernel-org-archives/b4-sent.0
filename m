From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH v3 0/2] arm64: dts: qcom: sm8350: Add the inline crypto
 engine
Date: Fri, 27 Nov 2026 15:24:24 +0000
Message-Id: <20261127-b4-sm8350-ice-v3-0-39c5b4f562cd@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOQQ6CMBAF0KuQrq1pCyXFlfcwLko7hTGBkhaJh
 nB3W9wYo8uf/Hl/VhIhIERyKlYSYMGIfkyhPBTE9HrsgKJNmQgmas6ZpG1F46BKySgaoOC0rSQ
 0pagFSTdTAIeP3btc3zne2xuYOSO50WOcfXjugwvPvX/2wimjTkqoQSvgRp9d8IPFOPmIc/rz6
 ENH8soiPp3m2xHZsRJU1aj0K/vtbNv2ApYFu5QOAQAA
X-Change-ID: 20261105-b4-sm8350-ice-efad45e93262
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, Demeter Barna <me@fromdisposition.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795793066; l=1656;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=kWxMQLo7ohxE4T9YHeCEZxmxXgiJKDWlketpNvOdZy0=;
 b=C7JhKntAjq/5VgGVzZy5b05GWrq+4akbyF0Oc/ezuiRaVtUVs8XNLfvBJXH4Xtik6jz3NWzXN
 7mGwodTD32kCZq2xXADVS6t24qhRTMe0G3PuMRlAChPBUEObFDjVLQY
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350 has an inline crypto engine (ICE v3.2.0) next to its UFS host,
but sm8350.dtsi does not describe it, so ufs-qcom runs without inline
encryption. Add the compatible to the binding and the node to
sm8350.dtsi, as on SM8450.

The TrustZone offers the raw-key SCM calls but not
GENERATE/PREPARE/IMPORT_ICE_KEY, so qcom-ice uses raw keys.

Tested on a Razer Edge 5G with fscrypt v2 on ext4: "AES-256-XTS using
blk-crypto (native)", and files written with and without inlinecrypt
read back correctly either way. dtbs_check is clean for all SM8350
boards.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
Changes in v3:
- dts: region size 0x18000.
- Rebased on next-20261126.
- Picked up the Reviewed-by tags.
- Link to v2: https://patch.msgid.link/20261109-b4-sm8350-ice-v2-0-fd5e84985e90@fromdisposition.org

Changes in v2:
- dt-bindings: drop SM8350 from the legacy single-clock list. It was
  added there by mistake; SM8350 does not need the exemption, its node
  has both clocks and the power domain.
- Link to v1: https://patch.msgid.link/20261105-b4-sm8350-ice-v1-0-f55e6ea8e1ca@fromdisposition.org

---
Demeter Barna (2):
      dt-bindings: crypto: qcom,inline-crypto-engine: Add SM8350
      arm64: dts: qcom: sm8350: Add the inline crypto engine

 .../bindings/crypto/qcom,inline-crypto-engine.yaml          |  1 +
 arch/arm64/boot/dts/qcom/sm8350.dtsi                        | 13 +++++++++++++
 2 files changed, 14 insertions(+)
---
base-commit: a9c48428cbd8d96b26f92631d0db6f8519c5fcc5
change-id: 20261105-b4-sm8350-ice-efad45e93262

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

