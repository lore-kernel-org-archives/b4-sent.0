From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 23 Jun 2025 16:53:29 +0800
Subject: [PATCH v3 3/3] MAINTAINERS: Add an entry for Amlogic spi driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250623-spisg-v3-3-c731f57e289c@amlogic.com>
References: <20250623-spisg-v3-0-c731f57e289c@amlogic.com>
In-Reply-To: <20250623-spisg-v3-0-c731f57e289c@amlogic.com>
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750668807; l=878;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=d96hwpa3CUOhnffR2RHeVgOJAkVgtVaxxsoYbBLIdso=;
 b=4zDUnHtNAHIpCUEIX5b7lnyH7hDVO3RkXJbLgp3LOzeCh7QDJ7oOGgR1lSeDrgJ5LEixoYhJ/
 iejxfCgZwUTAB5p3k9Iw3EToazbUDOq0B1r4pAqNnHkEnGdhash8RKP
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic spi entry to MAINTAINERS to clarify the maintainers.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index a92290fffa16..8225df5ede74 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1307,6 +1307,15 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml
 F:	drivers/rtc/rtc-amlogic-a4.c
 
+AMLOGIC SPISG DRIVER
+M:	Sunny Luo <sunny.luo@amlogic.com>
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-amlogic@lists.infradead.org
+L:	linux-spi@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml
+F:	drivers/spi/spi-amlogic-spisg.c
+
 AMPHENOL CHIPCAP 2 DRIVER
 M:	Javier Carrasco <javier.carrasco.cruz@gmail.com>
 L:	linux-hwmon@vger.kernel.org

-- 
2.37.1

