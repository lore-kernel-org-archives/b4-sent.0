From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH 0/2] arm64: dts: qcom: sm8350: Add the inline crypto engine
Date: Thu, 05 Nov 2026 15:29:29 +0000
Message-Id: <20261105-b4-sm8350-ice-v1-0-f55e6ea8e1ca@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrB1IohHbq0gXGn91CrUlU0UQ7
 25al9/ivZ0UUaB0z3aKWEXlPSfYPKMwtfMIlj6ZnHGVtcZzV7K+6sIblgDG0Palx61wlaPUfCI
 G2f6/5nFZl+6J8P1N6DhOIthlk3EAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793892578; l=1321;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=suhANv7bOMWCMhQ8xWZ6gPrL/h1+3YpM+oSA0xcQSBk=;
 b=Lit8UbrinNlhQJDYfrDII+oLqibmjgAWVno/4aiYqq5Nz9BX7KLkgZUl0bztXoJBkV5NCQPRs
 LQzq48Aekn2BdADzCUZsBQY5LTfjNg8Gd+bP+qKQvy6LHUJ4o3pR1gh
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
Demeter Barna (2):
      dt-bindings: crypto: qcom,inline-crypto-engine: Add SM8350
      arm64: dts: qcom: sm8350: Add the inline crypto engine

 .../bindings/crypto/qcom,inline-crypto-engine.yaml          |  2 ++
 arch/arm64/boot/dts/qcom/sm8350.dtsi                        | 13 +++++++++++++
 2 files changed, 15 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-b4-sm8350-ice-efad45e93262

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

