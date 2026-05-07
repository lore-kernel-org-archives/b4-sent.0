From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/2] pinctrl: add support amlogic a9
Date: Thu, 07 May 2026 08:21:05 +0000
Message-Id: <20260507-a9-pinctrl-v2-0-49774feff2ef@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHFL/GkC/02NwQqDMBBEf0X23C1mUak99T+KhyQmuqCJJBIs4
 r832ktv82YY3g7RBDYRnsUOwSSO7F0GuhWgR+kGg9xnBiqpKQW1KFtc2Ok1TDnWQkhJVCkL+aB
 kNKiCdHo8L9YHdGZbz2kJxvJ2ed5d5pHj6sPn0iZxtj9DRY9/QxJYou4bIZSqbU39S86TH1jft
 Z+hO47jCxssS6zBAAAA
X-Change-ID: 20260129-a9-pinctrl-a9511aa224bf
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778142090; l=833;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=ADtYUrAasvGOltfd9FShuLbJhinKTxBPxoHCICnXTv0=;
 b=+WPtDI+UlHraHDXBTPvl2FM/S60lk+5x68/SNLerSm/CfB7+/O7viEMzuv4ZAUaWnS6YseElv
 3trpOG25Uf1DbIa9FB3fm7J1h0rS0e7B4OD5g3UmGfF6ya2xc+isLPO
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl bindings and driver about for amlogic a9.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Add a commit message explaining why it is not compatible with previous SoCs and rebase code.
- Link to v1: https://lore.kernel.org/r/20260428-a9-pinctrl-v1-0-cd611bb5f52d@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for A9
      pinctrl: meson: support amlogic A9 SoC

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  1 +
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 61 ++++++++++++++++++++--
 2 files changed, 57 insertions(+), 5 deletions(-)
---
base-commit: eccd2fde7dbc398a6aba9120c01247beeca55aec
change-id: 20260129-a9-pinctrl-a9511aa224bf

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

