From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 17:18:57 +1000
Subject: [PATCH v2 1/6] armv8: spin_table: Fix missing includes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-msm8916-smp-support-v2-1-792e53dac374@samcday.com>
References: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
In-Reply-To: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
To: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Mark Kettenis <mark.kettenis@xs4all.nl>, Sumit Garg <sumit.garg@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 Casey Connolly <casey.connolly@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Sughosh Ganu <sughosh.ganu@arm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780384740; l=828;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=mQoSZDn/LSUJsIUtV/EsIb4Uz11YSinXSikaofNJ7ko=;
 b=SoME2+h/7g8MqnTGmxn2wXRP6eLyzvbBqaoUtsMlcf8mtwPX+wCZ0V4AIuB75Kw+TTMYhK/4n
 caLY0UlsLwpC0PPWWNZSfh3/2yZt2lkSCKKzm5kH78mGulMU92whqsZ
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Dropping the common.h header resulted in the spin table header missing
asm/types.h and the source unit missing the errno.h includes.

Fixes: 7410cde67de0 ("arm: Remove <common.h> and add needed includes")
Reviewed-by: Tom Rini <trini@konsulko.com>
Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/include/asm/spin_table.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/include/asm/spin_table.h b/arch/arm/include/asm/spin_table.h
index dec18c6e5c1..8fc61237e07 100644
--- a/arch/arm/include/asm/spin_table.h
+++ b/arch/arm/include/asm/spin_table.h
@@ -3,6 +3,8 @@
 #ifndef __ASM_SPIN_TABLE_H__
 #define __ASM_SPIN_TABLE_H__
 
+#include <asm/types.h>
+
 extern u64 spin_table_cpu_release_addr;
 extern char spin_table_reserve_begin;
 extern char spin_table_reserve_end;

-- 
2.54.0

