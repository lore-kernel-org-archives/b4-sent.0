From: Yang Li <yang.li@amlogic.com>
Date: Fri, 05 Jul 2024 19:13:27 +0800
Subject: [PATCH 3/3] MAINTAINERS: Add an entry for Amlogic WCN power
 sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-pwrseq-v1-3-31829b47fc72@amlogic.com>
References: <20240705-pwrseq-v1-0-31829b47fc72@amlogic.com>
In-Reply-To: <20240705-pwrseq-v1-0-31829b47fc72@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178006; l=844;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=2LQ5HRplZ2LlSPyzOYDNeeV7S6poY56OZ7f06ODqzXY=;
 b=PCOpuH5dGrWwfCdZFsAqjetcT/FPX1SeagmqXMJ1KkeEskEll8W9pctua+mg06NS6v906tdIe
 ZHNfuK9mBtKAWpdnStmTqHBzAOQcsh5Bw3Gr2cb8ti1WB8p1+NCLIvG
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for Amlogic WCN power sequence.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index dcb37b635f2c..0773f7040341 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1174,6 +1174,14 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC WCN POWER SEQUENCING
+M:	Yang Li <yang.li@amlogic.com>
+L:	linux-pm@vger.kernel.org
+S:	Maintained
+W:	http://www.amlogic.com
+F:	Documentation/devicetree/bindings/power/amlogic,w1552-pwrseq.yaml
+F:	drivers/power/sequencing/pwrseq-aml-wcn.c
+
 AMPHENOL CHIPCAP 2 HUMIDITY-TEMPERATURE IIO DRIVER
 M:	Javier Carrasco <javier.carrasco.cruz@gmail.com>
 L:	linux-hwmon@vger.kernel.org

-- 
2.42.0

