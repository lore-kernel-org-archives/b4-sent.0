From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 08 Nov 2024 13:54:43 +0800
Subject: [PATCH v5 3/3] MAINTAINERS: Add an entry for Amlogic RTC driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241108-rtc-v5-3-0194727c778b@amlogic.com>
References: <20241108-rtc-v5-0-0194727c778b@amlogic.com>
In-Reply-To: <20241108-rtc-v5-0-0194727c778b@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731045288; l=931;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Gn6Ya+wBxnc2VJ4I38RsdaXoWkK7Fe7p7YGOFyMiaMc=;
 b=JauI8zgU05bKeqeyzwuQBA2wM5STfZhy/ebpOWWWoTKxzWe5isdRVwCx2UNb5IujppvIWQH4S
 jRpneopPvcTD6rp07VFBCYsfr1yysXZdFURcmzrPv/o0o0p2PID/UfJ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yiting Deng <yiting.deng@amlogic.com>

Add Amlogic RTC entry to MAINTAINERS to clarify the maintainers.

Signed-off-by: Yiting Deng <yiting.deng@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c27f3190737f..86675e03888c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1209,6 +1209,14 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC RTC DRIVER
+M:	Yiting Deng <yiting.deng@amlogic.com>
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-amlogic@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml
+F:	drivers/rtc/rtc-amlogic-a4.c
+
 AMPHENOL CHIPCAP 2 HUMIDITY-TEMPERATURE IIO DRIVER
 M:	Javier Carrasco <javier.carrasco.cruz@gmail.com>
 L:	linux-hwmon@vger.kernel.org

-- 
2.37.1

