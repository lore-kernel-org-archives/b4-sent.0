From: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Date: Wed, 04 Dec 2024 16:05:28 +0000
Subject: [PATCH v5 5/6] arm64: defconfig: Enable Blaize BLZP1600 platform
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241204-blaize-blzp1600_init_board_support-v5-5-b642bcc49307@blaize.com>
References: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
In-Reply-To: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 James Cowgill <james.cowgill@blaize.com>, 
 Matt Redfearn <matt.redfearn@blaize.com>, 
 Neil Jones <neil.jones@blaize.com>, 
 Niko Pasaloukos <nikolaos.pasaloukos@blaize.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Olof Johansson <olof@lixom.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, soc@lists.linux.dev, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733328392; l=754;
 i=nikolaos.pasaloukos@blaize.com; s=20241111; h=from:subject:message-id;
 bh=p64eXXaIQjoPOizS0+i1yI0HfKEd6m8yRHyu9K+W+GE=;
 b=xiq+hGJ+bcWw9onTf2uX5rlzKc+E1DAv8+JHh2rcSL/LF3Oc1dtqsHetuoJ932y4rTYThe8Fn
 rIPtAh8dlLZB3H2WKbc3Znaeet/Fc4TWBTSF3E21T/UXhTtbp5us5MH
X-Developer-Key: i=nikolaos.pasaloukos@blaize.com; a=ed25519;
 pk=gGEjGCXdSuvCJPIiu0p0UeiPcW5LC710Z6KGN/dzo3g=
X-Endpoint-Received: by B4 Relay for nikolaos.pasaloukos@blaize.com/20241111 with auth_id=274
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable ARCH_BLAIZE to support the BLZP1600 SoC and the CB2
development board.

Signed-off-by: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index 5fdbfea7a5b295c4569f34773394ffe6eda778e9..4921669f89ae0a89e0c1489a2a4359be9698e5a2 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -44,6 +44,7 @@ CONFIG_ARCH_BCM_IPROC=y
 CONFIG_ARCH_BCMBCA=y
 CONFIG_ARCH_BRCMSTB=y
 CONFIG_ARCH_BERLIN=y
+CONFIG_ARCH_BLAIZE=y
 CONFIG_ARCH_EXYNOS=y
 CONFIG_ARCH_SPARX5=y
 CONFIG_ARCH_K3=y

-- 
2.43.0

