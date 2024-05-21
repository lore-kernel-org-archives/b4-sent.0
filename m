From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Subject: [PATCH 0/2] Input: edt-ft5x06 - add support for FocalTech FT5452
 and FT8719
Date: Tue, 21 May 2024 09:02:56 -0500
Message-Id: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-0-2a648ac7176b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJCpTGYC/x2NQQrDIBAAvxL23IW4VZL2K6UH0d3Gi8pqQiHk7
 5XeZi4zJzTWxA2e0wnKR2qp5CHmNkHYfP4wpjgcaCY7OzLoY8S211q0o3RnHaHPceC6mAf2soe
 tBWXOKCvdw2JZvBgYvaos6ft/vd7X9QOkqX22ewAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <joelselvaraj.oss@gmail.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716300186; l=1251;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=+Jy4m7MNDpofjaRM2AsMooq8RhxTCuUViL7IQLY/GDs=;
 b=GPJ6+3sTUcxQbqe7Q2jq/hSWNe3OTVkl1ZUdn4wrZgvg7dNBv2fIvPkzaZSANCp5YZIXhMMGV
 8LNL3nhf8RBDBfDayHlMd+at/RSHJznFSMSFxA8Q6Y2801ZcCzzmRQl
X-Developer-Key: i=joelselvaraj.oss@gmail.com; a=ed25519;
 pk=qT4gsuVtlPE0Dpr+tQA/Fumm7wzVP6qfeVaY+6pX04s=
X-Endpoint-Received: by B4 Relay for joelselvaraj.oss@gmail.com/20240420 with auth_id=165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver is compatible with FocalTech FT5452 and FT8719 touchscreens 
too. FT5452 supports up to 5 touch points. FT8719 supports up to 10 touch
points. Add compatible data for both of them. Currently in mainline,
FT8719 touchscreen is present in Xiaomi Poco F1 (EBBG variant)[1] and 
FT5452 touchscreen is present in Shift6mq[2].

[1] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts?h=v6.9
[2] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts?h=v6.9

Signed-off-by: Joel Selvaraj <joelselvaraj.oss@gmail.com>
---
Joel Selvaraj (2):
      dt-bindings: input: touchscreen: edt-ft5x06: Document FT5452 and FT8719 support
      Input: edt-ft5x06 - add support for FocalTech FT5452 and FT8719

 .../devicetree/bindings/input/touchscreen/edt-ft5x06.yaml    |  2 ++
 drivers/input/touchscreen/edt-ft5x06.c                       | 12 ++++++++++++
 2 files changed, 14 insertions(+)
---
base-commit: 6595aff3307919c5866493ea994af4edd24582ab
change-id: 20240521-add-support-ft5452-and-ft8719-touchscreen-f823c74efaf1

Best regards,
-- 
Joel Selvaraj <joelselvaraj.oss@gmail.com>

