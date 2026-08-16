From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH 0/2] Add pinctrl support for MSM8952
Date: Sun, 16 Aug 2026 16:48:29 +0300
Message-Id: <20260816-msm8952-pinctrl-v1-0-a7272bcd2187@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBNyKNGuEi3KphpIE40IorsnL
 d/i/wcyJaYMnXgg0cWZj1CgKgFuG8NKkudiwBp1bZSWPntjW5SRgzvTLieH09yYxqJWUKqYaOH
 7P/bD+34H7QynYQAAAA==
X-Change-ID: 20260816-msm8952-pinctrl-bc2bd4849261
To: Bjorn Andersson <andersson@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786888114; l=1113;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=hax40JvGfGceqZVis9K771ku6lFmRrEHVKGcqZpvT1A=;
 b=pJT5qLFodtWLVsO4kFHp1fpYn+TFtUyNvVdZjf+mnvMIgbHe3aEZvmw8E5TS3+5cdocOkTSwj
 g5eeSJAHj4ADjVlZOCDlmPp/KAUkjJCr5kRv7OQy6QmjzlpMFsfyN3l
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8952 has pinctrl system that is similar to MSM8917 pinctrl, but it
has some differences in some of the pins and their functions.
This driver was tested on General Mobile GM 5 Plus
(shamrock) using my own kernel fork [1].
I'm holding off on sending the GCC (Global Clock
Controller) driver and initial device tree until I've resolved some
outstanding bugs in the GCC driver.

[1] https://github.com/kadir1243/linux

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
Muzaffer Kadir (2):
      dt-bindings: pinctrl: qcom: Add MSM8952 pinctrl
      pinctrl: qcom: Add MSM8952 tlmm pinctrl driver

 .../bindings/pinctrl/qcom,msm8952-pinctrl.yaml     |  155 +++
 drivers/pinctrl/qcom/Kconfig.msm                   |    6 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-msm8952.c             | 1248 ++++++++++++++++++++
 4 files changed, 1410 insertions(+)
---
base-commit: 22eb4b80c0ab1aac513cca427a16de8986f3301e
change-id: 20260816-msm8952-pinctrl-bc2bd4849261

Best regards,
-- 
Muzaffer Kadir <muzafferkadir@mainlining.org>

