From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/3] Pinctrl support for SM8475
Date: Fri, 31 Jul 2026 14:08:22 -0400
Message-Id: <20260731-sm8475-tlmm-v1-0-3007a8e4aa62@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyNL3eJcCxNzU92SnNxcXbNEUyNj06QUA4u0NCWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgAColWebwAAAA==
X-Change-ID: 20260729-sm8475-tlmm-6a5235bd08ff
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785521444; l=1219;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=IpgEGrH3jJ2w6lBXnKD8/UL0W1WewzjwonRrOQYkU3A=;
 b=umfFbq7v0GTECdE97OY6n0+nQWDrsSF9TDcNOlP2exuEpzwd5onBpKtGpW81gN+Y714LFaxDI
 Knzl+JY4X0HDMKiYbA2hXqmcbc97e5TLR7lSQ9JdjDwxn7KUItfIoTd
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds proper pinctrl support for SM8475.
On downstream, when comparing both waipio (SM8450) and cape (SM8475)
pinctrl drivers, differences regarding PLL clock groups exist.
Match these differences upstream as well.
Some headers present in pinctrl-sm8450 were commonized, so that code
duplication is reduced to some extent.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (3):
      pinctrl: qcom: Commonize pinctrl-sm8450 headers
      dt-bindings: pinctrl: qcom,sm8450-tlmm: Add compatible for SM8475
      pinctrl: qcom: Add SM8475 pinctrl driver

 .../bindings/pinctrl/qcom,sm8450-tlmm.yaml         |    4 +-
 drivers/pinctrl/qcom/Kconfig.msm                   |    9 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-sm8450.c              |  233 +---
 drivers/pinctrl/qcom/pinctrl-sm8450.h              |  246 ++++
 drivers/pinctrl/qcom/pinctrl-sm8475.c              | 1462 ++++++++++++++++++++
 6 files changed, 1722 insertions(+), 233 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260729-sm8475-tlmm-6a5235bd08ff

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

