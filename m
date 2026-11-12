From: Xincheng Ji <jixincheng@ultrarisc.com>
Date: Thu, 12 Nov 2026 10:01:07 +0800
Subject: [PATCH v8 8/8] MAINTAINERS: Update UltraRISC platform maintainer
 and tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-ultrarisc-dts-v8-8-14fa0834cac4@ultrarisc.com>
References: <20261112-ultrarisc-dts-v8-0-14fa0834cac4@ultrarisc.com>
In-Reply-To: <20261112-ultrarisc-dts-v8-0-14fa0834cac4@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Andrew Lunn <andrew@lunn.ch>, 
 Jia Wang <wangjia@ultrarisc.com>, Xincheng Ji <jixincheng@ultrarisc.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 linux-riscv@lists.infradead.org
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794448869; l=1040;
 i=jixincheng@ultrarisc.com; s=20260922; h=from:subject:message-id;
 bh=zzbzfVX2pHKjlzmFHTGwjk6Q4jGYy9Bm9HpLwCsOw8U=;
 b=2iQS3anfVEQo5/QZ4GHyJmpaKBXwQ5QlnDN75lLOfZURdhnA3hll1agaX7JCqLgox4KoiwCVN
 LftIjGMayl2CLv2xDGPW05MkMKn/d1R9nsZaeHBU2RggGCQcqEng9D8
X-Developer-Key: i=jixincheng@ultrarisc.com; a=ed25519;
 pk=n848dcS5D6g0vLad/rjp4Gf/1eedTe1a3pYUrkt2260=
X-Endpoint-Received: by B4 Relay for jixincheng@ultrarisc.com/20260922 with auth_id=1046
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Jia Wang has left UltraRISC. Take over maintenance of the UltraRISC
platform and use Conor Dooley's tree for platform changes during the
handover, as requested by Conor.

Link: https://lore.kernel.org/all/20261110-amused-strobe-d6cf2bf24861@spud/
Signed-off-by: Xincheng Ji <jixincheng@ultrarisc.com>
---
 MAINTAINERS | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index a97926dadba4..67bf01e20560 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23640,10 +23640,10 @@ F:	include/dt-bindings/reset/thead,th1520-reset.h
 F:	include/linux/firmware/thead/thead,th1520-aon.h
 
 RISC-V ULTRARISC SoC SUPPORT
-M:	Jia Wang <wangjia@ultrarisc.com>
+M:	Xincheng Ji <jixincheng@ultrarisc.com>
 L:	linux-riscv@lists.infradead.org
 S:	Supported
-T:	git https://github.com/ultrarisc/linux.git
+T:	git https://git.kernel.org/pub/scm/linux/kernel/git/conor/linux.git/
 F:	Documentation/devicetree/bindings/riscv/ultrarisc.yaml
 F:	arch/riscv/boot/dts/ultrarisc/
 

-- 
2.34.1

