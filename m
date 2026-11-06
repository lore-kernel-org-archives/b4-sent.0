From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 07 Nov 2026 03:40:33 +0800
Subject: [PATCH] firmware: arm_scmi: Drop the ARM architecture dependency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-arm-scmi-arch-dep-v1-1-514872e8ede4@iscas.ac.cn>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqEMAyF4VeRrCdgKyj1VcRFGzMawQvNKIL47
 lZnd77F+U9QjsIKdXZC5F1UljnBfDKgwc89o3TJYHNbGpNX6OOESpOkQQN2vKIrvXOhsIHIQ/q
 tkb9yvM2m/Vu3MDL9nhBc1w1xJXeQdQAAAA==
X-Change-ID: 20261107-arm-scmi-arch-dep-96a99b32bcca
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Michal Simek <michal.simek@amd.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793994040; l=1758;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=JFfyRaQjdRkhf1+nAyQftf8BDfEeha9RuqZH2ozDpeU=;
 b=WKv3qVktXvpY2424NiZPSFXWRZ5auD0LPYgNUC0J2hfBTaOLyfwe2GJj4c8PvAPyBOGi63/t8
 2LjLVo+kIR9B4DG1mGecFcC8TiJjdI9omLH+JM6pTdF38NzUBJGIIgh
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SCMI core and the mailbox and shared memory transports only use
generic kernel interfaces. Transports that need architecture support,
such as SMC, already carry their own dependencies.

Drop the ARM and ARM64 dependency so that other architectures can use
SCMI. Depend on HAS_IOMEM instead, for devm_ioremap().

Suggested-by: Michal Simek <michal.simek@amd.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
This was patch 1 of the Zhihe A210 SoC series [1]. As Michal asked, it
now goes on its own through the SCMI tree.

Since [1], it depends on HAS_IOMEM: Sashiko found that UML, which has
no HAS_IOMEM, failed to link devm_ioremap().

Build tested on x86_64 without OF, i386, loongarch64, ppc64le, riscv64
and arm64. On UML, SCMI can no longer be selected.

[1] https://patch.msgid.link/20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn
---
 drivers/firmware/arm_scmi/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/firmware/arm_scmi/Kconfig b/drivers/firmware/arm_scmi/Kconfig
index 783c24a20e29..f403271c3d11 100644
--- a/drivers/firmware/arm_scmi/Kconfig
+++ b/drivers/firmware/arm_scmi/Kconfig
@@ -3,7 +3,7 @@ menu "ARM System Control and Management Interface Protocol"
 
 config ARM_SCMI_PROTOCOL
 	tristate "ARM System Control and Management Interface (SCMI) Message Protocol"
-	depends on ARM || ARM64 || COMPILE_TEST
+	depends on HAS_IOMEM || COMPILE_TEST
 	help
 	  ARM System Control and Management Interface (SCMI) protocol is a
 	  set of operating system-independent software interfaces that are

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-arm-scmi-arch-dep-96a99b32bcca

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

