From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/4] Pinctrl support for SM8475
Date: Sun, 02 Aug 2026 03:30:53 -0400
Message-Id: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WN0Q6CIBhGX8X919EQFKir3qN5gfqbtBAH5GqOd
 w+tmy7Pdr7zrRDQGwxwLlbwuJhg3JSBHQroRj3dkJg+MzDKBJXsRIJVlaxJfFhLhK4Zr9ueqmG
 AvJg9Dua1167Nl8OzvWMXt8RmjCZE59/73VJu3q/My7/yUhJKOKVSK6y0FuwyexfddLQITUrpA
 2v0Zrq4AAAA
X-Change-ID: 20260729-sm8475-tlmm-6a5235bd08ff
To: Bjorn Andersson <andersson@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785656048; l=1445;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=4ZUggOIXV7HyuwAJr8C1xnQDFvBL6VwcHMlJnp43JO8=;
 b=9NwFykxeyiwB/Y7GSu2pVTif+zyQRrHKJF341TFNTng+5Qrxbd5lRu0cV39gBzVxIE/JpMO2W
 fEMBRtMIpbbA9jt/4kHKdcTFqVS/9KJfkiTbp8D/wvHq7DgD9Uairjn
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
Changes in v2:
- Remove duplicate gpio81 reference (Sashiko)
- Link to v1: https://patch.msgid.link/20260731-sm8475-tlmm-v1-0-3007a8e4aa62@proton.me

---
Esteban Urrutia (4):
      pinctrl: qcom: sm8450: Remove duplicate reference to gpio81
      pinctrl: qcom: Commonize pinctrl-sm8450 headers
      dt-bindings: pinctrl: qcom,sm8450-tlmm: Add compatible for SM8475
      pinctrl: qcom: Add SM8475 pinctrl driver

 .../bindings/pinctrl/qcom,sm8450-tlmm.yaml         |    4 +-
 drivers/pinctrl/qcom/Kconfig.msm                   |    9 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-sm8450.c              |  235 +---
 drivers/pinctrl/qcom/pinctrl-sm8450.h              |  246 ++++
 drivers/pinctrl/qcom/pinctrl-sm8475.c              | 1462 ++++++++++++++++++++
 6 files changed, 1723 insertions(+), 234 deletions(-)
---
base-commit: 415606a7be939835db9b0d6b711887586646346d
change-id: 20260729-sm8475-tlmm-6a5235bd08ff

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

