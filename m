From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 09 Sep 2025 13:13:27 +0800
Subject: [PATCH v5 3/3] MAINTAINERS: Add an entry for Amlogic spifc driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-spifc-v5-3-962bc147d17f@amlogic.com>
References: <20250909-spifc-v5-0-962bc147d17f@amlogic.com>
In-Reply-To: <20250909-spifc-v5-0-962bc147d17f@amlogic.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liang Yang <liang.yang@amlogic.com>, 
 Feng Chen <feng.chen@amlogic.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757394806; l=935;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=waH2I+tfwvOLzp50Qi+Yg091qChCxHO4Mz5PuoGKYLg=;
 b=S64wUFqJJpT241VMBS0RwVymct4c6ZoWfnA+7yst3Hw+DTQwpG0Gg6gxop0AicDzYXuLx/Jjh
 1SRAdVB7Ai+DuMLmPPHpmc5OWBVpwrnsCyfWR8E6C/ZgYdll7/yrOnO
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic spi flash controller entry to MAINTAINERS
to clarify the maintainers.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index b1c081f9c567..9f1f337e9b6d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1306,6 +1306,16 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml
 F:	drivers/rtc/rtc-amlogic-a4.c
 
+AMLOGIC SPIFC DRIVER
+M:	Liang Yang <liang.yang@amlogic.com>
+M:	Feng Chen <feng.chen@amlogic.com>
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-amlogic@lists.infradead.org
+L:	linux-spi@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/spi/amlogic,a4-spifc.yaml
+F:	drivers/spi/spi-amlogic-spifc-a4.c
+
 AMLOGIC SPISG DRIVER
 M:	Sunny Luo <sunny.luo@amlogic.com>
 M:	Xianwei Zhao <xianwei.zhao@amlogic.com>

-- 
2.37.1

