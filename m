From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/3] SM8450 IPA support
Date: Mon, 22 Jun 2026 21:44:16 -0400
Message-Id: <20260622-sm8450-ipa-v1-0-532f0299f96e@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWpRktcRSyKKSPxkw4ikd5ds
 fwW793A6AkZquQGjycxrUtElibQjXYZUFAfDUoqI41Sgucy11LQZoXubZk5U2BrNMRg8+jo+mZ
 185uPdsJufw8QwgNmge/VbgAAAA==
X-Change-ID: 20260622-sm8450-ipa-5da81f67eb65
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782179059; l=1359;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=WqY7LEhsoR33ic8KDIs1qJmmlmw/mQOzPyENBlR+Sc4=;
 b=eLqzm+hzX0hr4/X3p2jgMNy1H3N9C/SRQMjI+Qr9zldSQarf9TCUBMJcw/XQD6XdDHHv/vSUp
 s+RNH1ZyqCfBWCFWxZ1CMISh+u5unjDwZTrzddJ5GLOGDw9E64csddt
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the IPA subsystem found in the SM8450 SoC.
While IPA v5.0 is very similar to IPA v5.1 (heck, it even managed to
properly get the modem up and running), it wasn't perfect, since the
modem would sometimes hang when rebooting or powering the AP off.
After a thorough investigation, I managed to create the proper data file
required for IPA v5.1.

Regards,
Esteban

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (3):
      arm64: dts: qcom: sm8450: Add IPA support
      dt-bindings: net: qcom,ipa: Add SM8450 compatible string
      net: ipa: Add IPA v5.1 data

 .../devicetree/bindings/net/qcom,ipa.yaml          |   1 +
 arch/arm64/boot/dts/qcom/sm8450.dtsi               |  55 ++-
 drivers/net/ipa/Makefile                           |   2 +-
 drivers/net/ipa/data/ipa_data-v5.1.c               | 477 +++++++++++++++++++++
 drivers/net/ipa/gsi_reg.c                          |   1 +
 drivers/net/ipa/ipa_data.h                         |   1 +
 drivers/net/ipa/ipa_main.c                         |   4 +
 drivers/net/ipa/ipa_reg.c                          |   1 +
 8 files changed, 536 insertions(+), 6 deletions(-)
---
base-commit: 948efecf22e49aa4bf55bb73ec79a0ddcfd38571
change-id: 20260622-sm8450-ipa-5da81f67eb65

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

