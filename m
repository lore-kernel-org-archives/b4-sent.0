From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Subject: [PATCH 0/2] novatek-nvt-ts: add support for NT36672A touchscreen
Date: Tue, 21 May 2024 07:09:44 -0500
Message-Id: <20240521-nvt-ts-devicetree-regulator-support-v1-0-8d766c639dca@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAiPTGYC/x2NwQqDMBAFf0X23AUj1mp/pfSQxqddKEnYjVIQ/
 72hx4Fh5iCDCozuzUGKXUxSrOAuDYW3jytY5srUtV3fXt3IcS9cjOfqBhQFWLFuH1+Ssm05Jy3
 sw4R+et1G7waqpaxY5Pu/PJ7n+QNYFuZEdQAAAA==
To: Hans de Goede <hdegoede@redhat.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <joelselvaraj.oss@gmail.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716293427; l=1155;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=f2GQ0va2lsLTO8nlzPzR6f1yERxb6qBUyy6szVB7sAM=;
 b=RwjnyeMqeGDD586cQXkEIsoybnrUaiCO8HAys+wB2ry3yzDHXQjh8LXhO3b3RTvs2fuPPGF4w
 XNDDR+VcijjD6awjhM6ZJsneWQ62X3ZMHBccN8iPQVlpoHccYsX2p3i
X-Developer-Key: i=joelselvaraj.oss@gmail.com; a=ed25519;
 pk=qT4gsuVtlPE0Dpr+tQA/Fumm7wzVP6qfeVaY+6pX04s=
X-Endpoint-Received: by B4 Relay for joelselvaraj.oss@gmail.com/20240420 with auth_id=165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the novatek touchscreen driver to support NT36672A chip which
is found in phones like Xiaomi Poco F1 [1]. Added devicetree support for
the driver and used i2c chip data to handle the variation in chip id and
wake type. Also added vcc and iovcc regulators which are used to power
the touchscreen hardware.

[1] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts?h=v6.9

Signed-off-by: Joel Selvaraj <joelselvaraj.oss@gmail.com>
---
Joel Selvaraj (2):
      dt-bindings: input: document Novatek NVT touchscreen controller
      Input: novatek-nvt-ts: add support for NT36672A touchscreen

 .../bindings/input/touchscreen/novatek,nvt-ts.yaml | 62 +++++++++++++++++
 MAINTAINERS                                        |  1 +
 drivers/input/touchscreen/novatek-nvt-ts.c         | 78 ++++++++++++++++++++--
 3 files changed, 135 insertions(+), 6 deletions(-)
---
base-commit: 6578aac6a270bd6deb9f9319b991dd430de263dd
change-id: 20240518-nvt-ts-devicetree-regulator-support-ac9e49b78a16

Best regards,
-- 
Joel Selvaraj <joelselvaraj.oss@gmail.com>

