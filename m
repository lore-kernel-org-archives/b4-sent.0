From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 23 Nov 2026 15:47:02 +0100
Subject: [PATCH v4 7/8] MAINTAINERS: Add entry for MIPS RISC-V SoC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-p8700-dts-v4-7-60bb7bf8a7a1@htecgroup.com>
References: <20261123-p8700-dts-v4-0-60bb7bf8a7a1@htecgroup.com>
In-Reply-To: <20261123-p8700-dts-v4-0-60bb7bf8a7a1@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Anup Patel <anup@brainfault.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Inochi Amaoto <inochiama@outlook.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Conor Dooley <conor@kernel.org>, linux-riscv@lists.infradead.org, 
 Vladimir Kondratiev <vladimir.kondratiev@mobileye.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Joel Stanley <joel@jms.id.au>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795445243; l=913;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=ZJvf49si5KqHQv1isXMeLQqxt/Hhb8/bQsfjW00EDHE=;
 b=wDSQhjRNNSKODF9urr4mkpjxL6kTtPOw+fAEqjfTUN/fClgZGbCqxzcDiXJZb6QuNTMRv0XGf
 YvR+C4NOJaPBKAnewg2+fq2W5MBc4vOLX4yB049dZzRxkssFfNJ5KuM
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a MAINTAINERS entry covering the MIPS RISC-V devicetree sources
and the board binding.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c2414447892c24d58595059ca27b18775919ac12..7b6cd49a4fe2626a946a9153f1ca545d6ad28960 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23542,6 +23542,14 @@ F:	drivers/spi/spi-mpfs.c
 F:	drivers/usb/musb/mpfs.c
 F:	include/soc/microchip/mpfs.h
 
+RISC-V MIPS SoC SUPPORT
+M:	Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
+L:	linux-riscv@lists.infradead.org
+S:	Supported
+T:	git https://github.com/aleksapaunovic-htec/linux.git
+F:	Documentation/devicetree/bindings/riscv/mips.yaml
+F:	arch/riscv/boot/dts/mips/
+
 RISC-V MISC SOC SUPPORT
 M:	Conor Dooley <conor@kernel.org>
 L:	linux-riscv@lists.infradead.org

-- 
2.43.0

