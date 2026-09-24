From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 24 Sep 2026 08:39:36 +0000
Subject: [PATCH 3/3] MAINTAINERS: Add an entry for Amlogic I2C driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-a9-i2c-v1-3-b8ad9b46f4a8@amlogic.com>
References: <20260924-a9-i2c-v1-0-b8ad9b46f4a8@amlogic.com>
In-Reply-To: <20260924-a9-i2c-v1-0-b8ad9b46f4a8@amlogic.com>
To: Junyi Zhao <junyi.zhao@amlogic.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Xianwei Zhao <xianwei.zhaol@amlogic.com>
Cc: Junyi Zhao <junyi.zhaol@amlogic.com>, linux-i2c@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790239188; l=829;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=aYonPJ+1tSzZLPuDMhjuR3pNtXh8ncO4wuKdJvLpiZk=;
 b=W2fhuoKGAkSXG5MS0wF+fkCwKpIiTkXKALi46UKdci9Vw0mrWEaJm3i8Nc6u20K6rY8qICF9M
 ViMHi39DZ58AbpKcjkXoLGboKoo37YOI8rXrOi0ve2ziIU9SDiCzP0G
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic I2C controller entry to MAINTAINERS to clarify
the maintainers.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 6215fcb07770..33c39ecf535f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1371,6 +1371,14 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC I2C DRIVER
+M:	Junyi Zhao <junyi.zhao@amlogic.com>
+L:	linux-i2c@vger.kernel.org
+L:	linux-amlogic@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/i2c/amlogic,a9-i2c.yaml
+F:	drivers/i2c/busses/i2c-amlogic-a9.c
+
 AMLOGIC ISP DRIVER
 M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org

-- 
2.52.0

