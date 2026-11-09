From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH v2 0/2] arm64: dts: qcom: sm8350: Add the inline crypto
 engine
Date: Mon, 09 Nov 2026 13:55:28 +0000
Message-Id: <20261109-b4-sm8350-ice-v2-0-fd5e84985e90@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOwQqDMBBEf0Vy7pYkGrE9+R/FQ4wb3YJGslZax
 H9vtOceH8y8mU0wRkIW92wTEVdiClMCfcmEG+zUI1CXWGipS6WkgbYAHqvcSCCHgN52hcFbrks
 tUmeO6Ol9+h7Nj/nVPtEth+RIDMRLiJ9zcFVH7p97VSDBG4Ml2gqVs7WPYeyI58C0pJ/XEHvR7
 Pv+BRhzvH/GAAAA
X-Change-ID: 20261105-b4-sm8350-ice-efad45e93262
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794232535; l=1627;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=iEvs/mRmPbkyFB2ueYR7aReCKd4lWIPF0+wKUolEjTM=;
 b=0eKFcFbHOOY66ttJSOqjNRwmxTPtozm6mbhfCF34b+vka5QQjZmzCFeRKeUWZ3WszvpZezeLz
 QOs2CFVgBtCCm9/rKi7XgKExoDxccLuVKfirFVALavSnnHulU+34MSr
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350 has an inline crypto engine (ICE v3.2.0) next to its UFS host,
but sm8350.dtsi does not describe it, so ufs-qcom runs without inline
encryption. Add the compatible to the binding and the node to
sm8350.dtsi, as on SM8450.

The region covers the engine (0x1d88000, 0x8000) and its key manager
(0x1d90000, 0x9000), as in Qualcomm's SM8350 device tree; the clocks and
the power domain are those of SM8450. The TrustZone offers the raw-key
SCM calls but not GENERATE/PREPARE/IMPORT_ICE_KEY, so qcom-ice uses raw
keys.

Tested on a Razer Edge 5G with fscrypt v2 on ext4: "AES-256-XTS using
blk-crypto (native)", and files written with and without inlinecrypt
read back correctly either way. dtbs_check is clean for all SM8350
boards.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
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
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-b4-sm8350-ice-efad45e93262

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

