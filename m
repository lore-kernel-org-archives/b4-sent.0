From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 01:00:15 +0300
Subject: [PATCH v3 3/3] MAINTAINERS: Add Cortina Systems CS7542 RTC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-cs7542-rtc-v3-3-53902bfbe0ae@gmail.com>
References: <20261124-b4-cs7542-rtc-v3-0-53902bfbe0ae@gmail.com>
In-Reply-To: <20261124-b4-cs7542-rtc-v3-0-53902bfbe0ae@gmail.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795471212; l=864;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=V966SZMepm42nKofeQHA+zZwJm4nGNGjIsMkGKj6kQA=;
 b=A9V7/mpPv+/bcY+uKssDtaSgc00coIaWRpY0v3mYhojSvOltGnigrmmlCd8lMUXRhVPhtyjN6
 e9XyC1ZUMfEA7n9JxjlYJWWqjC6LEC2EWA725FQ0m4z6nN7cWAEPctG
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Route changes to the CS7542 calendar clock driver and binding
to their subsystem mailing list and the platform maintainer.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 44540a1eb..e7f97fb96 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2949,6 +2949,13 @@ F:	tools/perf/tests/shell/coresight/*
 F:	tools/perf/util/cs-etm-decoder/*
 F:	tools/perf/util/cs-etm.*
 
+ARM/CORTINA SYSTEMS CS7542 RTC
+M:	Fil Dunsky <filipp.dunsky@gmail.com>
+L:	linux-rtc@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/rtc/cortina,cs7542-rtc.yaml
+F:	drivers/rtc/rtc-cs75xx.c
+
 ARM/CORTINA SYSTEMS GEMINI ARM ARCHITECTURE
 M:	Hans Ulli Kroll <ulli.kroll@googlemail.com>
 M:	Linus Walleij <linusw@kernel.org>

-- 
2.53.0

