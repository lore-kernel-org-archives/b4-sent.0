From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 23 Nov 2026 15:47:03 +0100
Subject: [PATCH v4 8/8] riscv: defconfig: Enable MIPS SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-p8700-dts-v4-8-60bb7bf8a7a1@htecgroup.com>
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
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795445243; l=702;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=466tDeyPbrAH0ZZbXJHUmWZAi2oQm3IXvaEsJZHNtNU=;
 b=QbJYoDvcuW6rTMceYF+5oDzqORpAQ4g2v6P2iVuhB6hDlCo5rUvgeFenzg/A7wBqX4SgHuwJF
 wI87ry8uZsiC0Ks+ptcdfYOeK7zDZnUfEL7uMktB21Y/VoHrOgsHhdd
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Build the MIPS P8700 Boston dtb by default.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 arch/riscv/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/riscv/configs/defconfig b/arch/riscv/configs/defconfig
index 04ae305d5511bb0760247f50d4b69b1e3a00527b..1b0b5346603934058d8348ddb3aa9d7616af999c 100644
--- a/arch/riscv/configs/defconfig
+++ b/arch/riscv/configs/defconfig
@@ -26,6 +26,7 @@ CONFIG_ARCH_ANDES=y
 CONFIG_ARCH_ANLOGIC=y
 CONFIG_ARCH_ESWIN=y
 CONFIG_ARCH_MICROCHIP=y
+CONFIG_ARCH_MIPS=y
 CONFIG_ARCH_SIFIVE=y
 CONFIG_ARCH_SOPHGO=y
 CONFIG_ARCH_SPACEMIT=y

-- 
2.43.0

