From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 21 Nov 2026 03:15:59 +0800
Subject: [PATCH v4 13/13] MAINTAINERS: add Zhihe A210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-a210-scmi-v4-13-4a795a0a9fc9@iscas.ac.cn>
References: <20261121-a210-scmi-v4-0-4a795a0a9fc9@iscas.ac.cn>
In-Reply-To: <20261121-a210-scmi-v4-0-4a795a0a9fc9@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Drew Fustini <fustini@kernel.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Inochi Amaoto <inochiama@gmail.com>, Vivian Wang <wangruikang@iscas.ac.cn>, 
 Yao Zi <me@ziyao.cc>, Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795202181; l=998;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=4+K9oMgmXDDNfWP3RQVazEGhA8ORba3TgR1reKRQrsA=;
 b=7xcyBtu7YBanong5vbppbomKxRSQ5askeWhUrWIhxQ49iTgHE+taiLAE4M2HbLLzGiFk62t3o
 ZuIW/KgYXZDB//lw5jViGKgh8McyJDTU0lHz8KeFABH1yAAJZAYqs+j
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Zhiguo Zhu and Han Gao as A210 maintainers.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 MAINTAINERS | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index ccbcdc0799b9..a1eb24fd742e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -30928,6 +30928,18 @@ L:	linux-kernel@vger.kernel.org
 S:	Maintained
 F:	arch/x86/kernel/cpu/zhaoxin.c
 
+ZHIHE A210 SOC SUPPORT
+M:	Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
+M:	Han Gao <gaohan@iscas.ac.cn>
+L:	linux-riscv@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml
+F:	Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml
+F:	Documentation/devicetree/bindings/riscv/zhihe.yaml
+F:	arch/riscv/boot/dts/zhihe/
+F:	drivers/mailbox/mailbox-a210.c
+F:	drivers/pinctrl/pinctrl-zhihe-a210.c
+
 ZONED BLOCK DEVICE (BLOCK LAYER)
 M:	Damien Le Moal <dlemoal@kernel.org>
 L:	linux-block@vger.kernel.org

-- 
2.55.0

